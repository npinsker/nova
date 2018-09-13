package nova.ui;

using nova.animation.Director;

import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import openfl.Assets;
import openfl.display.BitmapData;

enum DialogBoxType {
	TEXT_ONLY;  // Successive dialog boxes of text only.
	            // Format data as an Array<String>.
	TEXT_PLUS_METADATA;  // Dialog boxes contain text, as well as optional 'speaker'
	                     // and 'image' attributes. Format data as an Array<Dynamic>.
	RICH;  // Rich text box. Currently unsupported.
}

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

class DialogBox extends FlxSpriteGroup {
	public static inline var DEFAULT_TEXT_PADDING_X:Int = 6;
	public static inline var DEFAULT_TEXT_PADDING_Y:Int = 5;
	public static inline var DIRECTOR_DIALOG_TRANSITION_STR:String = '__dialogTransition';
	
	public var abort:Bool = false;  // Whether the user can leave the dialog at any point.
	public var skip:Bool = true;  // Whether the user can press the 'Advance' key to display all text in the pane.
	
	public var align:DialogBoxAlign = DialogBoxAlign.LEFT;
	public var position:DialogBoxPosition = DialogBoxPosition.BOTTOM;
	public var advanceStyle:DialogAdvanceStyle = DialogAdvanceStyle.NONE;
	public var advanceLength:Int = 8;
	public var advancing:Bool = false;
	public var advanceSound:String = null;
	public var advanceIndicatorInfo:Dynamic;
	public var advanceIndicatorSprite:FlxSprite;
	public var advanceIndicatorTween:FlxTween;
	
	public var backgroundPadding:Pair<Int> = [0, 0];
	public var textPadding:Pair<Int> = [DEFAULT_TEXT_PADDING_X, DEFAULT_TEXT_PADDING_Y];
	
	public var fontAssetPath:String = null;
	public var fontSize:Float = 4.5;
	public var fontColor:FlxColor = FlxColor.BLACK;
	
	public var bgSprite:FlxSprite = null;
	public var text:FlxText;
	public var nextText:FlxText;
	public var copiedText:FlxSprite;
	public var messages:Array<Dynamic>;
	public var index:Int = 0;
	public var bottomImageStore:FlxSprite;
	public var globalScale:Int = 1;
	
	public var currentSpeaker:String = "";
	public var dialogSpeakerSprite:FlxSprite = null;
	public var speakerText:FlxText = null;
	
	public var callback:Void -> Void = null;
	public var abortCallback:Void -> Void = null;
	
	public var options:Dynamic;
	public var optionsTween:FlxTween;
	
	public var dialogBoxTop:Float;
	public var speakerBoxTop:Float;
	
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
	
