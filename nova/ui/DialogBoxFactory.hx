package nova.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import nova.utils.StructureUtils;
import openfl.Assets;
import openfl.display.BitmapData;

class DialogBoxFactory {
	public var options:Dynamic;
	
	public function new(options:Dynamic) {
		this.options = options;
	}
	
	public function create(messages:Array<Dynamic>, overrideOptions:Dynamic = null):DialogBox {
		var merged:Dynamic = StructureUtils.merge(options, overrideOptions);
		return new DialogBox(messages, merged);
	}
}