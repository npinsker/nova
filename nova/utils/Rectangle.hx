package nova.utils;

import flixel.math.FlxRect;

/**
 * Represents a rectangle with coordinates as ordered pairs of either Floats or Ints.
 * Properties can be accessed with the 'x', 'y', 'width', and 'height' values.
 * ```
 */
@:generic
abstract Rectangle<K:Float>(Array<K>) {
	public inline function new(x:K, y:K, width:K, height:K) {
		this = [x, y, width, height];
	}
	
	public var x(get, set):K;
	function get_x() { return this[0]; }
	function set_x(x:K) { this[0] = x; return x; }
	
	public var y(get, set):K;
	function get_y() { return this[1]; }
	function set_y(y:K) { this[1] = y; return y; }

	public var width(get, set):K;
	function get_width() { return this[2]; }
	function set_width(width:K) { this[2] = width; return width; }
	
	public var height(get, set):K;
	function get_height() { return this[3]; }
	function set_height(height:K) { this[3] = height; return height; }
	
	@:from
	public static function fromIntArray(a:Array<Int>):Rectangle<Int> {
		if (a.length != 4) {
			trace("Error: `fromArray` must have exactly two arguments.");
			return null;
		}
		return new Rectangle<Int>(a[0], a[1], a[2], a[3]);
	}
	
	@:from
	public static function fromFloatArray(a:Array<Float>):Rectangle<Float> {
		if (a.length != 4) {
			trace("Error: `fromArray` must have exactly two arguments.");
			return null;
		}
		return new Rectangle<Float>(a[0], a[1], a[2], a[3]);
	}
	
	@:from
	public static function fromFlxRect(a:FlxRect):Rectangle<Float> {
		return new Rectangle<Float>(a.x, a.y, a.width, a.height);
	}

	@:from
	public static function fromOpenFLRect(a:openfl.geom.Rectangle):Rectangle<Float> {
		return new Rectangle<Float>(a.x, a.y, a.width, a.height);
	}
	
	@:to
	public function toArray():Array<K> {
		return this;
	}
	
	@:to
	public function toFlxRect():FlxRect {
		return new FlxRect(this[0], this[1], this[2], this[3]);
	}

    @:to
    public function toOpenFLRectangle():openfl.geom.Rectangle {
        return new openfl.geom.Rectangle(this[0], this[1], this[2], this[3]);
    }
	
	@:to
	public function toFloatRect():Rectangle<Float> {
		return new Rectangle<Float>(this[0], this[1], this[2], this[3]);
	}
	
	@:op(A == B)
	public function equals(rhs:Array<K>):Bool {
		if (rhs == null) return (this == null);
		return this[0] == rhs[0] && this[1] == rhs[1] &&
               this[2] == rhs[2] && this[3] == rhs[3];
	}
	
	public function area():Float {
		return this[2] * this[3];
	}
	
	public function copy():Rectangle<K> {
		return new Rectangle<K>(this[0], this[1], this[2], this[3]);
	}
	
	public function toString():String {
		return "(" + this[0] + ", " + this[1] + ", " + this[2] + ", " + this[3] + ")";
	}
}
