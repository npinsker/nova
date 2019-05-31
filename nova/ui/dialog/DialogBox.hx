package nova.ui.dialog;

using nova.animation.Director;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo;
import lime.text.UTF8String;
import nova.input.Focusable;
import nova.render.FlxLocalSprite;
import nova.render.TiledBitmapData;
import nova.ui.dialog.DialogNodeSequence;
import nova.ui.text.TextFormat;
import nova.ui.text.WaveText;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import nova.input.InputController;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.text.AntiAliasType;

using nova.utils.StructureUtils;

enum DialogBoxPosition {
	TOP;
	MIDDLE;
	BOTTOM;
}

enum DialogBoxAlign {
	LEFT;
	CENTER;
	RIGHT;
}

enum DialogAdvanceStyle {
	NONE;
	SCROLL;
	TYPEWRITER;
}

enum DialogBoxMode {
	NORMAL;
	SELECT_OPTION;
}

enum FlagType {
	START;
	END;
	POINT;
}

typedef DialogBoxFlag = {
	@:optional var name:String;
	@:optional var flagAction:String -> FlxLocalSprite;
	@:optional var genericAction:DialogBox -> Void;
	@:optional var type:FlagType;
	@:optional var position:Int;
}

/**
 * A powerful dialog box class with a focus on configuration and extensibility.
 * 
 * In most cases it's recommended to initialize instances of this class through a `DialogBoxFactory`
 * rather than doing so directly.
 */
class DialogBox extends FlxLocalSprite implements Focusable {
	public static inline var DEFAULT_TEXT_PADDING_X:Int = 6;
	public static inline var DEFAULT_TEXT_PADDING_Y:Int = 5;
	public static inline var DIRECTOR_DIALOG_TRANSITION_STR:String = '__dialogTransition';
	public static inline var DIRECTOR_SLIDEIN_TRANSITION_STR:String = '__slideInTransition';
	
	public static inline var DEFAULT_FONT_SIZE:Float = 5;
	
  /**
    * Whether the user can leave the dialog box at any point.
    */
	public var abort:Bool = false;

  /**
    * Whether the user can press the 'advance' key to display all text in the pane,
    * in TYPEWRITER mode.
    */
	public var skip:Bool = true;
	public var finished:Bool = false;
	
	public var labelMap:Map<String, Int>;
	
	public var align:DialogBoxAlign = DialogBoxAlign.LEFT;
	public var position:DialogBoxPosition = DialogBoxPosition.BOTTOM;
	public var advanceStyle:DialogAdvanceStyle = DialogAdvanceStyle.NONE;
	public var advanceLength:Int = 8;
	public var advancing:Bool = false;
	public var advanceSound:String = null;
  public var advanceCallback:Void -> Void = null;
  public var textAppearCallback:Int -> Void = null;
	public var advanceIndicatorInfo:Dynamic;
	public var advanceIndicatorSprite:LocalSpriteWrapper = null;
	public var advanceIndicatorTween:FlxTween;
	public var mode = DialogBoxMode.NORMAL;
	public var flags:Array<DialogBoxFlag>;
	public var pause:Int = 0;
	
	public var choices:Array<String>;
	public var choiceIndex:Int = 0;
	public var choiceSprite:LocalWrapper<FlxText> = null;
	public var choiceIndicator:LocalSpriteWrapper = null;
	
	public var backgroundPadding:Pair<Int> = [0, 0];
	public var textPadding:Pair<Int> = [DEFAULT_TEXT_PADDING_X, DEFAULT_TEXT_PADDING_Y];
	
	public var textFormat:Dynamic;
	public var optionsTextFormat:Dynamic;
	
	public var bgSprite:FlxLocalSprite = null;
	public var text:LocalWrapper<FlxText>;
	public var nextText:LocalWrapper<FlxText>;
	public var movieClipContainer:FlxLocalSprite = null;
	public var copiedText:FlxSprite;
	public var messages:DialogNodeSequence;
	public var bottomImageStore:FlxSprite;
	public var globalScale:Int = 1;
	
	public var lastSpeaker:String = "";
	public var currentSpeaker:String = "";
	public var speakerSprite:TiledBitmapData = null;
	public var speakerSpriteData:Dynamic;
	public var speakerSpriteMap:Map<String, OneOfTwo<Pair<Int>, Map<String, Pair<Int>>>> = null;
	public var dialogSpeakerSprite:LocalSpriteWrapper = null;
	public var speakerText:LocalWrapper<FlxText> = null;
	public var speakerBackground:FlxLocalSprite = null;
	public var speakerPadding:Int = 6;
	public var speakerImage:LocalSpriteWrapper = null;
	public var speakerOffset:Pair<Int> = [0, 0];
	public var textOffset:Pair<Int> = [0, 0];
	
