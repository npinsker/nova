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
	
	public static function minBy<T>(a:Array<T>, cmpFn:T -> Float):T {
		var bestIndex:Int = 0;
		var bestValue:Float = cmpFn(a[0]);
		for (i in 1...a.length) {
			var value:Float = cmpFn(a[i]);
			if (value < bestValue) {
				bestValue = value;
				bestIndex = i;
			}
		}
		return a[bestIndex];
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
	
	public static function indices<T>(a:Array<T>, b:Array<Int>):Array<T> {
		var r = new Array<T>();
		for (i in b) {
			r.push(a[i]);
		}
		return r;
	}
	
	public static function extend<T>(a:Array<T>, b:Array<T>):Array<T> {
		for (k in b) {
			a.push(k);
		}
		
		return a;
	}
	
	public static function remove<T>(a:Array<T>, element:T, ?cmpFn:T -> T -> Bool = null):Bool {
		var index = indexOf(a, element, cmpFn);
		
		if (index != -1) {
			a.splice(index, 1);
		}
		return (index != -1);
	}
	
	public static function exactMatch<T>(a:Array<T>, b:Array<T>):Bool {
		if (a.length != b.length) return false;
		for (i in 0...a.length) {
			if (a[i] != b[i]) return false;
		}
		return true;
	}
	
	public static function unorderedMatch<T>(a:Array<T>, b:Array<T>, fn:T -> T -> Int):Bool {
		if (a.length != b.length) return false;
		var sa:Array<T> = a.copy();
		sa.sort(fn);
		var sb:Array<T> = b.copy();
		sb.sort(fn);
		return exactMatch(sa, sb);
	}
	
	public static function unorderedStringMatch(a:Array<String>, b:Array<String>):Bool {
		return unorderedMatch(a, b, function(a, b) { return (a < b ? -1 : 1); });
	}
	
	public static function randomShuffle<T>(a:Array<T>):Void {
		for (i in 0...a.length) {
			var t:T = a[i];
			var pivot = Std.random(a.length - i) + i;
			a[i] = a[pivot];
			a[pivot] = t;
		}
	}
	
	public static function filterByIndex<T>(a:Array<T>, fn:Int -> Bool):Array<T> {
		var ret:Array<T> = new Array<T>();
		for (i in 0...a.length) {
			if (fn(i)) {
				ret.push(a[i]);
			}
		}
		return ret;
	}
	
	public static function eachRow<T>(a:Array<Array<T>>, fn:Array<T> -> Array<T>):Array<Array<T>> {
		for (i in 0...a.length) {
			a[i] = fn(a[i]);
		}
		return a;
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