	public function new(messages:Array<Dynamic>, options:Dynamic) {
		super();
		
		this.messages = messages;
		for (i in 0...this.messages.length) {
			if (Std.is(this.messages[i], String)) {
				this.messages[i] = StringTools.trim(this.messages[i]);
			}
		}
		
		if (Reflect.hasField(options, 'scale')) {
			Reflect.setField(this, 'globalScale', Reflect.field(options, 'scale'));
		}
		
		for (supportedField in ['abort', 'align', 'skip', 'advanceStyle', 'advanceLength',
		                        'advanceSound', 'callback', 'abortCallback', 'fontSize']) {
			if (Reflect.hasField(options, supportedField)) {
				Reflect.setField(this, supportedField, Reflect.field(options, supportedField));
			}
		}
		
		fontSize *= globalScale;
		textPadding *= globalScale;
		
		if (Reflect.hasField(options, 'background')) {
			bgSprite = new FlxSprite();
			var bitmapData:BitmapData = BitmapDataUtils.loadFromObject(options.background);
			bgSprite.loadGraphic(bitmapData);
			this.add(bgSprite);
			dialogBoxTop = FlxG.height - bgSprite.height;
			bgSprite.y = dialogBoxTop;
		}
		
		if (Reflect.hasField(options, 'speakerBackground')) {
			dialogSpeakerSprite = new FlxSprite();
			var bitmapData:BitmapData = BitmapDataUtils.loadFromObject(options.speakerBackground);
			dialogSpeakerSprite.loadGraphic(bitmapData);
			this.add(dialogSpeakerSprite);
			var offset:Pair<Int> = [0, 0];
			if (Reflect.hasField(options.speakerBackground, 'offset')) {
				offset = [Std.int(options.speakerBackground.offset.x * globalScale), Std.int(options.speakerBackground.offset.y * globalScale)];
			}
			speakerBoxTop = dialogBoxTop - dialogSpeakerSprite.height + offset.y;
			dialogSpeakerSprite.y = speakerBoxTop;
			dialogSpeakerSprite.x = (10 * globalScale) + offset.x;
			dialogSpeakerSprite.visible = false;
		}
		
		if (Reflect.hasField(options, 'advanceIndicator')) {
			advanceIndicatorSprite = new FlxSprite();
			
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
			advanceIndicatorSprite.loadGraphic(advanceIndicatorInfo.image, true,
											   (Reflect.hasField(advanceIndicator, 'width') ? advanceIndicator.width : advanceIndicator.image.width),
											   (Reflect.hasField(advanceIndicator, 'height') ? advanceIndicator.height : advanceIndicator.image.height));

			advanceIndicatorSprite.animation.add('next', advanceIndicatorInfo.nextFrames, 5);
			advanceIndicatorSprite.animation.add('finish', advanceIndicatorInfo.finishFrames, 5);
			advanceIndicatorSprite.animation.play('next');
			advanceIndicatorSprite.x = FlxG.width - advanceIndicatorSprite.width - textPadding.x;
			advanceIndicatorSprite.y = FlxG.height - advanceIndicatorSprite.height - textPadding.y;
			
			if (advanceIndicator.animation != null) {
				advanceIndicator.animation.x += advanceIndicatorSprite.x;
				advanceIndicator.animation.y += advanceIndicatorSprite.y;
				advanceIndicatorTween = FlxTween.tween(advanceIndicatorSprite, advanceIndicator.animation, 0.3,
													   {ease: FlxEase.expoInOut, type: FlxTween.PINGPONG});
			}
			
			this.add(advanceIndicatorSprite);
		}
		
		text = new FlxText(textPadding.x,
		                   dialogBoxTop + textPadding.y,
		                   bgSprite.width - (2 * textPadding.x),
						   messages[0]);
		text.setFormat(this.fontAssetPath, Std.int(this.fontSize), this.fontColor);
		this.add(text);
	}
	
