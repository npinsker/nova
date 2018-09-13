package nova.utils;

/**
 * A lightweight class containing simple Array utilities.
 * 
 * @author Nathan Pinsker
 */

class ArrayUtils {
	public static function last<T>(a:Array<T>):T {
		return a[a.length - 1];
	}
}