	public var textPreprocess:DialogBox -> String -> String = null;
	public var callback:?String -> Void = null;
	public var boxCallback:Void -> Void = null;
	public var emitCallback:String -> Void = null;
	public var boxCallbackStr:String = null;
	public var canAdvance:Bool = true;
	
	public var options:Dynamic;
	public var optionsTween:FlxTween;
	public var selectOptionSprite:Dynamic = null;
	public var optionsOffset:Pair<Int> = [0, 0];

	public var speakerBoxTop:Float;
	
	public var choicesTaken:Array<String>;
	public var variables:Map<String, Dynamic>;
	public var globalVariables:Map<String, Dynamic>;
	public var globalReferences:Array<String>;
	public var pointer:DialogSequencePointer;
	public var labels:Map<String, Int>;
	
	private function getFlag(position:Int):DialogBoxFlag {
		for (flag in flags) {
			var name:String = flag.name;
			var count:Int = 0;
			for (flag in flags) {
				if (flag.type != POINT && flag.name == name && flag.position <= position) {
					count += (flag.type == START ? 1 : -1);
				}
			}
			if (count != 0) {
				return flag;
			}
		}
		return null;
	}
	
	private function getPointFlag(position:Int):DialogBoxFlag {
		for (flag in flags) {
			if (flag.type == POINT && flag.position == position) {
				return flag;
			}
		}
		return null;
	}
	
	private static function _typeOutAction(text:String, frames:Int, ?options:Dynamic):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
							var spriteAsText:FlxText = cast(sprite, FlxText);
							var utf8Text:UTF8String = new UTF8String(text);

							object.options = options;
							object.currentLength = 0;
							object.done = false;
							
							spriteAsText.text = text;
							
