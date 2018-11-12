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
class ShakeText extends RichText {
	public var originalX:Array<Float>;
	public var SHAKE_INTENSITY:Float = 2;

	public function new(text:String, ?font:String = null) {
		super();
		
		var tempTextField:TextField = new TextField();
		tempTextField.setTextFormat(new TextFormat((font != null ? font : FlxAssets.FONT_DEFAULT), 24, 0xFFFFFF));
		
		tempTextField.text = text;
		originalX = new Array<Float>();
		
		for (i in 0...text.length) {
			var boundaries:Rectangle = tempTextField.getCharBoundaries(i);
			var wrapper:LocalWrapper<FlxText> = new LocalWrapper(new FlxText(0, 0, boundaries.width + 1, text.charAt(i), 24));
			wrapper.x = boundaries.x;
			originalX.push(boundaries.x);

			add(wrapper);
		}
	}
	
	override public function update(elapsed:Float) {
		for (i in 0...children.length) {
			var child:FlxLocalSprite = children[i];
			child.x = originalX[i] + Std.random(Std.int(2*SHAKE_INTENSITY + 1)) - SHAKE_INTENSITY;
			child.y = Std.random(Std.int(2*SHAKE_INTENSITY + 1)) - SHAKE_INTENSITY;
		}
		
		super.update(elapsed);
	}
}