package nova.utils;
import flixel.math.FlxRect;

/**
 * ...
 * @author Nathan Pinsker
 */
class GeomUtils {
	public static function expand(rect:FlxRect, amt:Float):FlxRect {
		return new FlxRect(rect.x - amt, rect.y - amt, rect.width + 2 * amt, rect.height + 2 * amt);
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
}