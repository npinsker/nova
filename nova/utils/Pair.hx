package nova.utils;
import flixel.math.FlxPoint;

/**
 * Represents a pair of numbers, either Floats or Ints. Properties can be accessed with the 'x' and 'y' values.
 * 
 * Pairs provide a substantial ease-of-use advantage over classes, as they can be directly declared like arrays.
 * They support addition and multiplication by both scalars and other Pairs, as in the examples below:
 * 
 * ```
 * var p:Pair<Int> = [1, 2];
 * 
 * trace(p * 2);  // [2, 4]
 * trace(p * [5, 3]);  // [5, 6]
 * ```
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
	
	public var x(get, set):K;
	function get_x() { return this[0]; }
	function set_x(x:K) { this[0] = x; return x; }
	
	public var y(get, set):K;
	function get_y() { return this[1]; }
	function set_y(y:K) { this[1] = y; return y; }
	
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
	
	@:from
	public static function fromFlxPoint(a:FlxPoint):Pair<Float> {
		return new Pair<Float>(a.x, a.y);
	}
	
	@:to
	public function toArray():Array<K> {
		return this;
	}
	
	@:to
	public function toFlxPoint():FlxPoint {
		return new FlxPoint(this[0], this[1]);
	}
	
	@:to
	public function toFloatPair():Pair<Float> {
		return new Pair<Float>(this[0], this[1]);
	}
	
	@:op(A + B) @:commutative
	public static function addFloatPair<K:Float>(p:Pair<K>, rhs:Array<Float>):Pair<Float> {
		return new Pair<Float>(p.x + rhs[0], p.y + rhs[1]);
	}
	
	@:op(A + B) @:commutative
	public static function addIntPair(p:Pair<Float>, rhs:Array<Int>):Pair<Float> {
		return new Pair<Float>(p.x + rhs[0], p.y + rhs[1]);
	}
	
	@:op(A + B) @:commutative
	public static function addTwoIntPairs(p:Pair<Int>, rhs:Array<Int>):Pair<Int> {
		return new Pair<Int>(p.x + rhs[0], p.y + rhs[1]);
	}
	
	@:op(A + B) @:commutative
	public static function addNumber<K:Float>(p:Pair<K>, rhs:K):Pair<K> {
		return new Pair<K>(p.x + rhs, p.y + rhs);
	}
	
	@:op(A - B)
	public function subtractNumber(rhs:K):Pair<K> {
		return new Pair<K>(this[0] - rhs, this[1] - rhs);
	}
	
	@:op(A - B)
	public function subtract(rhs:Array<K>):Pair<K> {
		return new Pair<K>(this[0] - rhs[0], this[1] - rhs[1]);
	}
	
	@:op(A - B)
	public static function subtractFloatPairOnLeft(p:Pair<Float>, rhs:Array<Int>):Pair<Float> {
		return new Pair<Float>(p.x - rhs[0], p.y - rhs[1]);
	}
	
	@:op(A - B)
	public static function subtractFloatPairOnRight(p:Pair<Int>, rhs:Array<Float>):Pair<Float> {
		return new Pair<Float>(p.x - rhs[0], p.y - rhs[1]);
	}

	@:op(A * B) @:commutative
	public static function multiplyByNumber<K:Float>(p:Pair<K>, rhs:K):Pair<K> {
		return new Pair<K>(p.x * rhs, p.y * rhs);
	}
	
	@:op(A * B) @:commutative
	public static function multiplyByFloatPair<K:Float>(p:Pair<K>, rhs:Array<Float>):Pair<Float> {
		return new Pair<Float>(p.x * rhs[0], p.y * rhs[1]);
	}
	
	@:op(A * B) @:commutative
	public static function multiplyIntPair(p:Pair<Float>, rhs:Array<Int>):Pair<Float> {
		return new Pair<Float>(p.x * rhs[0], p.y * rhs[1]);
	}
	
	@:op(A * B) @:commutative
	public static function multiplyTwoIntPairs(p:Pair<Int>, rhs:Array<Int>):Pair<Int> {
		return new Pair<Int>(p.x * rhs[0], p.y * rhs[1]);
	}
	
	@:op(A / B)
	public static function divideBy<K:Float, L:Float>(p:Pair<K>, rhs:L):Pair<Float> {
		return new Pair<Float>(p.x / rhs, p.y / rhs);
	}
	
	@:op(-A)
	public function negate():Pair<K> {
		return new Pair<K>( -this[0], -this[1]);
	}
	
	@:op(A == B)
	public function equals(rhs:Array<K>):Bool {
		if (rhs == null) return (this == null);
		return this[0] == rhs[0] && this[1] == rhs[1];
	}
	
	public function norm():Float {
		return Math.sqrt(this[0] * this[0] + this[1] * this[1]);
	}
	
	public function normSquared():K {
		return this[0] * this[0] + this[1] * this[1];
	}
	
	public function copy():Pair<K> {
		return new Pair<K>(this[0], this[1]);
	}
	
	public function toString():String {
		return "(" + this[0] + ", " + this[1] + ")";
	}
}