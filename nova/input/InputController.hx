package nova.input;

#if (desktop || web)
import flixel.FlxG;
#end

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
	private var _inputMap:Map<Button, Array<FlxKey>>;
	#end
	
	private function new() {
		_inputMap = new Map<Button, Array<FlxKey>>();
	}
	
	#if (desktop || web)
	public static function addKeyMapping(keyCode:FlxKey, button:Button) {
		if (!instance._inputMap.exists(button)) {
			instance._inputMap.set(button, new Array<FlxKey>());
		}
		instance._inputMap.get(button).push(keyCode);
	}
	#end
	
	public static function justPressed(button:Button) {
		#if (desktop || web)
		if (instance._inputMap.exists(button)) {
			if (FlxG.keys.anyJustPressed(instance._inputMap.get(button))) {
				return true;
			}
		}
		#end

		return false;
	}
	
	public static function pressed(button:Button) {
		#if (desktop || web)
		if (instance._inputMap.exists(button)) {
			if (FlxG.keys.anyPressed(instance._inputMap.get(button))) {
				return true;
			}
		}
		#end

		return false;
	}
	
	public static function justReleased(button:Button) {
		#if (desktop || web)
		if (instance._inputMap.exists(button)) {
			if (FlxG.keys.anyJustReleased(instance._inputMap.get(button))) {
				return true;
			}
		}
		#end

		return false;
	}
}