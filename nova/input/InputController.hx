package nova.input;

import flixel.FlxG;
import flixel.input.FlxSwipe;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

import nova.input.NovaSwipe;

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

/**
  * Collates input from different sources and maps them to virtual 'buttons',
  * whose status can then be checked. Works with keyboard, a single gamepad,
  * and `SimpleSwipe` gestures. Can also 'consume' a button press so it is no
  * longer detected.
  *
  * This class will be extended to support multiple gamepads someday hopefully?
  *
  * Example usage:

  * ```
  * InputController.addKeyMapping(ENTER, Button.CONFIRM);
  * InputController.addGamepadMapping(A, Button.CONFIRM);
  * [...]
  * if (InputController.justPressed(CONFIRM)) {
  *   [...]
  * }
  * ```
  *
  * In the case of swipes, since the type of swipe can only be identified at the point of release,
  * `justPressed` and `justReleased` will both evaluate to true only when the swipe is
  * released and `pressed` will never be true due to a swipe action.
  */
class InputController {
	public static var instance(default, null):InputController = new InputController();
	
	#if (desktop || web)
	private var _keyboardInputMap:Map<Button, Array<FlxKey>>;
  private var _gamepadInputMap = new Map<Button, Array<FlxGamepadInputID>>();
	#end

  #if mobile
  private var _simpleSwipeInputMap = new Map<Button, Array<SimpleSwipe>>();
  #end

  private var _disabled:Array<Button>;
  private var _simulatedPresses:Array<Button>;
	
	private function new() {
    #if (desktop || web)
		_keyboardInputMap = new Map<Button, Array<FlxKey>>();
    _gamepadInputMap = new Map<Button, Array<FlxGamepadInputID>>();
    #end

    #if mobile
    _simpleSwipeInputMap = new Map<Button, Array<SimpleSwipe>();
    #end

    _disabled = [];
    _simulatedPresses = [];
	}
	
	public static function addKeyMapping(keyCode:FlxKey, button:Button) {
    #if (desktop || web)
		if (!instance._keyboardInputMap.exists(button)) {
			instance._keyboardInputMap.set(button, new Array<FlxKey>());
		}
		instance._keyboardInputMap.get(button).push(keyCode);
    #end
	}

  public static function addGamepadMapping(padCode:FlxGamepadInputID, button:Button) {
    #if (desktop || web)
		if (!instance._gamepadInputMap.exists(button)) {
			instance._gamepadInputMap.set(button, new Array<FlxGamepadInputID>());
		}
		instance._gamepadInputMap.get(button).push(padCode);
    #end
  }

  public static function addSimpleSwipeMapping(swipe:SimpleSwipe, button:Button) {
    #if mobile
    if (!instance._simpleSwipeInputMap.exists(button)) {
      instance._simpleSwipeInputMap.set(button, new Array<SimpleSwipe>());
    }
    instance._simpleSwipeInputMap.get(button).push(swipe);
    #end
  }
	
	public static function justPressed(button:Button) {
        if (instance._disabled.indexOf(button) != -1) {
          return false;
        }

        if (instance._simulatedPresses.indexOf(button) != -1) {
            return true;
        }

		#if (desktop || web)
		if (instance._keyboardInputMap.exists(button)) {
			if (FlxG.keys.anyJustPressed(instance._keyboardInputMap.get(button))) {
				return true;
			}
		}
		if (instance._gamepadInputMap.exists(button)) {
      for (candidate in instance._gamepadInputMap.get(button)) {
        if (FlxG.gamepads.anyJustPressed(candidate)) {
          return true;
        }
      }
		}
		#end

    #if mobile
    if (instance._simpleSwipeInputMap.exists(button)) {
      for (swipe in FlxG.swipes) {
        var simpleSwipe = NovaSwipe.toSimpleSwipe(swipe);
        if (instance._simpleSwipeInputMap.get(button).indexOf(simpleSwipe) != -1) {
          return true;
        }
      }
    }
    #end

		return false;
	}
	
	public static function pressed(button:Button) {
		#if (desktop || web)
		if (instance._keyboardInputMap.exists(button)) {
			if (FlxG.keys.anyPressed(instance._keyboardInputMap.get(button))) {
				return true;
			}
		}
		if (instance._gamepadInputMap.exists(button)) {
      for (candidate in instance._gamepadInputMap.get(button)) {
        if (FlxG.gamepads.anyPressed(candidate)) {
          return true;
        }
      }
		}
		#end

		return false;
	}
	
	public static function justReleased(button:Button) {
		#if (desktop || web)
		if (instance._keyboardInputMap.exists(button)) {
			if (FlxG.keys.anyJustReleased(instance._keyboardInputMap.get(button))) {
				return true;
			}
		}
		if (instance._gamepadInputMap.exists(button)) {
      for (candidate in instance._gamepadInputMap.get(button)) {
        if (FlxG.gamepads.anyJustReleased(candidate)) {
          return true;
        }
      }
		}
		#end

    #if mobile
    if (instance._simpleSwipeInputMap.exists(button)) {
      for (swipe in FlxG.swipes) {
        var simpleSwipe = NovaSwipe.toSimpleSwipe(swipe);
        if (instance._simpleSwipeInputMap.get(button).indexOf(simpleSwipe) != -1) {
          return true;
        }
      }
    }
    #end

		return false;
	}

  /**
    * Consumes a button press, so successive calls to 'justPressed' will return false.
    * Does not affect 'pressed' or 'justReleased' calls.
    *
    * Use this method with care! It's intended to be used in a setting where two components
    * are both listening for a button press on the same frame, but you want the one on 'top'
    * (i.e. the one that's processed first) to be the only one that receives the button. Thus,
    * the component can consume the press after reading it.
    *
    * In other words, this method can be used to implement a simple stack-based window manager.
    * It will be removed in future if there is ever window manager tooling added.
    */
  public static function consume(button:Button) {
    instance._disabled.push(button);
  }

  public static function simulatePress(button:Button) {
    instance._simulatedPresses.push(button);
  }

  public static function update() {
    instance._disabled = [];
    instance._simulatedPresses = [];
  }
}
