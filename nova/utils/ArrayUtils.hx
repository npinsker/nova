package nova.utils;

using Lambda;

/**
 * A lightweight class containing simple Array utilities.
 * 
 * @author Nathan Pinsker
 */

class ArrayUtils {
	public static function foldFn<T:Float>(a:Array<T>, cmpFn:T -> T -> T):T {
		return a.fold(
			function foldf(a:T, b:T):T {
				if (b == null) {
					return a;
				}
				return cmpFn(a, b);
			}, null);
	}
	
	public static function min(a:Array<Float>):Float {
		return foldFn(a, Math.min);
	}
	
	public static function max(a:Array<Float>):Float {
		return foldFn(a, Math.max);
	}
	
	public static function last<T>(a:Array<T>):T {
		return a[a.length - 1];
	}
	
	public static function indexOf<T>(a:Array<T>, element:T, ?cmpFn:T -> T -> Bool = null):Int {
		for (i in 0...a.length) {
			if (cmpFn == null && a[i] == element) {
				return i;
			}
			if (cmpFn != null && cmpFn(a[i], element)) {
				return i;
			}
		}
		return -1;
	}
	
	public static function remove<T>(a:Array<T>, element:T, ?cmpFn:T -> T -> Bool = null):Bool {
		var index = indexOf(a, element, cmpFn);
		
		if (index != -1) {
			a.splice(index, 1);
		}
		return (index != -1);
	}
	
	public static function to2D<T>(a:Array<T>, columns:Int):Array<Array<T>> {
		if (a.length % columns != 0) {
			trace('Warning: called `to2D` where length ($a.length) doesn\'t evenly divide $columns');
		}

		var builtArray:Array<Array<T>> = new Array<Array<T>>();
		var index = 0;
		while (index < a.length) {
			builtArray.push(a.slice(index, index + columns));
			index += columns;
		}
		return builtArray;
	}
}