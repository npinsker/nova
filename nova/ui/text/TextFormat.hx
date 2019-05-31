package nova.ui.text;

import flash.text.TextField;
import flixel.util.typeLimit.OneOfTwo;

import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * A concise representation of text field formatting parameters.
 */
typedef TextFormat = {
	@:optional var font:String;
	@:optional var size:Float;
	@:optional var color:Int;
};

class TextFormatUtils {
	public static function setTextFormat(text:OneOfTwo<FlxText, TextField>, format:TextFormat) {
		var DEFAULT_FONT_SIZE:Int = 12;
		var DEFAULT_COLOR:FlxColor = FlxColor.BLACK;
		
		var font:String = format.font;
		var size:Int = Std.int(format.size != null ? format.size : DEFAULT_FONT_SIZE);
		var color:FlxColor = (format.color != null ? FlxColor.fromInt(format.color) : DEFAULT_COLOR);
		
		if (Std.is(text, FlxText)) {
			cast(text, FlxText).setFormat(font, size, color);
		} else {
			var tfText:TextField = cast(text, TextField);

			var newFormat:openfl.text.TextFormat = new openfl.text.TextFormat();
			newFormat.font = font;
			newFormat.size = size;
			newFormat.color = color.to24Bit();
			tfText.defaultTextFormat = newFormat;
			tfText.setTextFormat(newFormat);
		}
	}
}
