package nova.ui.dialog;

using nova.animation.Director;

import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo;
import nova.render.FlxLocalSprite;
import nova.ui.dialog.DialogNodeSequence;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import nova.input.InputController;
import openfl.Assets;
import openfl.display.BitmapData;

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

class DialogBox extends FlxLocalSprite {
	public static inline var DEFAULT_TEXT_PADDING_X:Int = 6;
	public static inline var DEFAULT_TEXT_PADDING_Y:Int = 5;
	public static inline var DIRECTOR_DIALOG_TRANSITION_STR:String = '__dialogTransition';
	
	public static inline var DEFAULT_FONT_SIZE:Float = 4.5;
	
	public var abort:Bool = false;  // Whether the user can leave the dialog at any point.
	public var skip:Bool = true;  // Whether the user can press the 'Advance' key to display all text in the pane.
	public var destroyed:Bool = false;
	
	public var labelMap:Map<String, Int>;
	
	public var align:DialogBoxAlign = DialogBoxAlign.LEFT;
	public var position:DialogBoxPosition = DialogBoxPosition.BOTTOM;
	public var advanceStyle:DialogAdvanceStyle = DialogAdvanceStyle.NONE;
	public var advanceLength:Int = 8;
	public var advancing:Bool = false;
	public var advanceSound:String = null;
	public var advanceIndicatorInfo:Dynamic;
	public var advanceIndicatorSprite:LocalSpriteWrapper = null;
	public var advanceIndicatorTween:FlxTween;
	public var mode = DialogBoxMode.NORMAL;
	
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
	public var copiedText:FlxSprite;
	public var messages:DialogNodeSequence;
	public var bottomImageStore:FlxSprite;
	public var globalScale:Int = 1;
	
	public var currentSpeaker:String = "";
	public var dialogSpeakerSprite:LocalSpriteWrapper = null;
	public var speakerText:LocalWrapper<FlxText> = null;
	public var speakerBackground:FlxLocalSprite = null;
	public var speakerPadding:Int = 6;
	public var speakerImage:FlxLocalSprite = null;
	public var speakerOffset:Pair<Int> = [0, 0];
	public var textOffset:Pair<Int> = [0, 0];
	
	public var callback:Void -> Void = null;
	public var boxCallback:Void -> Void = null;
	public var advanceCallback:String -> Void = null;
	public var boxCallbackStr:String = null;
	public var canAdvance:Bool = false;
	
	public var options:Dynamic;
	public var optionsTween:FlxTween;
	public var selectOptionSprite:BitmapData = null;
	public var optionsOffset:Pair<Int> = [0, 0];

	public var speakerBoxTop:Float;
	
	public var variables:Map<String, Dynamic>;
	public var pointer:DialogSequencePointer;
	public var labels:Map<String, Int>;
	
