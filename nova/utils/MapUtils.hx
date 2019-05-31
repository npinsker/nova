package nova.utils;

/**
 * Utilities for working with Haxe's Map object.
 */
class MapUtils {
	@:generic
	public static function merge<T, U>(a:Map<T, U>, b:Map<T, U>):Map<T, U> {
		var newMap:Map<T, U> = new Map<T, U>();
		for (key in a.keys()) {
			newMap.set(key, a.get(key));
		}
		for (key in b.keys()) {
			newMap.set(key, b.get(key));
		}
		return newMap;
	}
}
