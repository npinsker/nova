package nova.ui.dialog;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import nova.ui.dialog.DialogNodeSequence;
import nova.utils.StructureUtils;
import openfl.Assets;
import openfl.display.BitmapData;

class DialogBoxFactory {
	public var options:Dynamic;
	
	public function new(options:Dynamic) {
		this.options = options;
	}
	
	public function create(messages:OneOfTwo<DialogNodeSequence, Array<String>>, overrideOptions:Dynamic = null):DialogBox {
		var merged:Dynamic = StructureUtils.merge(options, overrideOptions);
		if (Std.is(messages, Array)) {
			messages = DialogParser.parseLines(messages);
		}
		return new DialogBox(messages, merged);
	}
}