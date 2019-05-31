package nova.utils;

using Lambda;

/**
 * A lightweight class containing simple character utilities.
 */

class CharUtils {
	public static function isDigit(code:Int) {
		return code >= '0'.code && code <= '9'.code;
	}
}
