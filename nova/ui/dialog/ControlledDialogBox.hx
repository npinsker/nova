package nova.ui.dialog;

import openfl.display.BitmapData;

import flixel.FlxSprite;
import flixel.text.FlxText;
import nova.animation.Director;
import nova.render.FlxLocalSprite;
import nova.ui.dialog.DialogBox;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;

using nova.animation.Director;

/**
 * ...
 * @author Nathan Pinsker
 */
class ControlledDialogBox extends DialogBox {
	public var message:Dynamic;
	
	public function new(options:Dynamic) {
		super(null, options);
	}
	
	override public function handleInput():Void {
		trace("Warning: handleInput should not be called on a ControlledDialogBox!");
	}
	
	public function setText(text:Dynamic):Void {
		this.message = text;
		this.renderText(text);
	}
}