	public function handleInput() {
		var advance:Bool = false;
		var abort:Bool = false;
		#if (desktop || web)
		advance = advance || FlxG.keys.anyJustPressed([Z, ENTER, SPACE]);
		abort = advance || FlxG.keys.anyJustPressed([LEFT, RIGHT, UP, DOWN, A, S, D, W]);
		#end
		#if mobile
		advance = advance || (FlxG.swipes.length > 0);
		#end
		if (advance) {
			if (!advancing) {
				if (index < messages.length - 1) {
					index += 1;
					var nextTextStr:String;
					var nextSpeaker:String = "";
					
					if (speakerText != null) {
						speakerText.destroy();
					}

					if (Std.is(messages[index], String)) {
						nextTextStr = messages[index];
					} else {
						nextTextStr = messages[index].text;
						nextSpeaker = messages[index].speaker;
					}
					if (nextSpeaker != currentSpeaker && dialogSpeakerSprite != null) {
						//remove
					}
					
					if (nextSpeaker != "") {
						dialogSpeakerSprite.visible = true;
						speakerText = new FlxText(10 * globalScale + offset.x, speakerBoxTop + this.dialogSpeakerSprite.height - this.fontSize - 4 * globalScale,
						                          dialogSpeakerSprite.width, nextSpeaker);
						speakerText.alignment = FlxTextAlign.CENTER;
						speakerText.setFormat(this.fontAssetPath, Std.int(this.fontSize), this.fontColor);
						add(speakerText);
					} else {
						dialogSpeakerSprite.visible = false;
					}
					
					if (advanceSound != null) {
						FlxG.sound.load(advanceSound).play();
					}
					
					if (this.advanceStyle == DialogAdvanceStyle.NONE) {
						text.destroy();
						text = new FlxText(textPadding.x,
										   dialogBoxTop + textPadding.y,
										   bgSprite.width - (2 * textPadding.x),
										   nextTextStr);
						text.setFormat(this.fontAssetPath, Std.int(this.fontSize), this.fontColor);
						this.add(text);
					} else if (this.advanceStyle == DialogAdvanceStyle.SCROLL) {
						advancing = true;
						advanceIndicatorSprite.visible = false;
						nextText = new FlxText(textPadding.x,
											   dialogBoxTop + textPadding.y + bgSprite.height,
											   bgSprite.width - (2 * textPadding.x),
											   nextTextStr);
						nextText.setFormat(this.fontAssetPath, Std.int(this.fontSize), this.fontColor);
						nextText.draw();
						bottomImageStore = new FlxSprite();
						bottomImageStore.pixels = nextText.pixels.clone();
						add(nextText);
						Director.afterAll(null,
							[text.moveBy([0, -Std.int(bgSprite.height)], advanceLength, DIRECTOR_DIALOG_TRANSITION_STR),
							 nextText.moveBy([0, -Std.int(bgSprite.height)], advanceLength, DIRECTOR_DIALOG_TRANSITION_STR)]).call(function(sprite:FlxSprite) {
								this.remove(text);
								text.destroy();
								text = nextText;
								advancing = false;
								advanceIndicatorSprite.visible = true;
							});
					} else if (this.advanceStyle == DialogAdvanceStyle.TYPEWRITER) {
						advancing = true;
						advanceIndicatorSprite.visible = false;
						DialogBox.typeOut(this.text, nextTextStr, advanceLength).call(function(sprite:FlxSprite) {
							advancing = false;
							advanceIndicatorSprite.visible = true;
						});
					}
					if (index == messages.length - 1) {
						advanceIndicatorTween.cancel();
						advanceIndicatorSprite.animation.play("finish");
						advanceIndicatorSprite.x = FlxG.width - advanceIndicatorSprite.width - textPadding.x;
						advanceIndicatorSprite.y = FlxG.height - advanceIndicatorSprite.height - textPadding.y;
					}
				} else {
					if (this.callback != null) {
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
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		Director.update();
		
		if (advancing && this.advanceStyle == DialogAdvanceStyle.SCROLL) {
			var top:Float = FlxG.height - bgSprite.height + textPadding.y;
			var bottom:Float = FlxG.height - textPadding.y;
			if (this.text.y < top) {
				var transparentRect:BitmapData = new BitmapData(Std.int(this.text.width), Std.int(top - this.text.y), true, 0);
				this.text.pixels.copyPixels(transparentRect, transparentRect.rect, new Point(0, 0));
			}
			if (this.nextText.y + this.nextText.height > bottom) {
				var transparentRect:BitmapData = new BitmapData(Std.int(this.nextText.width), Std.int(this.nextText.y + this.nextText.height - bottom), true, 0);
				this.nextText.pixels = bottomImageStore.pixels.clone();
				this.nextText.pixels.copyPixels(transparentRect, transparentRect.rect, new Point(0, this.nextText.height - transparentRect.height));
			} else if (bottomImageStore != null) {
				this.nextText.pixels = bottomImageStore.pixels.clone();
				this.bottomImageStore = null;
			}
		}
		handleInput();
	}
}