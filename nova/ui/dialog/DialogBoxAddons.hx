package nova.ui.dialog;

import nova.render.FlxLocalSprite;
import nova.ui.text.ShakeText;
import nova.ui.text.WaveText;

import nova.ui.dialog.DialogBox.DialogBoxFlag;


typedef TextWithFlags = {
	var text:String;
  var flags:Array<DialogBoxFlag>;
}

/**
 * Common utilities useful for creating rich dialog boxes.
 */
class DialogBoxAddons {
  /**
    * Converts variables surrounded by the code string to the stored values
    * of those variables in the dialog box.
    *
    * For example, if the dialog box has the variable 'health' set to 3,
    * then this method converts 'I have %health% health' to 'I have 3 health'
    * (assuming 'code' is set to '%').
    */
	public static function parseVariableCodes(code:String) {
		var codeMatch:String = code + '([a-z]+)?' + code;
		return function(db:DialogBox, text:String):String {
			return new EReg(codeMatch, 'ig').map(text, function(e:EReg) {
				var s:String = e.matched(1);
				
				if (db.variables.exists(s)) {
					return db.variables.get(s);
				} else if (db.globalVariables.exists(s)) {
					return db.globalVariables.get(s);
				}
				trace("Warning: unknown variable " + s);
				return codeMatch;
			});
		}
	}
	
	public static var parsePercentVariables:DialogBox -> String -> String = parseVariableCodes('%');
	
	public static function toWaveText(text:String) {
		return new WaveText(text);
	}
	
	public static function parseTextFlags(text:String):TextWithFlags {
    var transformedText:String = '';
		var inFlag:Bool = false;
		var anchor:Int = 0;
    var anchorPosition:Int = 0;
    var flags:Array<DialogBoxFlag> = [];
		for (i in 0...text.length) {
			if (!inFlag) {
				if (text.charAt(i) == '[') {
					inFlag = true;
					anchor = i + 1;
          anchorPosition = transformedText.length;
				} else {
					transformedText += text.charAt(i);
				}
			} else {
				if (text.charAt(i) == ']') {
          flags.push({name: text.substring(anchor, i), position: anchorPosition});
          inFlag = false;
				}
			}
		}
		return {text: transformedText, flags: flags};
	}
	
	public static var parseCommonTextFlags:DialogBox -> String -> String = function(db:DialogBox, text:String) {
    var parsedFlags = parseTextFlags(text);
    db.flags = parsedFlags.flags;
    var newColors:Map<String, Int> = [
      'red' => 0xFFFF0000,
      'green' => 0xFF00CC00,
      'blue' => 0xFF0000CC,
      'black' => 0xFF000000,
      'white' => 0xFFFFFFFF,
      'orange' => 0xFFFFA500,
      'yellow' => 0xFFFFFF00,
      'pink' => 0xFFFFC0CB,
      'brown' => 0xFF8B4513,
    ];
    for (color in newColors.keys()) {
        if (!db.colors.exists(color)) {
            db.colors.set(color, newColors.get(color));
        }
    }
    db.creationClasses = [
      'wave' => WaveText,
      'shake' => ShakeText,
    ];
    return parsedFlags.text;
	};
}
