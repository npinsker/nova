package nova.ui.text;
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import nova.render.FlxLocalSprite;
import openfl.geom.Rectangle;
import openfl.text.TextFormat;

/**
 * ...
 * @author Nathan Pinsker
 */
class WaveText extends RichText {
	public function new(text:String, ?font:String = null) {
		super();
		
		var tempTextField:TextField = new TextField();
		tempTextField.setTextFormat(new TextFormat((font != null ? font : FlxAssets.FONT_DEFAULT), 24, 0xFFFFFF));
		
		tempTextField.text = text;
		
		for (i in 0...text.length) {
			var boundaries:Rectangle = tempTextField.getCharBoundaries(i);
			var wrapper:LocalWrapper<FlxText> = new LocalWrapper(new FlxText(0, 0, boundaries.width + 1, text.charAt(i), 24));
			wrapper.x = boundaries.x;
			
			FlxTween.tween(wrapper, {y: -8}, 0.4,
						   {ease: FlxEase.expoInOut, type: 4, startDelay: 0.1 * i});
			add(wrapper);
		}
	}
}