							var builtText:String = '';
							var characterPositions:Array<Pair<Float>> = [];
							var lastPosition:Pair<Float> = [0, 0];
							for (i in 0...utf8Text.length) {
								var posn = spriteAsText.textField.getCharBoundaries(i);
								characterPositions.push([posn.x, posn.y]);
								if (i > 0 && lastPosition.x > posn.x) {
									builtText = builtText.substring(0, builtText.length - 1) + '\n';
								}
								builtText += utf8Text.charAt(i);
								lastPosition = [posn.x, posn.y];
							}
							object.text = builtText.toString();
							var og:Pair<Float> = [characterPositions[0].x, characterPositions[0].y];
							object.characterPositions = [for (cp in characterPositions) cp - og];
							spriteAsText.text = "";
						  },
              function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                var db:DialogBox = cast(object.options.target, DialogBox);
							  if (db.pause > 0) {
								  db.pause -= 1;
								  return;
							  }
                if (db.textAppearCallback != null) {
                  db.textAppearCallback(frame);
                }

							  var textSprite:FlxText = cast(sprite, FlxText);
							  var utf8Text:UTF8String = new UTF8String(object.text);
							  var prevLength:Int = object.currentLength;
							  var addCount:Int = Std.int(utf8Text.length / frames);
							  if (addCount < 1) addCount = 1;
							  var newLength:Int = prevLength + addCount;
							  if (newLength >= utf8Text.length) {
								  newLength = utf8Text.length;
								  object.done = true;
							  }
							  
							  if (db.flags.length == 0) {
                  textSprite.text = utf8Text.substring(0, newLength);
							  } else {
								var diff:UTF8String = utf8Text.substring(prevLength, newLength);
								
								for (i in prevLength...newLength) {
									var flag = db.getFlag(i);
									var posn:Pair<Float> = object.characterPositions[i];
									var db:DialogBox = cast(object.options.target, DialogBox);
									
									if (flag == null) {
										var lc = new LocalWrapper<FlxText>(new FlxText(0, 0, 0, utf8Text.charAt(i)));
										setTextFormat(lc._sprite, object.options.textFormat);
										db.movieClipContainer.add(lc);
										lc.x = posn.x;
										lc.y = posn.y;
									} else {
										var wt:FlxLocalSprite = flag.flagAction(utf8Text.charAt(i));
										var lc = wt;
										db.movieClipContainer.add(lc);
										lc.x = posn.x;
										lc.y = posn.y;
									}
									
									var genericFlag = db.getPointFlag(i);
									if (genericFlag != null) {
										genericFlag.genericAction(db);
									}
									
									if (db.pause > 0) {
										newLength = i + 1;
										break;
									}
								}
							  }
							  object.currentLength = newLength;
						  },
						  frames);
	}
	
	private static function _slideInAction(direction:String, frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
							  if (direction.charAt(0) == "l") {
								  object.direction = [ -1, 0];
							  } else if (direction.charAt(0) == "r") {
								  object.direction = [1, 0];
							  } else if (direction.charAt(0) == "u") {
								  object.direction = [0, -1];
							  } else if (direction.charAt(0) == "d") {
								  object.direction = [0, 1];
							  } else {
								  trace("Error: unknown `slideIn` direction " + direction + " (defaulting to right)");
								  object.direction = [1, 0];
							  }
							  object.bitmapData = sprite.pixels.clone();
						  },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  sprite.pixels.copyPixels(object.bitmapData, object.bitmapData.rect, new Point(0, 0));
							  var ratio:Float = (frames - frame) / frames;
							  if (object.direction[1] == 0) {
								  var wid:Int = Std.int(object.bitmapData.width * ratio);
								  sprite.pixels.fillRect(new Rectangle((object.direction[0] < 0 ? object.bitmapData.width - wid : 0), 0, wid, object.bitmapData.height),
														 0x00000000);
							  } else {
								  var hei:Int = Std.int(object.bitmapData.height * ratio);
								  sprite.pixels.fillRect(new Rectangle(0, (object.direction[1] < 0 ? object.bitmapData.height - hei : 0), object.bitmapData.width, hei),
														 0x00000000);
							  }
						  },
						  frames);
	}
	
  /**
    * Create a 'type-out' action like what's used in the TYPEWRITER dialog box style.
    */
	public static function typeOut(sprite:OneOfTwo<FlxText, Actor>, text:String, frames:Int, ?options:Dynamic):Actor {
		return Director.directorChainableFn(_typeOutAction(text, frames, options), cast(sprite, FlxSprite), DIRECTOR_DIALOG_TRANSITION_STR,
			function(a:Actor):Bool { return a.action.object.done; } );
	}
	
  /**
    * Create a 'slide-in' action like what's used in the SCROLL dialog box style.
    */
	public static function slideIn(sprite:OneOfTwo<FlxSprite, Actor>, startOffset:String, frames:Int):Actor {
		return Director.directorChainableFn(_slideInAction(startOffset, frames), cast(sprite, FlxSprite), DIRECTOR_SLIDEIN_TRANSITION_STR);
	}
	
	public function new(messages:DialogNodeSequence, options:Dynamic) {
		super();
		
		if (messages != null) {
			InputController.consume(Button.CONFIRM);
			
			this.messages = messages;
			this.pointer = new DialogSequencePointer(messages, 0);
			this.labelMap = new Map<String, Int>();
		
			for (i in 0...this.messages.length) {
				var node:DialogSyntaxNode = this.messages.sequence[i];
				if (node.type == LABEL) {
					this.labelMap.set(node.value, i);
				}
			}
		}
		
		this.options = options;
		
		this.labels = new Map<String, Int>();
		this.variables = new Map<String, Dynamic>();
		this.globalVariables = new Map<String, Dynamic>();
		this.globalReferences = new Array<String>();
		this.choicesTaken = new Array<String>();
		this.flags = new Array<DialogBoxFlag>();
		
		if (Reflect.hasField(options, 'scale')) {
			Reflect.setField(this, 'globalScale', Reflect.field(options, 'scale'));
		}
		
		for (supportedField in ['abort', 'align', 'skip', 'advanceStyle', 'advanceLength',
		                        'textAppearCallback', 'callback', 'abortCallback', 'emitCallback', 'advanceCallback',
								'selectOptionSprite', 'globalVariables', 'speakerSpriteMap', 'textPreprocess', 'textPadding']) {
			if (Reflect.hasField(options, supportedField)) {
				Reflect.setField(this, supportedField, Reflect.field(options, supportedField));
			}
		}

		textPadding *= globalScale;
		
		if (Reflect.hasField(options, 'background')) {
			var bgSrc:FlxSprite = new FlxSprite();
			var bitmapData:BitmapData = BitmapDataUtils.loadFromObject(options.background);
			bgSrc.loadGraphic(bitmapData);
			bgSprite = new LocalSpriteWrapper(bgSrc);
			this.add(bgSprite);
			
			width = bgSprite.width;
			height = bgSprite.height;
		}
		
		if (Reflect.hasField(options, 'speakerSprite')) {
			speakerSprite = BitmapDataUtils.loadTilesFromObject(options.speakerSprite);
			speakerSpriteData = options.speakerSprite;
		}
		
		if (Reflect.hasField(options, 'speakerBackground')) {
			var dialogSpeakerSrc:FlxSprite = new FlxSprite();
			var bitmapData:BitmapData = BitmapDataUtils.loadFromObject(options.speakerBackground);
			this.speakerBackground = options.speakerBackground;
			dialogSpeakerSrc.loadGraphic(bitmapData);
			dialogSpeakerSprite = new LocalSpriteWrapper(dialogSpeakerSrc);
			this.add(dialogSpeakerSprite);
			if (Reflect.hasField(options.speakerBackground, 'offset')) {
				speakerOffset = [Std.int(options.speakerBackground.offset.x * globalScale), Std.int(options.speakerBackground.offset.y * globalScale)];
			}
			if (Reflect.hasField(options.speakerBackground, 'padding')) {
				speakerPadding = options.speakerBackground.padding;
			}
			if (Reflect.hasField(options.speakerBackground, 'textOffset')) {
				textOffset = [Std.int(options.speakerBackground.textOffset.x * globalScale), Std.int(options.speakerBackground.textOffset.y * globalScale)];
			}
			speakerBoxTop = -dialogSpeakerSprite.height + speakerOffset.y;
			dialogSpeakerSprite.y = speakerBoxTop;
			dialogSpeakerSprite.x = (5 * globalScale) + speakerOffset.x;
			dialogSpeakerSprite.visible = false;
		}
		speakerPadding *= globalScale;
		
		if (options.prop('selectOptionSprite.offset') != null) {
			optionsOffset = [Std.int(options.prop('selectOptionSprite.offset.x')), Std.int(options.prop('selectOptionSprite.offset.y'))];
		}
		
		if (Reflect.hasField(options, 'advanceIndicator')) {
			var advanceIndicatorSrc = new FlxSprite();
			
			var advanceIndicator:Dynamic = options.advanceIndicator;
			if (!Reflect.hasField(advanceIndicator, 'nextFrames')) {
				trace("Warning: parameter `advanceIndicator` has no Array field `nextFrames`!");
			}
			if (!Reflect.hasField(advanceIndicator, 'finishFrames')) {
				trace("Warning: parameter `advanceIndicator` has no Array field `finishFrames`!");
			}
			this.advanceIndicatorInfo = {
				image: BitmapDataUtils.loadFromObject(advanceIndicator),
				nextFrames: Reflect.hasField(advanceIndicator, 'nextFrames') ? advanceIndicator.nextFrames : [0],
				finishFrames: Reflect.hasField(advanceIndicator, 'finishFrames') ? advanceIndicator.finishFrames : [0]
			}
			advanceIndicatorSrc.loadGraphic(advanceIndicatorInfo.image, true,
										    (Reflect.hasField(advanceIndicator, 'width') ? advanceIndicator.width : advanceIndicator.image.width),
											(Reflect.hasField(advanceIndicator, 'height') ? advanceIndicator.height : advanceIndicator.image.height));

			advanceIndicatorSrc.animation.add('next', advanceIndicatorInfo.nextFrames, 5);
			advanceIndicatorSrc.animation.add('finish', advanceIndicatorInfo.finishFrames, 5);
			advanceIndicatorSrc.animation.play('next');
			advanceIndicatorSrc.x = width - advanceIndicatorSrc.width - textPadding.x;
			advanceIndicatorSrc.y = height - advanceIndicatorSrc.height - textPadding.y;
			advanceIndicatorSprite = new LocalSpriteWrapper(advanceIndicatorSrc);
			
			if (advanceIndicator.animation != null) {
				var destination:Dynamic = {x: advanceIndicator.animation.x + advanceIndicatorSrc.x,
				                           y: advanceIndicator.animation.y + advanceIndicatorSrc.y};
				advanceIndicatorTween = FlxTween.tween(advanceIndicatorSprite, destination, 0.3,
													   {ease: FlxEase.expoInOut, type: 4});
			}
			add(advanceIndicatorSprite);
		}
		
		if (Reflect.hasField(options, 'beforeMount')) {
			options.beforeMount(this);
		}
		
		text = new LocalWrapper<FlxText>(new FlxText());
		add(text);
		setTextFormat(text._sprite, options.textFormat);
		
		this.movieClipContainer = new FlxLocalSprite();
		add(this.movieClipContainer);
		
		if (messages != null) {
			if (pointer.get().type != TEXT && pointer.get().type != CHOICE_BOX) {
				advanceUntilBlocked(false);
			}
			if (pointer.get().type == RETURN) {
				if (this.callback != null) {
					this.callback(pointer.get().value);
				} else {
					trace("Warning: called RETURN statement without any callback function!");
				}
				finished = true;
				return;
			}
			renderText(parseDialogNode());
		}
		movieClipContainer.x = text.x;
		movieClipContainer.y = text.y;
	}
	
	public function parseDialogNode():Dynamic {
		var current:DialogSyntaxNode = pointer.get();
		
		if (current.type == TEXT) {
			var build:Dynamic = current.value.clone();
			return build;
		}
		if (current.type == CHOICE_BOX) {
			var build:Dynamic = {
				text: "",
				choices: []
			}
			for (child in current.child.sequence) {
				if (child.type == TEXT) {
					build = build.merge(child.value);
				}
			}
			scrapeChoices(current.child, build.choices);
			return build;
		}
		return null;
	}
	
	public function scrapeChoices(sequence:DialogNodeSequence, choices:Array<Dynamic>):Void {
		for (s in sequence.sequence) {
			if (s.type == CHOICE) {
				choices.push([s.value.text, s.value.tag]);
			} else if (s.type == IF) {
				var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in globalVariables.keys()) {
					mergedVariables.set(k, globalVariables.get(k));
				}
				for (k in variables.keys()) {
					if (globalReferences.indexOf(k) == -1) {
						mergedVariables.set(k, globalVariables.get(k));
					}
				}
				var exp:ExpressionNode = s.value.evaluate(mergedVariables);
				if (exp.type == INTEGER && exp.value > 0) {
					scrapeChoices(s.child, choices);
				}
			}
		}
	}
	
	private function advanceUntilBlocked(stepFirst:Bool = true) {
		var steppedFirst = false;
		while (true) {
			if (stepFirst || steppedFirst) {
				pointer.step();
			}
			steppedFirst = true;
			var node:DialogSyntaxNode = pointer.get();
			if (node == null || node.type == TEXT || node.type == CHOICE_BOX || node.type == RETURN || node.type == FUNCTION) {
				return;
			} else if (node.type == JUMP) {
				var label:String = node.value;
				if (labelMap.exists(label)) {
					pointer.sequence = messages;
					pointer.index = labelMap.get(label);
				} else if (label == 'end') {
					pointer.sequence = null;
					return;
				} else {
					trace("Label " + label + " doesn't exist!");
				}
			} else if (node.type == IF) {
				var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in globalVariables.keys()) {
					mergedVariables.set(k, globalVariables.get(k));
				}
				for (k in variables.keys()) {
					if (globalReferences.indexOf(k) == -1) {
						mergedVariables.set(k, globalVariables.get(k));
					}
				}
				var exp:ExpressionNode = node.value.evaluate(mergedVariables);
				if (exp.type == INTEGER && exp.value > 0) {
					pointer.sequence = node.child;
					pointer.index = -1;
				}
			} else if (node.type == VARIABLE_ASSIGN) {
				var global:Bool = false;
				if (globalReferences.indexOf(node.value.name) != -1) {
					global = true;
				}
				if (globalVariables.exists(node.value.name) && !variables.exists(node.value.name)) {
					global = true;
				}
				if (global) {
					globalVariables.set(node.value.name, node.value.value);
				} else {
					variables.set(node.value.name, node.value.value);
				}
			} else if (node.type == GLOBAL) {
				globalReferences.push(node.value);
			} else if (node.type == EMIT) {
				emitCallback(node.value);
			} else if (node.type == DEBUG) {
				var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in globalVariables.keys()) {
					mergedVariables.set(k, globalVariables.get(k));
				}
				for (k in variables.keys()) {
					if (globalReferences.indexOf(k) == -1) {
						mergedVariables.set(k, globalVariables.get(k));
					}
				}
				trace('DEBUG [line ${node.value.line}]: ${node.value.name} = ' + mergedVariables.get(node.value.name));
			}
		}
	}
	
	public function renderText(message:Dynamic) {
		var nextTextStr:String;
		var nextSpeaker:String = "";

		if (speakerText != null) {
			remove(speakerText);
			speakerText.destroy();
		}

		if (Std.is(message, String)) {
			nextTextStr = message;
			if (textPreprocess != null) {
				nextTextStr = textPreprocess(this, nextTextStr);
			}
		} else {
			if (Reflect.hasField(message, 'text')) {
				nextTextStr = message.text;
			} else {
				nextTextStr = '';
			}
			if (textPreprocess != null) {
				nextTextStr = textPreprocess(this, nextTextStr);
			}
			nextSpeaker = message.speaker;
			if (nextSpeaker == null) nextSpeaker = '';
			if (choiceSprite != null) {
				remove(choiceSprite);
				choiceSprite.destroy();
				choiceSprite = null;
				remove(choiceIndicator);
				choiceIndicator.destroy();
			}
			if (Reflect.hasField(message, 'choices')) {
				choices = [for (i in cast(message.choices, Array<Dynamic>)) i[0]];
				choiceIndex = 0;
				mode = DialogBoxMode.SELECT_OPTION;
				var strIndex = 0;
				var choiceText:FlxText = new FlxText(0, 0, 0);
				if (Reflect.hasField(options, 'choiceTextFormat')) {
					setTextFormat(choiceText, StructureUtils.merge(options.choiceTextFormat, {size: 5 * globalScale}));
				} else {
					setTextFormat(choiceText, StructureUtils.merge(options.textFormat, {size: 5 * globalScale}));
				}
				
				choiceSprite = new LocalWrapper(choiceText);
				add(choiceSprite);

				var selectWrapper = new FlxSprite();
				if (selectOptionSprite != null) {
					selectWrapper.loadGraphic(BitmapDataUtils.loadFromObject(selectOptionSprite));
				} else {
					trace("Warning: `selectOptionSprite` is null!");
				}
				choiceIndicator = new LocalSpriteWrapper(selectWrapper);
				add(choiceIndicator);
			} else {
				mode = DialogBoxMode.NORMAL;
				nextTextStr = message.text;
				if (textPreprocess != null) {
					nextTextStr = textPreprocess(this, nextTextStr);
				}
			}
		}
		if (nextSpeaker != currentSpeaker && dialogSpeakerSprite != null) {
			//remove
		}
		
		var textX:Int = textPadding.x + (Reflect.hasField(options, 'textOffset') ? options.textOffset[0] : 0);
		if (speakerImage != null) {
			remove(speakerImage);
			speakerImage = null;
		}
		
		if (nextSpeaker != "") {
      if (Reflect.hasField(options, 'speakerBackground')) {
        if (dialogSpeakerSprite != null) {
          dialogSpeakerSprite.visible = true;
        }
        speakerText = new LocalWrapper<FlxText>(new FlxText(0, 0, 0, nextSpeaker));
        setTextFormat(speakerText._sprite, options.textFormat);
        speakerText.x = 5 * globalScale + speakerOffset.x + textOffset.x + speakerPadding;
        speakerText.y = speakerBoxTop + this.dialogSpeakerSprite.height - speakerText.height - 4 * globalScale + textOffset.y;
        speakerText.width = speakerText._sprite.width;
        if (speakerBackground != null) {
          var speakerBitmapData:BitmapData = BitmapDataUtils.loadFromObject(speakerBackground);
          dialogSpeakerSprite._sprite.loadGraphic(BitmapDataUtils.horizontalStretchCenter(speakerBitmapData,
                                              speakerPadding,
                                              Std.int(speakerText.width) + 2 * speakerPadding));
        }
        add(speakerText);
      }

			if (speakerSpriteMap != null && speakerSprite != null && speakerSpriteMap.exists(nextSpeaker)) {
				if (Std.is(speakerSpriteMap.get(nextSpeaker), Array)) {
					var loc:Pair<Int> = speakerSpriteMap.get(nextSpeaker);
					speakerImage = new LocalSpriteWrapper(new FlxSprite(speakerSprite.getTile(loc)));
				} else {
					var m:Map<String, Pair<Int>> = speakerSpriteMap.get(nextSpeaker);
					if (Reflect.hasField(message, 'mood')) {
						var mood:String = message.mood;
						if (m.exists(mood)) {
							var loc = m.get(mood);
							speakerImage = new LocalSpriteWrapper(new FlxSprite(speakerSprite.getTile(loc)));
						}
					} else if (m.exists('default')) {
						var loc = m.get('default');
						speakerImage = new LocalSpriteWrapper(new FlxSprite(speakerSprite.getTile(loc)));
					}
				}
			}
			if (speakerImage != null) {
				add(speakerImage);
				speakerImage.y = (bgSprite.height - speakerImage.height) / 2 + (Reflect.hasField(speakerSpriteData, 'offset') ? speakerSpriteData.offset[1] : 0);
				speakerImage.x = textPadding.x + (Reflect.hasField(speakerSpriteData, 'offset') ? speakerSpriteData.offset[0] : 0);
				textX += textPadding.x + Std.int(speakerImage.width);
				if (lastSpeaker != nextSpeaker && Reflect.hasField(speakerSpriteData, 'transitionIn')) {
					speakerSpriteData.transitionIn(speakerImage);
				}
			}
			lastSpeaker = nextSpeaker;
		} else {
			if (dialogSpeakerSprite != null) {
        dialogSpeakerSprite.visible = false;
      }
		}
		/*if (index > 0 && advanceSound != null) {
			FlxG.sound.load(advanceSound).play();
		}*/
		if (this.advanceStyle == DialogAdvanceStyle.NONE) {
			remove(text);
			text.destroy();
			text = new LocalWrapper(new FlxText(0, 0,
											    bgSprite.width - textX - textPadding.x,
											    nextTextStr));
			setTextFormat(text._sprite, options.textFormat);
			text.x = textX;
			text.y = textPadding.y + (Reflect.hasField(options, 'textOffset') ? options.textOffset[1] : 0);
			text._sprite.fieldWidth = bgSprite.width - textPadding.x - text.x;
			if (choiceSprite != null) {
				choiceSprite.x = textX + choiceIndicator.width + globalScale * optionsOffset.x;
				if (nextTextStr.length > 0) {
					choiceSprite.y = text.y + text._sprite.textField.getLineMetrics(0).height + 5 + globalScale * optionsOffset.y;
				} else {
					choiceSprite.y = text.y + globalScale * optionsOffset.y;
				}
				redrawOptions();
			}
			add(text);
			if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
		} else if (this.advanceStyle == DialogAdvanceStyle.SCROLL) {
			advancing = true;
			if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = false;
			nextText = new LocalWrapper(new FlxText(0, 0,
												    bgSprite.width - (2 * textPadding.x),
												    nextTextStr));
			nextText.x = textX;
			nextText.y = textPadding.y + bgSprite.height;
			setTextFormat(nextText._sprite, options.textFormat);
			nextText._sprite.draw();
			bottomImageStore = new FlxSprite();
			bottomImageStore.pixels = nextText._sprite.pixels.clone();
			add(nextText);
	
			Director.afterAll(null,
				[text.moveBy([0, -Std.int(bgSprite.height)], advanceLength, {tag: DIRECTOR_DIALOG_TRANSITION_STR}),
				 nextText.moveBy([0, -Std.int(bgSprite.height)], advanceLength, {tag: DIRECTOR_DIALOG_TRANSITION_STR})]).call(function(sprite:FlxSprite) {
					this.remove(text);
					text.destroy();
					text = nextText;
					advancing = false;
					if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
				});
		} else if (this.advanceStyle == DialogAdvanceStyle.TYPEWRITER) {
			advancing = true;
			if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = false;
			remove(text);
			text.destroy();
			text = new LocalWrapper(new FlxText(textX, textPadding.y,
											    bgSprite.width - textX - textPadding.x,
											    nextTextStr));
			add(text);
			setTextFormat(text._sprite, options.textFormat);
			if (choiceSprite != null) {
				choiceSprite.x = textX + choiceIndicator.width + globalScale * optionsOffset.x;
				if (nextTextStr.length > 0) {
					choiceSprite.y = text.y + text._sprite.textField.getLineMetrics(0).height + 5 + globalScale * optionsOffset.y;
				} else {
					choiceSprite.y = text.y + globalScale * optionsOffset.y;
				}
				choiceSprite.visible = false;
				choiceIndicator.visible = false;
				redrawOptions();
			}
			
			DialogBox.typeOut(this.text._sprite, nextTextStr, advanceLength, {target: this, textFormat: options.textFormat}).call(function(sprite:FlxSprite) {
				advancing = false;
				if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
				if (choiceSprite != null) {
					choiceSprite.visible = true;
					choiceIndicator.visible = true;
				}
			});
		}
	}
	
  /**
    * Advances the dialog box and re-renders the box with the new text,
    * applying animations if appropriate.
    */
	public function advanceAndRender() {
		advanceUntilBlocked();
		
		remove(movieClipContainer);
		movieClipContainer = new FlxLocalSprite();
		add(movieClipContainer);

    if (advanceCallback != null) {
      advanceCallback();
    }
			
		if (pointer.get() != null) {
			if (pointer.get().type == RETURN) {
				if (this.callback != null) {
					this.callback(pointer.get().value);
				} else {
					trace("Warning: called RETURN statement without any callback function!");
				}
				finished = true;
				return;
			} else if (pointer.get().type == FUNCTION) {
				pointer.get().value(this);
				return;
			}
			renderText(parseDialogNode());
			movieClipContainer.x = text.x;
			movieClipContainer.y = text.y;
		} else {
			if (this.callback != null && boxCallbackStr == null) {
				this.callback();
			}
			finished = true;
		}
	}
	
  /**
    * Re-renders the 'option select' component if it is currently showing.
    */
	public function redrawOptions() {
		var choiceTextStr = this.choices.join('\n');
		var lineHeight = choiceSprite._sprite.textField.getLineMetrics(0).height;
		var anchor:Int = 0;
		if (choices.length * lineHeight > bgSprite.height - 2 * textPadding.y) {
			anchor = choiceIndex - 1;
			if (anchor < 0) anchor = 0;
			if (anchor > choices.length - 4) anchor = choices.length - 4;
			choiceTextStr = [for (i in anchor...anchor + 4) choices[i]].join('\n');
		}
		choiceSprite._sprite.text = choiceTextStr;
		/*for (i in 0...choices.length) {
			var len = choices[i].length;
			if (choicesTaken.indexOf(message.choices[i][1]) != -1) {
				choiceSprite._sprite.addFormat(new FlxTextFormat(FlxColor.GRAY), strIndex, strIndex + len);
			}
			strIndex += len + 1;
		}*/
		choiceIndicator.x = choiceSprite.x - choiceIndicator.width - 5;
		choiceIndicator.y = choiceSprite.y + (choiceIndex - anchor) * choiceSprite._sprite.textField.getLineMetrics(0).height;
	}
	
	public function handleInput():Void {
		var message:Dynamic = parseDialogNode();
		var advance:Bool = InputController.justPressed(Button.CONFIRM);
		if (advance) {
			InputController.consume(Button.CONFIRM);
		}
		
		if (this.mode == DialogBoxMode.NORMAL) {
			if (advance && canAdvance) {
				if (!advancing) {
					advanceAndRender();
				} else if (skip) {
					var advanceTransitions:Array<Actor> = Director.actorsWithTag(DIRECTOR_DIALOG_TRANSITION_STR);
					for (i in 0...advanceTransitions.length) {
						advanceTransitions[i].skipToEnd();
					}
				}
			}
			/*if (abort) {
				if (this.abortCallback != null && index == messages.length - 1) {
					this.abortCallback();
					this.destroy();
				}
			}*/
		} else if (this.mode == DialogBoxMode.SELECT_OPTION) {
			if (InputController.justPressed(Button.DOWN)) {
				if (choiceIndex < choices.length - 1) {
					++choiceIndex;
					redrawOptions();
				}
			} else if (InputController.justPressed(Button.UP)) {
				if (choiceIndex > 0) {
					--choiceIndex;
					redrawOptions();
				}
			} else if (advance) {
				var jumpToLabel = message.choices[choiceIndex][1];

				if (labelMap.exists(jumpToLabel)) {
					pointer.sequence = messages;
					pointer.index = labelMap.get(jumpToLabel);
					if (choicesTaken.indexOf(jumpToLabel) == -1) {
						choicesTaken.push(jumpToLabel);
					}
					advanceAndRender();
				} else if (jumpToLabel == 'end') {
					if (this.callback != null && boxCallbackStr == null) {
						this.callback();
					}
					finished = true;
				} else {
					trace("No label " + jumpToLabel + " found!");
					advanceAndRender();
				}
			}
		}
	}
	
	public function setLocked(locked:Bool):Void {
		canAdvance = locked;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		
		if (advancing && this.advanceStyle == DialogAdvanceStyle.SCROLL) {
			var top:Float = textPadding.y;
			var bottom:Float = bgSprite.height - textPadding.y;
			if (this.text.y < top) {
				var transparentRect:BitmapData = new BitmapData(Std.int(this.text.width), Std.int(top - this.text.y), true, 0);
				this.text._sprite.pixels.copyPixels(transparentRect, transparentRect.rect, new Point(0, 0));
			}
			if (this.nextText.y + this.nextText.height + textPadding.y > bottom) {
				var transparentRect:BitmapData = new BitmapData(Std.int(this.nextText.width), Std.int(this.nextText.y + this.nextText.height + textPadding.y - bottom), true, 0);
				this.nextText._sprite.pixels = bottomImageStore.pixels.clone();
				this.nextText._sprite.pixels.copyPixels(transparentRect, transparentRect.rect, new Point(0, this.nextText._sprite.height - transparentRect.height));
			} else if (bottomImageStore != null) {
				this.nextText._sprite.pixels = bottomImageStore.pixels.clone();
				this.bottomImageStore = null;
			}
		}
	}
	
	static function setTextFormat(text:FlxText, format:TextFormat) {
		var font:String = format.font;
		var size:Int = Std.int(format.size != null ? format.size : DEFAULT_FONT_SIZE);
		var color:FlxColor = (format.color != null ? FlxColor.fromInt(format.color) : FlxColor.BLACK);

		text.setFormat(font, size, color);
	}
}
