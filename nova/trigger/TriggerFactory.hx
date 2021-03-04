package nova.trigger;

import openfl.Assets;
import yaml.Yaml;
import yaml.util.ObjectMap;

import nova.animation.Director;
import nova.trigger.Trigger.TriggerEffect;
import nova.trigger.Trigger.TriggerNode;
import nova.ui.dialog.DialogParser;
import nova.utils.Pair;

using StringTools;

class TriggerToken {
    public var type:String;
    public var name:String;

    public function new(type:String, name:String) {
        this.type = type;
        this.name = name;
    }
}

class TriggerFactory {
    public var triggerConfig:Map<String, Array<TriggerToken>>;
    public var effectParsers:Map<String, Actor -> Dynamic -> Actor>;

    public function new(configPath:String) {
        triggerConfig = new Map<String, Array<TriggerToken>>();
        effectParsers = new Map<String, Actor -> Dynamic -> Actor>();

        var config:ObjectMap<String, Dynamic> =
            cast Yaml.parse(Assets.getText(configPath));
        for (key in config.keys()) {
            var arr:Array<TriggerToken> = [];

            var triggerList:Array<String> = cast config.get(key);
            for (tokenStr in triggerList) {
                var splitStr = tokenStr.split(' ');
                arr.push(new TriggerToken(splitStr[0], splitStr[1]));
            }
            triggerConfig.set(key, arr);
        }
    }

    public function parseAndAddEffect(node:TriggerNode, line:String):TriggerNode {
        var tokens:Array<String> = line.split(' ');
        var triggerType = tokens[0];
        if (!triggerConfig.exists(triggerType)) {
            trace("Error: no parser for trigger of type " + triggerType + "!");
            return null;
        }
        var lineConfig = triggerConfig.get(triggerType);
        var tokenPtr = 1;
        var params:Dynamic = {};

        for (parseRule in lineConfig) {
            if (parseRule.type == 'int') {
                Reflect.setField(params, parseRule.name, Std.parseInt(tokens[tokenPtr]));
                tokenPtr += 1;
            } else if (parseRule.type == 'float') {
                Reflect.setField(params, parseRule.name, Std.parseFloat(tokens[tokenPtr]));
                tokenPtr += 1;
            } else if (parseRule.type == 'string') {
                if (parseRule.name != '_') {
                    Reflect.setField(params, parseRule.name, tokens[tokenPtr]);
                }
                tokenPtr += 1;
            } else if (parseRule.type == 'bool') {
                Reflect.setField(params, parseRule.name, (tokens[tokenPtr].toLowerCase() == 'true'));
                tokenPtr += 1;
            } else if (parseRule.type == 'ipair' || parseRule.type == 'fpair') {
                var originalPtr = tokenPtr;
                if (!tokens[tokenPtr].startsWith('(')) {
                    trace("Error: token " + tokens[tokenPtr] + " could not be parsed as a Pair!");
                    return null;
                }
                while (tokenPtr < tokens.length && !tokens[tokenPtr].endsWith(')')) {
                    tokenPtr++;
                }
                var pairStr = tokens.slice(originalPtr, tokenPtr).join(' ');
                var coordReg:EReg = ~/\((-?[\d\.]+),? *(-?[\d\.]+)\)/g;
                if (coordReg.match(line)) {
                    if (parseRule.type == 'ipair') {
                        Reflect.setField(params, parseRule.name,
                            new Pair<Int>(Std.parseInt(coordReg.matched(1)),
                                          Std.parseInt(coordReg.matched(2))));
                    } else {
                        Reflect.setField(params, parseRule.name,
                            new Pair<Float>(Std.parseFloat(coordReg.matched(1)),
                                            Std.parseFloat(coordReg.matched(2))));
                    }
                    tokenPtr++;
                } else {
                    trace("Error: string " + pairStr + " could not be matched to type " + parseRule.type + "!");
                    return null;
                }
            } else if (parseRule.type == 'expr') {
                var exprStr:String = tokens.slice(tokenPtr).join(' ');
                tokenPtr = tokens.length;

                Reflect.setField(params, parseRule.name,
                    DialogParser.parseExpression(DialogParser.parseLine(exprStr)));
            } else {
                trace("Error: unknown parse rule type " + parseRule.type + "!");
                return null;
            }
        }
        node.children.push(new TriggerEffect(triggerType, params));

        return node;
    }

    private function parseTriggerTreeLevel(node:Trigger.TriggerNode, parallel:Bool, prevActor:Actor):Actor {
        var actor:Actor = prevActor;
        if (!parallel) {
            for (child in node.children) {
                if (Std.is(child, TriggerEffect)) {
                    var effect:TriggerEffect = cast child;
                    actor = effectParsers.get(effect.type)(actor, effect.params);
                } else {
                    var childNode:TriggerNode = cast child;
                    actor = parseTriggerTreeLevel(childNode, !parallel, actor);
                }
            }
            return actor;
        } else {
            var actorList:Array<Actor> = [];
            for (child in node.children) {
                if (Std.is(child, TriggerEffect)) {
                    var effect:TriggerEffect = cast child;
                    actorList.push(effectParsers.get(effect.type)(prevActor, effect.params));
                } else {
                    var childNode:TriggerNode = cast child;
                    actorList.push(parseTriggerTreeLevel(childNode, !parallel, actor));
                }
            }
            return Director.afterAll(null, actorList);
        }
    }

    public function buildTrigger(lines:Array<String>):Trigger {
        var trigger = new Trigger();
        var stack:Array<TriggerNode> = [trigger.effects];
  
        for (rline in lines) {
            var line = rline.trim();
            if (line == '[' || line == '{') {
                stack.push(new TriggerNode());
                var parent:TriggerNode = stack[stack.length - 2];
                var child:TriggerNode = stack[stack.length - 1];
                parent.children.push(child);
                continue;
            } else if (line == ']' || line == '}') {
                stack.pop();
                continue;
            }
            var tokens:Array<String> = line.split(' ');
            var triggerType = tokens[0].toLowerCase();
  
            if (triggerType == 'if') {
                var ifExpr:String = tokens.slice(1).join(' ');
                trigger.conditions.push(
                    DialogParser.parseExpression(DialogParser.parseLine(ifExpr))
                );
            } else {
                parseAndAddEffect(stack[stack.length - 1], line);
            }
        }

        return trigger;
    }

    public function buildActor(trigger:Trigger):Actor {
        return parseTriggerTreeLevel(trigger.effects, false, null);
    }
}
