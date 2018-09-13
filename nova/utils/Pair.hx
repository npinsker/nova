package nova.utils;

/**
 * Represents a pair of numbers, either Floats or Ints.
 * 
 * Properties can be accessed with the 'x' and 'y' values,
 * or the 'first' and 'second' values.
 */
@:generic
abstract Pair<K:Float>(Array<K>) {
	public static var LEFT:Pair<Int> = [-1, 0];
	public static var RIGHT:Pair<Int> = [1, 0];
	public static var UP:Pair<Int> = [0, -1];
	public static var DOWN:Pair<Int> = [0, 1];
	
	public inline function new(x:K, y:K) {
		this = [x, y];
	}
	
	public var x(get, never):K;
	function get_x() { return this[0]; }
	
	public var y(get, never):K;
	function get_y() { return this[1]; }
	
	public var first(get, never):K;
	function get_first() { return this[0]; }
	
	public var second(get, never):K;
	function get_second() { return this[1]; }
	
	@:from
	public static function fromIntArray(a:Array<Int>):Pair<Int> {
		if (a.length != 2) {
			trace("Error: `fromArray` must have exactly two arguments.");
			return null;
		}
		return new Pair<Int>(a[0], a[1]);
	}
	
	@:from
	public static function fromFloatArray(a:Array<Float>):Pair<Float> {
		if (a.length != 2) {
			trace("Error: `fromArray` must have exactly two arguments.");
			return null;
		}
		return new Pair<Float>(a[0], a[1]);
	}
	
	@:to
	public function toArray():Array<K> {
		return this;
	}
	
	@:op(A + B)
	public function add(rhs:Array<K>):Pair<K> {
		return new Pair<K>(this[0] + rhs[0], this[1] + rhs[1]);
	}
	
	@:op(A - B)
	public function subtract(rhs:Array<K>):Pair<K> {
		return new Pair<K>(this[0] - rhs[0], this[1] - rhs[1]);
	}
	
	@:op(A * B)
	public function multiply(rhs:K):Pair<K> {
		return new Pair<K>(this[0] * rhs, this[1] * rhs);
	}
	
	@:op(A == B)
	public function equals(rhs:Array<K>):Bool {
		return this[0] == rhs[0] && this[1] == rhs[1];
	}
	
	public function toString():String {
		return "(" + this[0] + ", " + this[1] + ")";
	}
}