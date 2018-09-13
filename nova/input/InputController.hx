package nova.input;

import flixel.input.keyboard.FlxKey;

/**
 * ...
 * @author Nathan Pinsker
 */

enum Button {
	CONFIRM;
	CANCEL;
	
	LEFT;
	RIGHT;
	UP;
	DOWN;
	
	START;
	SELECT;
	
	X;
	Y;
	Z;
	LB;
	LT;
	RB;
	RT;
	
	D_LEFT;
	D_RIGHT;
	D_UP;
	D_DOWN;
	
	LEFT_CLICK;
	RIGHT_CLICK;
}

class InputController {
	public static var instance(default, null):InputController = new InputController();
	
	#if (desktop || web)
	private var _inputMap:Map<Button, 
	
	public static var addKeyMapping(keyCode:FlxKey, button:Button) {
		
	}
	
	#end

	private function new() {
		
	}
}