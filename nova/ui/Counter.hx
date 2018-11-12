package nova.ui;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import nova.input.InputController;
import nova.render.FlxLocalSprite;

import flixel.graphics.frames.FlxBitmapFont;

/**
 * ...
 * @author Nathan Pinsker
 */
class Counter extends FlxLocalSprite {
	public var setting:Int = 10;
	public var callback:Int -> Void;
	
	public var _text:FlxBitmapText;
	
	public function new(callback:Int -> Void = null) {
		super();
		this.callback = callback;
		
		_text = new FlxBitmapText(FlxBitmapFont.fromMonospace('assets/images/digits.png', '0123456789', new FlxPoint(30, 40)));
		
		_text.text = Std.string(setting);
		
		add(_text);
	}
	
	public function handleInput() {
		if (InputController.justPressed(Button.UP)) {
			if (setting < 99) {
				setting++;
				_text.text = Std.string(setting);
			}
		} else if (InputController.justPressed(Button.DOWN)) {
			if (setting > 0) {
				setting--;
				_text.text = Std.string(setting);
			}
		}
		
		if (InputController.justPressed(Button.CONFIRM)) {
			this.callback(setting);
			
			this.destroy();
		}
	}
}