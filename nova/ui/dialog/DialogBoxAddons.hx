package nova.ui.dialog;

/**
 * ...
 * @author Nathan Pinsker
 */
class DialogBoxAddons {
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
}