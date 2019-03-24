package nova.utils;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

/**
 * ...
 * @author Nathan Pinsker
 */
class GeomUtils {
	public static function expand(rect:FlxRect, amt:Float):FlxRect {
		return new FlxRect(rect.x - amt, rect.y - amt, rect.width + 2 * amt, rect.height + 2 * amt);
	}
	
	public static function distance(a:Pair<Float>, b:Pair<Float>):Float {
		return Math.sqrt(distanceSquared(a, b));
	}
	
	public static function distanceSquared(a:Pair<Float>, b:Pair<Float>):Float {
		return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
	}
	
	public static function distanceToPoint(rect:FlxRect, point:Pair<Float>, norm:Int = 1):Float {
		var xd:Float = 0, yd:Float = 0;
		if (point.x < rect.x) {
			xd = rect.x - point.x;
		} else if (point.x > rect.x + rect.width) {
			xd = point.x - rect.x - rect.width;
		}
		
		if (point.y < rect.y) {
			yd = rect.y - point.y;
		} else if (point.y > rect.y + rect.height) {
			yd = point.y - rect.y - rect.height;
		}
		
		if (norm == 2) {
			return Math.sqrt(xd * xd + yd * yd);
		}
		return xd + yd;
	}
	
	public static function pointOnLine(p1:Pair<Float>, p2:Pair<Float>, a:Pair<Float>):Pair<Float> {
		// Finds the point on the line p1 -> p2 that is closest to the point 'a'.
		
		if (p1.y == p2.y) {
			return [a.x, p1.y];
		}
		
		var slope1:Float = (p2.y - p1.y) / (p2.x - p1.x);
		var b1:Float = p1.x * slope1 - p1.y;
		
		var slope2:Float = -1.0 / slope1;
		var b2:Float = a.x * slope2 - a.y;
		
		var rx:Float = (b2 - b1) / (slope2 - slope1);
		return [rx, slope1 * rx + b1];
	}
	
	public static function approx(p1:Pair<Float>, p2:Pair<Float>, eps:Float = 1e-6):Bool {
		return Math.abs(p1.x - p2.x) <= eps && Math.abs(p1.y - p2.y) <= eps;
	}
}