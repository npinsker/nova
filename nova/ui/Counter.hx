package nova.ui;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import nova.input.InputController;
import nova.render.FlxLocalSprite;

import flixel.graphics.frames.FlxBitmapFont;

/**
 * A simple counter widget.
 */
class Counter extends FlxLocalSprite {
	public var value:Int = 1;
	public var maxValue:Int;
	public var callback:Int -> Void;
	
	public var _text:FlxBitmapText;
	
	public function new(callback:Int -> Void = null, maxValue:Int = 99) {
		super();
		this.callback = callback;
		this.maxValue = maxValue;
		
		_text = new FlxBitmapText(FlxBitmapFont.fromAngelCode('assets/images/digits.png',
			'assets/data/digits_xml.txt'));
		
		_text.text = Std.string(value);
		
		add(_text);
	}
	
	public function handleInput() {
		if (InputController.justPressed(Button.UP)) {
			if (value < this.maxValue) {
				value++;
				_text.text = Std.string(value);
			}
		} else if (InputController.justPressed(Button.DOWN)) {
			if (value > 1) {
				value--;
				_text.text = Std.string(value);
			}
		}
		
		if (InputController.justPressed(Button.CONFIRM)) {
			this.callback(value);
			
			this.destroy();
		}
	}
}
