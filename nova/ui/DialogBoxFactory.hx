package nova.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.Assets;
import openfl.display.BitmapData;

class DialogBoxFactory {
	public var options:Dynamic;
	
	public function new(options:Dynamic) {
		this.options = options;
	}
	
	public function create(messages:Array<Dynamic>, overrideOptions:Dynamic = null):DialogBox {
		var merged:Dynamic = {};
		if (overrideOptions != null) {
			for (field in Reflect.fields(overrideOptions)) {
				Reflect.setField(merged, field, Reflect.field(overrideOptions, field));
			}
		}
		for (field in Reflect.fields(options)) {
			if (!Reflect.hasField(merged, field)) {
				Reflect.setField(merged, field, Reflect.field(options, field));
			}
		}
		return new DialogBox(messages, merged);
	}
}