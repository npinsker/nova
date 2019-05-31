package nova.ui.dialog;
import nova.render.FlxLocalSprite;
import nova.ui.text.ShakeText;
import nova.ui.text.WaveText;

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
	
	public static function parseTextFlags(textSpecificFlags:Map<String, String -> FlxLocalSprite>, genericFlags:Map<String, DialogBox -> Void>) {
		return function(db:DialogBox, text:String):String {
			var transformedText:String = '';
			var i = 0;
			var inFlag:Bool = false;
			var anchor:Int = 0;
			var offset:Int = 0;
			db.flags = new Array<DialogBox.DialogBoxFlag>();
			for (i in 0...text.length) {
				if (!inFlag) {
					if (text.charAt(i) == '[') {
						inFlag = true;
						anchor = i + 1;
					} else {
						transformedText += text.charAt(i);
					}
				} else {
					if (text.charAt(i) == ']') {
						var builtStr:String = text.substring(anchor, i);
						if (textSpecificFlags.exists(builtStr)) {
							db.flags.push({name: builtStr, position: anchor - 1 - offset, flagAction: textSpecificFlags.get(builtStr), type: START});
							offset += builtStr.length + 2;
							inFlag = false;
						} else if (builtStr.charAt(0) == '/' && textSpecificFlags.exists(builtStr.substring(1))) {
							var flagName = builtStr.substring(1);
							db.flags.push({name: flagName, position: anchor - 1 - offset, flagAction: textSpecificFlags.get(flagName), type: END});
							offset += builtStr.length + 2;
							inFlag = false;
						} else if (genericFlags.exists(builtStr)) {
							if (builtStr.charAt(0) == '/') {
								var flagName = builtStr.substring(1);
								if (text.indexOf('[' + flagName + ']') != -1) {
									db.flags.push({name: flagName, position: anchor - 1 - offset, genericAction: genericFlags.get(flagName), type: END});
								}
							} else {
								var typeToAssign:DialogBox.FlagType = POINT;
								if (text.indexOf('[/' + builtStr + ']') != -1) {
									typeToAssign = START;
								}
								db.flags.push({name: builtStr, position: anchor - 1 - offset, genericAction: genericFlags.get(builtStr), type: typeToAssign});
							}
							offset += builtStr.length + 2;
							inFlag = false;
						}
					}
				}
			}
			return transformedText;
		}
	}
	
	public static var parseCommonTextFlags:DialogBox -> String -> String = function(db:DialogBox, text:String) {
		return parseTextFlags([
			'wave'  => function(t) { return new WaveText(t, db.options.textFormat); },
			'shake' => function(t) { return new ShakeText(t, db.options.textFormat); },
		],
		[
			'delay' => function(db) { db.pause = 30; },
		])(db, text);
	};
}
