package nova.trigger;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import nova.trigger.TriggerFactory;
import nova.utils.Pair;

using nova.animation.Director;

class TriggerPrefabs {
    public static function addFunctionTrigger(factory:TriggerFactory,
                                              triggerName:String,
                                              fn:Dynamic -> Void) {
        factory.effectParsers.set(triggerName, function(prevActor:Actor, params:Dynamic) {
            return Director.call(prevActor, function(sp:FlxSprite) {
                fn(params);
            });
        });
    }

    public static function loadBasicPrefabs(factory:TriggerFactory) {
        if (!factory.triggerConfig.exists('wait')) {
            factory.triggerConfig.set('wait', [
                new TriggerToken('int', 'frames')
            ]);
            factory.effectParsers.set('wait', function(prevActor:Actor, params:Dynamic) {
                return Director.wait(prevActor, params.frames);
            });
        }

        if (!factory.triggerConfig.exists('cameraFade')) {
            factory.triggerConfig.set('cameraFade', [
                new TriggerToken('string', 'from_to'),
                new TriggerToken('int', 'frames')
            ]);
            factory.effectParsers.set('cameraFade', function(prevActor:Actor, params:Dynamic) {
                var done:Bool = false;
                var duration:Float = params.frames / FlxG.updateFramerate;

                return Director.call(prevActor, function() {
                    FlxG.camera.fade(FlxColor.BLACK, duration, (params.from_to == 'from'), function() { done = true; });
                }).callUntil(
                    function(s) {},
                    function(s) { return done; }
                );
            });
        }

        if (!factory.triggerConfig.exists('cameraFlash')) {
            factory.triggerConfig.set('cameraFlash', [
                new TriggerToken('int', 'frames')
            ]);
            factory.effectParsers.set('cameraFlash', function(prevActor:Actor, params:Dynamic) {
                var done:Bool = false;
                var duration:Float = params.frames / FlxG.updateFramerate;

                return Director.call(prevActor, function() {
                    FlxG.camera.flash(FlxColor.WHITE, duration, function() { done = true; });
                }).callUntil(
                    function(s) {},
                    function(s) { return done; }
                );
            });
        }

        if (!factory.triggerConfig.exists('cameraShake')) {
            factory.triggerConfig.set('cameraShake', [
                new TriggerToken('float', 'intensity'),
                new TriggerToken('int', 'frames')
            ]);
            factory.effectParsers.set('cameraShake', function(prevActor:Actor, params:Dynamic) {
                var done:Bool = false;
                var duration:Float = params.frames / FlxG.updateFramerate;

                return Director.call(prevActor, function() {
                    FlxG.camera.shake(params.intensity, duration, function() { done = true; });
                }).callUntil(
                    function(s) {},
                    function(s) { return done; }
                );
            });
        }

        if (!factory.triggerConfig.exists('clearTag')) {
            factory.triggerConfig.set('clearTag', [
                new TriggerToken('string', 'tag'),
            ]);
            factory.effectParsers.set('clearTag', function(prevActor:Actor, params:Dynamic) {
                return Director.call(prevActor, function() { Director.clearTag(params.tag); });
            });
        }
    }

    public static function loadSpriteTargetedPrefabs(factory:TriggerFactory,
                                                     spriteFromStringFn:String -> FlxSprite) {
        if (!factory.triggerConfig.exists('visible')) {
            factory.triggerConfig.set('visible', [
                new TriggerToken('string', 'target'),
                new TriggerToken('bool', 'visible'),
            ]);
            factory.effectParsers.set('visible', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .call(function(sp:FlxSprite) { sp.visible = params.visible; });
            });
        }

        if (!factory.triggerConfig.exists('fadeIn')) {
            factory.triggerConfig.set('fadeIn', [
                new TriggerToken('string', 'target'),
                new TriggerToken('int', 'frames'),
            ]);
            factory.effectParsers.set('fadeIn', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .fadeIn(params.frames);
            });
        }

        if (!factory.triggerConfig.exists('fadeOut')) {
            factory.triggerConfig.set('fadeOut', [
                new TriggerToken('string', 'target'),
                new TriggerToken('int', 'frames'),
            ]);
            factory.effectParsers.set('fadeOut', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .fadeIn(params.frames);
            });
        }

        if (!factory.triggerConfig.exists('moveBy')) {
            factory.triggerConfig.set('moveBy', [
                new TriggerToken('string', 'target'),
                new TriggerToken('fpair', 'direction'),
                new TriggerToken('int', 'frames'),
            ]);
            factory.effectParsers.set('moveBy', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .moveBy(params.direction, params.frames);
            });
        }

        if (!factory.triggerConfig.exists('jumpInArc')) {
            factory.triggerConfig.set('jumpInArc', [
                new TriggerToken('string', 'target'),
                new TriggerToken('float', 'distance'),
                new TriggerToken('int', 'frames'),
            ]);
            factory.effectParsers.set('moveBy', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .jumpInArc(params.distance, params.frames);
            });
        }


        if (!factory.triggerConfig.exists('teleport')) {
            factory.triggerConfig.set('teleport', [
                new TriggerToken('string', 'target'),
                new TriggerToken('fpair', 'destination'),
            ]);
            factory.effectParsers.set('teleport', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .call(function(sp:FlxSprite) {
                                   var dest:Pair<Float> = cast params.destination;
                                   sp.x = dest.x;
                                   sp.y = dest.y;
                                });
            });
        }

        if (!factory.triggerConfig.exists('teleportBy')) {
            factory.triggerConfig.set('teleportBy', [
                new TriggerToken('string', 'target'),
                new TriggerToken('fpair', 'destination'),
            ]);
            factory.effectParsers.set('teleport', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .call(function(sp:FlxSprite) {
                                   var dest:Pair<Float> = cast params.destination;
                                   sp.x += dest.x;
                                   sp.y += dest.y;
                                });
            });
        }

        if (!factory.triggerConfig.exists('animate')) {
            factory.triggerConfig.set('animate', [
                new TriggerToken('string', 'target'),
                new TriggerToken('string', 'animation'),
            ]);
            factory.effectParsers.set('animate', function(prevActor:Actor, params:Dynamic) {
                return Director.then(prevActor, function() { return spriteFromStringFn(params.target); })
                               .call(function(sp:FlxSprite) {
                                   sp.animation.play(params.animation);
                                });
            });
        }
    }
}
