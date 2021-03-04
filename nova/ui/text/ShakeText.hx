package nova.ui.text;
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import nova.render.FlxLocalSprite;
import nova.ui.text.TextFormat.TextFormatUtils;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

/**
 * Text that shakes.
 */
class ShakeText extends RichText {
	public var originalX:Array<Float>;
	public var SHAKE_INTENSITY:Float = 2;

	public function new(text:String, ?textFormat:nova.ui.text.TextFormat = null) {
		super();

		var tempTextField:TextField = new TextField();
		if (textFormat != null) {
			TextFormatUtils.setTextFormat(tempTextField, textFormat);
		}
		tempTextField.text = text;
		
		originalX = new Array<Float>();
		
		for (i in 0...text.length) {
			var boundaries:Rectangle = tempTextField.getCharBoundaries(i);
            if (boundaries == null) continue;
			var wrapper:LocalWrapper<FlxText> = new LocalWrapper(new FlxText(0, 0, boundaries.width + 1, text.charAt(i), 24));
			wrapper.x = boundaries.x;
      wrapper._sprite.textField.width += 20;
			originalX.push(boundaries.x);
			if (textFormat != null) {
				TextFormatUtils.setTextFormat(wrapper._sprite, textFormat);
			}

			add(wrapper);
		}
	}
	
	override public function update(elapsed:Float) {
		for (i in 0...children.length) {
			var child:FlxLocalSprite = children[i];
			child.x = originalX[i] + Std.random(Std.int(2*SHAKE_INTENSITY + 1)) - SHAKE_INTENSITY;
			child.y = Std.random(Std.int(2 * SHAKE_INTENSITY + 1)) - SHAKE_INTENSITY;
		}
		
		super.update(elapsed);
	}
}
