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
import nova.ui.text.RichText;
import nova.ui.text.ShakeText;
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
	
	public var labelMap:Map<String, DialogSequencePointer>;
	
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
	public var pause:Int = 0;
	
	public var choices:Array<String>;
  public var choiceBox:DialogChoiceBox = null;
	
	public var backgroundPadding:Pair<Int> = [0, 0];
	public var textPadding:Pair<Int> = [DEFAULT_TEXT_PADDING_X, DEFAULT_TEXT_PADDING_Y];
	
	public var textFormat:Dynamic;
	public var optionsTextFormat:Dynamic;
	
	public var bgSprite:LocalSpriteWrapper = null;
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
	public var pointer:InstructionPointer;
	public var labels:Map<String, Int>;
  
  public var flags:Array<DialogBoxFlag>;
  
  public var creationClasses:Map<String, Class<RichText>> = null;
  public var colors:Map<String, Int>;
	
	private static function _typeOutActor(text:String, frames:Int, ?options:Dynamic):PartialActor {
		return new PartialActor(function(sprite:FlxSprite, object:Dynamic) {
							var spriteAsText:FlxText = cast(sprite, FlxText);

							object.options = options;
							object.currentLength = 0;
                            object.flagPosition = 0;
                            object.creationFn = null;
                            object.textFormat = StructureUtils.clone(object.options.textFormat);
							object.done = false;

                            var db:DialogBox = cast(object.options.target, DialogBox);
                            var newText:String = text;

                            var i = db.flags.length - 1;
                            while (i >= 0) {
                                var tokens = db.flags[i].name.split(' ');
                                if (tokens[0] != 'var') {
                                    --i;
                                    continue;
                                }

                                newText = newText.substring(0, db.flags[i].position) +
                                          db.pointer.getVariable(tokens[1]) +
                                          newText.substring(db.flags[i].position);

                                --i;
                            }
                            object.text = newText;

							var utf8Text:UTF8String = new UTF8String(newText);
							
							spriteAsText.text = newText;

                            if (Reflect.hasField(db.options, 'textCenter')) {
                                db.text.x = (db.width - spriteAsText.textField.textWidth) / 2;
                                db.text.y = (db.height - spriteAsText.textField.textHeight) / 2 - 4;
                            }
							
							var builtText:String = '';
							var characterPositions:Array<Pair<Float>> = [];
							var lastPosition:Pair<Float> = [0, 0];
							for (i in 0...utf8Text.length) {
								var posn = spriteAsText.textField.getCharBoundaries(i);
                                if (posn == null) {
                                  posn = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);
                                }
                                characterPositions.push([posn.x, posn.y]);
								if (i > 0 && lastPosition.x > posn.x) {
									builtText = builtText.substring(0, builtText.length - 1) + '\n';
								}
								builtText += utf8Text.charAt(i);
								lastPosition = [posn.x, posn.y];
							}
							if (characterPositions.length > 0) {
								var og:Pair<Float> = [characterPositions[0].x, characterPositions[0].y];
								object.characterPositions = [for (cp in characterPositions) cp - og];
							}
							object.text = builtText.toString();
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
                  for (i in prevLength...newLength) {
                    var startingPosition = object.flagPosition;
                    while (object.flagPosition < db.flags.length && db.flags[object.flagPosition].position == i) {
                      object.flagPosition += 1;
                    }
                    for (j in startingPosition...object.flagPosition) {
                      var flag:DialogBoxFlag = db.flags[j];
                      var tokens = flag.name.split(' ');
                      if (tokens[0] == 'delay' || tokens[0] == 'd') {
                        db.pause = Std.parseInt(tokens[1]);
                      } else if (tokens[0] == 'emit') {
                        db.emitCallback(tokens.slice(1).join(' '));
                      }
                      
                      if (db.colors != null) {
                        if (db.colors.exists(tokens[0])) {
                          object.textFormat.color = db.colors[tokens[0]];
                        } else if (db.colors.exists(tokens[0].substring(1)) && tokens[0].charAt(0) == '/') {
                            object.textFormat.color = object.options.textFormat.color;
                        }
                      }
                      
                      if (db.creationClasses != null) {
                        if (db.creationClasses.exists(tokens[0])) {
                          object.creationFn = function(s, t) { return Type.createInstance(db.creationClasses[tokens[0]], [s, t]); };
                        } else if (db.creationClasses.exists(tokens[0].substring(1)) && tokens[0].charAt(0) == '/') {
                            object.creationFn = null;
                        }
                      }
                    }
                    var posn:Pair<Float> = object.characterPositions[i];
                    
                    var db:DialogBox = cast(object.options.target, DialogBox);
                    
                    if (object.creationFn == null) {
                      var lc = new LocalWrapper<FlxText>(new FlxText(0, 0, 0, utf8Text.charAt(i)));
                      setTextFormat(lc._sprite, object.textFormat);
                      db.movieClipContainer.add(lc);
                      lc.x = posn.x;
                      lc.y = posn.y;
                    } else {
                      var tf:TextFormat = object.textFormat;
                      var rt:FlxLocalSprite = object.creationFn(utf8Text.charAt(i), StructureUtils.clone(tf));
                      rt.x = posn.x;
                      rt.y = posn.y;
                      db.movieClipContainer.add(rt);
                    }
                    
                    if (db.pause > 0) {
                      newLength = i + 1;
                      break;
                    }
                  }
							  }
							  object.currentLength = newLength;
						  },
						  function(a:Actor) {
                  return a.action.object.done;
              });
	}
	
	private static function _slideInActor(direction:String, frames:Int):PartialFrameBasedActor {
		return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) {
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
	  	return Director.directorChainableFn(
                 _typeOutActor(text, frames, options),
                 cast(sprite, FlxSprite),
                 DIRECTOR_DIALOG_TRANSITION_STR
      );
	}
	
  /**
    * Create a 'slide-in' action like what's used in the SCROLL dialog box style.
    */
	public static function slideIn(sprite:OneOfTwo<FlxSprite, Actor>, startOffset:String, frames:Int):Actor {
		return Director.directorChainableFn(_slideInActor(startOffset, frames), cast(sprite, FlxSprite), DIRECTOR_SLIDEIN_TRANSITION_STR);
	}
	
	public function new(messages:DialogNodeSequence, options:Dynamic) {
		super();
		
		this.labels = new Map<String, Int>();
		this.variables = new Map<String, Dynamic>();
        this.globalReferences = [];
		
		this.options = options;
		this.choicesTaken = new Array<String>();
		this.flags = new Array<DialogBoxFlag>();
        this.colors = new Map<String, Int>();
		
		if (Reflect.hasField(options, 'scale')) {
			Reflect.setField(this, 'globalScale', Reflect.field(options, 'scale'));
		}
		
		for (supportedField in ['abort', 'align', 'skip', 'advanceStyle', 'advanceLength',
		                        'textAppearCallback', 'callback', 'abortCallback', 'emitCallback', 'advanceCallback',
								'selectOptionSprite', 'globalVariables', 'speakerSpriteMap', 'textPreprocess', 'textPadding', 'optionsOffset']) {
			if (Reflect.hasField(options, supportedField)) {
				Reflect.setField(this, supportedField, Reflect.field(options, supportedField));
			}
		}
 
		if (messages != null) {
			InputController.consume(Button.CONFIRM);
			
			this.messages = messages;
			this.labelMap = new Map<String, DialogSequencePointer>();
			for (i in 0...this.messages.length) {
				var node:DialogSyntaxNode = this.messages.sequence[i];
				if (node.type == LABEL) {
					this.labelMap.set(node.value, new DialogSequencePointer(this.messages, i));
				}
			}
			this.pointer = new InstructionPointer(messages, 0, labelMap, variables, globalVariables, emitCallback);
		}

		textPadding *= globalScale;
		
		if (Reflect.hasField(options, 'background')) {
			var bgSrc:FlxSprite = new FlxSprite();
			var bitmapData:BitmapData = BitmapDataUtils.loadFromObject(options.background);
			bgSprite = LocalSpriteWrapper.fromGraphic(bitmapData);
			this.add(bgSprite);
			
			width = bgSprite.width;
			height = bgSprite.height;
		} else {
            width = FlxG.width;
            height = FlxG.height;
        }
		
		if (Reflect.hasField(options, 'speakerSprite')) {
			speakerSprite = BitmapDataUtils.loadTilesFromObject(options.speakerSprite);
			speakerSpriteData = options.speakerSprite;
		}
		
        speakerBoxTop = 0;
        if (options.prop('speakerOffset') != null) {
            speakerBoxTop += options.speakerOffset[1];
        }
		if (options.prop('speakerBackground.image') != null) {
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
			speakerBoxTop += -dialogSpeakerSprite.height + speakerOffset.y;
			dialogSpeakerSprite.y = speakerBoxTop;
			dialogSpeakerSprite.x = (5 * globalScale) + speakerOffset.x + (Reflect.hasField(options, 'speakerOffset') ? options.speakerOffset[0] : 0);
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
		if (Reflect.hasField(options, 'textFormat')) setTextFormat(text._sprite, options.textFormat);
		
		this.movieClipContainer = new FlxLocalSprite();
		add(this.movieClipContainer);
		
		if (messages != null) {
			if (pointer.get().type != TEXT && pointer.get().type != CHOICE_BOX) {
				advanceUntilBlocked(false);
			}
			if (pointer.get() == null) {
                if (this.callback != null) {
					this.callback();
				}
                finished = true;
                return;
            } else if (pointer.get().type == RETURN) {
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
				choices.push([s.value.text, s.value.tag, s.value.type]);
			} else if (s.type == IF) {
				var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in pointer.globalVariables.keys()) {
					mergedVariables.set(k, pointer.globalVariables.get(k));
				}
				for (k in pointer.localVariables.keys()) {
          if (!pointer.globalVariables.exists(k)) {
						mergedVariables.set(k, pointer.localVariables.get(k));
					}
				}
				var exp:ExpressionNode = s.value.evaluate(mergedVariables);
				if (exp.type == INTEGER && exp.value > 0) {
					scrapeChoices(s.child, choices);
				}
			}
		}
	}
	
	private function advanceUntilBlocked(stepFirst:Bool = true, bypassText:Bool = false) {
		var steppedFirst = false;
		if (stepFirst || steppedFirst) {
			pointer.nextInstruction();
		}
    pointer.step(bypassText);
	}

	public function renderText(message:Dynamic) {
		var nextTextStr:String;
		var nextSpeaker:String = "";

		if (speakerText != null) {
			remove(speakerText);
			speakerText.destroy();
		}

		mode = DialogBoxMode.NORMAL;
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
			if (choiceBox != null) {
				remove(choiceBox);
				choiceBox.destroy();
				choiceBox = null;
			}
			if (Reflect.hasField(message, 'choices')) {
        var choicesArr:Array<Dynamic> = cast message.choices;
        var abortChoice:String = null;

        for (choice in choicesArr) {
          if (choice[2] == 'choice_abort') {
            abortChoice = choice[1];
            choicesArr = choicesArr.filter(function(k) { return k[2] != 'choice_abort'; });
          }
        }

				choices = [for (i in choicesArr) i[0]];
				var jumps:Array<String> = [for (i in choicesArr) i[1]];
				mode = DialogBoxMode.SELECT_OPTION;
				var strIndex = 0;
				
        var choiceBoxOptions:Dynamic = (Reflect.hasField(options, 'choiceBoxOptions') ? options.choiceBoxOptions : {});
        if (Reflect.hasField(options, 'choiceBoxCreationFn')) {
          choiceBox = options.choiceBoxCreationFn(choices, jumps, choiceBoxOptions);
        } else {
          choiceBox = new VerticalMenuChoiceBox(choices, jumps, choiceBoxOptions);
        }
        choiceBox.abortChoice = abortChoice;
        add(choiceBox);

				var selectWrapper = new FlxSprite();
				if (selectOptionSprite != null) {
					selectWrapper.loadGraphic(BitmapDataUtils.loadFromObject(selectOptionSprite));
				} else {
					trace("Warning: `selectOptionSprite` is null!");
				}
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
      }
      speakerText = new LocalWrapper<FlxText>(new FlxText(0, 0, 0, nextSpeaker));
      setTextFormat(
          speakerText._sprite,
          Reflect.hasField(options, 'speakerTextFormat') ? options.speakerTextFormat : options.textFormat
      );
      var speakerTextOffset:Pair<Float> = options.prop('speakerBackground.textOffset') ? [options.speakerBackground.textOffset.x, options.speakerBackground.textOffset.y] : [0, 0];
      speakerText.x = 5 * globalScale + speakerOffset.x + speakerTextOffset.x + speakerPadding;
      speakerText.y = speakerBoxTop + (dialogSpeakerSprite != null ? this.dialogSpeakerSprite.height : 0) - speakerText.height - 4 * globalScale + speakerTextOffset.y;
      speakerText.width = speakerText._sprite.width;
      if (options.prop('speakerBackground.image') != null) {
        var speakerBitmapData:BitmapData = BitmapDataUtils.loadFromObject(options.speakerBackground);
        dialogSpeakerSprite._sprite.loadGraphic(BitmapDataUtils.horizontalStretchCenter(speakerBitmapData,
                                            speakerPadding,
                                            Std.int(speakerText.width) + 2 * speakerPadding));
      }
      add(speakerText);

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
											    width - textX - textPadding.x,
											    nextTextStr));
			setTextFormat(text._sprite, options.textFormat);
			text.x = textX;
			text.y = textPadding.y + (Reflect.hasField(options, 'textOffset') ? options.textOffset[1] : 0);
			text._sprite.fieldWidth = width - textPadding.x - text.x;
			if (choiceBox != null) {
        choiceBox.setPositionFromDB(this);
			}
			add(text);
			if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
		} else if (this.advanceStyle == DialogAdvanceStyle.SCROLL) {
			advancing = true;
			if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = false;
			nextText = new LocalWrapper(new FlxText(0, 0,
												    width - (2 * textPadding.x),
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
			text = new LocalWrapper(new FlxText(textX, textPadding.y + (Reflect.hasField(options, 'textOffset') ? options.textOffset[1] : 0),
											    width - textX - textPadding.x,
											    nextTextStr));
			add(text);
			setTextFormat(text._sprite, options.textFormat);
			if (choiceBox != null) {
        choiceBox.setPositionFromDB(this);
			}
			
			DialogBox.typeOut(this.text._sprite, nextTextStr, advanceLength, {target: this, textFormat: options.textFormat}).call(function(sprite:FlxSprite) {
				advancing = false;
				if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
				if (choiceBox != null) {
					choiceBox.visible = true;
				}
			});
		}
	}
	
  /**
    * Advances the dialog box and re-renders the box with the new text,
    * applying animations if appropriate.
    */
	public function advanceAndRender(bypassText:Bool = false) {
		advanceUntilBlocked(true, bypassText);
		
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
	
	public function handleInput():Void {
		if (finished) return;

		var message:Dynamic = parseDialogNode();
    var advanceType:Int = 0;
    if (InputController.justPressed(Button.CONFIRM)) {
      advanceType = 1;
      InputController.consume(Button.CONFIRM);
    } else if (InputController.justPressed(Button.X)) {
      advanceType = 2;
      InputController.consume(Button.X);
    }

		if (this.mode == DialogBoxMode.NORMAL) {
			if (advanceType > 0 && canAdvance) {
				if (!advancing) {
					advanceAndRender(advanceType == 1 ? false : true);
				} else if (skip) {
					var advanceTransitions:Array<Actor> = Director.actorsWithTag(DIRECTOR_DIALOG_TRANSITION_STR);
					/*for (i in 0...advanceTransitions.length) {
						advanceTransitions[i].skipToEnd();
					}*/
				}
			}
			/*if (abort) {
				if (this.abortCallback != null && index == messages.length - 1) {
					this.abortCallback();
					this.destroy();
				}
			}*/
		} else if (this.mode == DialogBoxMode.SELECT_OPTION) {
      choiceBox.handleInput();
      var jumpToLabel:String = null;
      if (advanceType == 1) {
        jumpToLabel = choiceBox.selectOption();
      } else if (choiceBox.abortChoice != null && InputController.justPressed(Button.CANCEL)) {
        jumpToLabel = choiceBox.abortChoice;
        advanceType = 1;
        InputController.consume(Button.CANCEL);
      }
			if (jumpToLabel != null && !advancing) {
				if (labelMap.exists(jumpToLabel)) {
					pointer.sequence = labelMap.get(jumpToLabel).sequence;
					pointer.index = labelMap.get(jumpToLabel).index;
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
		canAdvance = !locked;
	}

    override public function _recomputeBounds():Void {
        super._recomputeBounds();

        width = this.bgSprite.width;
        height = this.bgSprite.height;
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
        nova.ui.text.TextFormatUtils.setTextFormat(text, format);
	}
}