	private static function _typeOutAction(text:String, frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { object.text = text; cast(sprite, FlxText).text = ""; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  var substringLength:Int = Std.int(object.text.length * frame / frames);
							  cast(sprite, FlxText).text = object.text.substring(0, substringLength);
						  },
						  frames);
	}
	
	public static function typeOut(sprite:OneOfTwo<FlxText, Actor>, text:String, frames:Int):Actor {
		return Director.directorChainableFn(_typeOutAction(text, frames), cast(sprite, FlxSprite), frames, DIRECTOR_DIALOG_TRANSITION_STR);
	}
	
	public function new(messages:DialogNodeSequence, options:Dynamic) {
		super();
		
		this.messages = messages;
		this.options = options;
		this.pointer = new DialogSequencePointer(messages, 0);
		
		this.labels = new Map<String, Int>();
		this.variables = new Map<String, Dynamic>();
		this.labelMap = new Map<String, Int>();
		
		for (i in 0...this.messages.length) {
			var node:DialogSyntaxNode = this.messages.sequence[i];
			if (node.type == LABEL) {
				this.labelMap.set(node.value, i);
			}
		}
		
		if (Reflect.hasField(options, 'scale')) {
			Reflect.setField(this, 'globalScale', Reflect.field(options, 'scale'));
		}
		
		for (supportedField in ['abort', 'align', 'skip', 'advanceStyle', 'advanceLength',
		                        'advanceSound', 'callback', 'abortCallback', 'advanceCallback',
								'selectOptionSprite']) {
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
		// TODO: replace this with a way to consume inputs from InputController
		new FlxTimer().start(0.2, function(f:FlxTimer) { canAdvance = true; });
		
		text = new LocalWrapper<FlxText>(new FlxText());
		var holdStyle = this.advanceStyle;
		this.advanceStyle = DialogAdvanceStyle.NONE;
		if (pointer.get().type != TEXT && pointer.get().type != CHOICE_BOX) {
			advanceUntilBlocked();
		}
		renderText();
		
		this.advanceStyle = holdStyle;
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
					build.merge(child.value);
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
				var exp:ExpressionNode = s.value.evaluate(variables);
				if (exp.type == INTEGER && exp.value > 0) {
					scrapeChoices(s.child, choices);
				}
			}
		}
	}
	
	public function advanceUntilBlocked() {
		while (true) {
			pointer.step();
			var node:DialogSyntaxNode = pointer.get();
			if (node == null || node.type == TEXT || node.type == CHOICE_BOX) {
				return;
			} else if (node.type == JUMP) {
				var label:String = node.value;
				if (labelMap.exists(label)) {
					pointer.sequence = messages;
					pointer.index = labelMap.get(label);
				} else {
					trace("Label " + label + " doesn't exist!");
				}
			} else if (node.type == IF) {
				var exp:ExpressionNode = node.value.evaluate(variables);
				if (exp.type == INTEGER && exp.value > 0) {
					pointer.sequence = node.child;
					pointer.index = -1;
				}
			} else if (node.type == VARIABLE_ASSIGN) {
				variables.set(node.value.name, node.value.value);
			}
		}
	}
	
	public function renderText() {
		var nextTextStr:String;
		var nextSpeaker:String = "";
		var message:Dynamic = parseDialogNode();

		if (speakerText != null) {
			remove(speakerText);
			speakerText.destroy();
		}

		if (Std.is(message, String)) {
			nextTextStr = message;
		} else {
			if (Reflect.hasField(message, 'text')) {
				nextTextStr = message.text;
			} else {
				nextTextStr = '';
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
				var choiceTextStr = this.choices.join('\n');
				var choiceText:FlxText = new FlxText(0, 0, 0, choiceTextStr);
				setTextFormat(choiceText, StructureUtils.merge(options.optionsTextFormat, {size: 3.5}));
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
			}
		}
		if (nextSpeaker != currentSpeaker && dialogSpeakerSprite != null) {
			//remove
		}
		
		var textX:Int = textPadding.x;
		if (nextSpeaker != "") {
			dialogSpeakerSprite.visible = true;
			speakerText = new LocalWrapper<FlxText>(new FlxText(0, 0, 0, nextSpeaker));
			setTextFormat(speakerText._sprite, options.textFormat);
			speakerText.x = 5 * globalScale + speakerOffset.x + textOffset.x + speakerPadding;
			speakerText.y = speakerBoxTop + this.dialogSpeakerSprite.height - speakerText.height - 4 * globalScale + textOffset.y;
			speakerText.width = speakerText._sprite.width;
			var speakerBitmapData:BitmapData = BitmapDataUtils.loadFromObject(speakerBackground);
			dialogSpeakerSprite._sprite.loadGraphic(BitmapDataUtils.horizontalStretchCenter(speakerBitmapData,
			                                                                        speakerPadding,
			                                                                        Std.int(speakerText.width) + 2 * speakerPadding));
			add(speakerText);
			
			if (speakerImage != null) {
				remove(speakerImage);
				speakerImage = null;
			}
			var imageSrc = this.options.prop('defaultBindings.speakerImages.' + nextSpeaker);
			if (Reflect.hasField(message, 'image')) {
				imageSrc = message.image;
			}
			if (imageSrc != null) {
				speakerImage = new LocalSpriteWrapper(new FlxSprite(Assets.getBitmapData(imageSrc)));
				add(speakerImage);
				speakerImage.y = (bgSprite.height - speakerImage.height) / 2;
				speakerImage.x = textPadding.x;
				textX += textPadding.x + Std.int(speakerImage.width);
			}
		} else {
			dialogSpeakerSprite.visible = false;
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
			text.y = textPadding.y;
			if (choiceSprite != null) {
				choiceSprite.x = text.x + globalScale * optionsOffset.x;
				choiceSprite.y = text.y + text._sprite.textField.getLineMetrics(0).height + 5 + globalScale * optionsOffset.y;
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
				[text.moveBy([0, -Std.int(bgSprite.height)], advanceLength, DIRECTOR_DIALOG_TRANSITION_STR),
				 nextText.moveBy([0, -Std.int(bgSprite.height)], advanceLength, DIRECTOR_DIALOG_TRANSITION_STR)]).call(function(sprite:FlxSprite) {
					this.remove(text);
					text.destroy();
					text = nextText;
					advancing = false;
					if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
				});
		} else if (this.advanceStyle == DialogAdvanceStyle.TYPEWRITER) {
			advancing = true;
			if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = false;
			DialogBox.typeOut(this.text._sprite, nextTextStr, advanceLength).call(function(sprite:FlxSprite) {
				advancing = false;
				if (advanceIndicatorSprite != null) advanceIndicatorSprite.visible = true;
			});
		}
		/*if (index == messages.length - 1) {
			advanceIndicatorTween.cancel();
			if (advanceIndicatorSprite != null) {
				if (advanceIndicatorSprite.animation.getByName('finish') != null) {
					advanceIndicatorSprite.animation.play("finish");
				}
				advanceIndicatorSprite.x = width - advanceIndicatorSprite.width - textPadding.x;
				advanceIndicatorSprite.y = height - advanceIndicatorSprite.height - textPadding.y;
			}
		}*/
	}
	
	public function redrawOptions() {
		choiceIndicator.x = choiceSprite.x - choiceIndicator.width - 5;
		choiceIndicator.y = choiceSprite.y + (-0.5 + choiceIndex) * choiceSprite._sprite.textField.getLineMetrics(0).height;
	}
	
	public function handleInput() {
		var message:Dynamic = parseDialogNode();
		if (this.mode == DialogBoxMode.NORMAL) {
			var advance:Bool = InputController.justPressed(Button.CONFIRM);
			if (advance && canAdvance && this.visible) {
				if (!advancing) {
					advanceUntilBlocked();
					
					if (pointer.get() != null) {
						renderText();
					} else {
						if (boxCallbackStr != null) {
							if (advanceCallback == null) {
								trace("Error: can't include a `callbackStr` on a dialog box if no `advanceCallback` is provided!");
							} else {
								advanceCallback(boxCallbackStr);
							}
						}
						
						if (this.callback != null && boxCallbackStr == null) {
							this.callback();
						}
						this.destroy();
					}
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
			} else if (InputController.justPressed(Button.CONFIRM)) {
				var jumpToLabel = message.choices[choiceIndex][1];
				
				if (labelMap.exists(jumpToLabel)) {
					pointer.sequence = messages;
					pointer.index = labelMap.get(jumpToLabel);
					
					advanceUntilBlocked();
					renderText();
				} else if (jumpToLabel == 'end') {
					if (boxCallbackStr != null) {
						if (advanceCallback == null) {
							trace("Error: can't include a `callbackStr` on a dialog box if no `advanceCallback` is provided!");
						} else {
							advanceCallback(boxCallbackStr);
						}
					} else if (Reflect.hasField(options, 'advanceCallbackAlways') && options.advanceCallbackAlways) {
						advanceCallback(null);
					}
					if (this.callback != null && boxCallbackStr == null) {
						this.callback();
					}
					this.destroy();
				} else {
					trace("No label " + jumpToLabel + " found!");
					advanceUntilBlocked();
					renderText();
				}
			}
		}
	}
	
	public function setLocked(locked:Bool):Void {
		canAdvance = locked;
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		Director.update();
		
		handleInput();
		
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
	
	override public function destroy():Void {
		destroyed = true;
		super.destroy();
	}
	
	function setTextFormat(text:FlxText, format:Dynamic) {
		var font:String = (Reflect.hasField(format, 'font') ? format.font : null);
		var size:Int = Std.int(Reflect.hasField(format, 'size') ? format.size * globalScale : DEFAULT_FONT_SIZE * globalScale);
		var color:FlxColor = (Reflect.hasField(format, 'color') ? format.color : FlxColor.BLACK);

		text.setFormat(font, size, color);
	}
}