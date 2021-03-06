package nova.ui.text;
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import nova.render.FlxLocalSprite;
import nova.ui.dialog.DialogBox;
import nova.ui.text.TextFormat.TextFormatUtils;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

/**
 * Text that undulates up and down.
 */
class WaveText extends RichText {
	public function new(text:String, ?textFormat:nova.ui.text.TextFormat = null) {
		super();
		
		var tempTextField:TextField = new TextField();
		if (textFormat != null) {
			TextFormatUtils.setTextFormat(tempTextField, textFormat);
		}
		tempTextField.text = text;
		
		for (i in 0...text.length) {
			var boundaries:Rectangle = tempTextField.getCharBoundaries(i);
            if (boundaries == null) continue;
			var wrapper:LocalWrapper<FlxText> = new LocalWrapper(new FlxText(0, 0, boundaries.width + 1, text.charAt(i), 24));
			wrapper.x = boundaries.x;
      wrapper._sprite.textField.width += 20;
			if (textFormat != null) {
				TextFormatUtils.setTextFormat(wrapper._sprite, textFormat);
			}
			
			FlxTween.tween(wrapper, {y: -12}, 0.3,
						   {ease: FlxEase.sineInOut, type: 4, startDelay: 2.6 * i});
			add(wrapper);
		}
	}
}
