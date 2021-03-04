package nova.utils;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import nova.utils.Pair;

/**
 * Utilities for working with 2D geometry.
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
	
  /**
    * Finds the minimum distance from the supplied point to the given rectangle.
    * If the point is inside the rectangle, this value is zero.
    */
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
	
  /**
    * Finds the point on the line p1 -> p2 that is closest to the supplied point.
    */
	public static function pointOnLine(p1:Pair<Float>, p2:Pair<Float>, a:Pair<Float>):Pair<Float> {
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

  public static function cross(point1:Pair<Float>, point2:Pair<Float>):Float {
    return point1.x * point2.y - point1.y * point2.x;
  }

  /**
    * Checks whether the lines formed by (p1 -> p2) and (q1 -> q2) intersect.
    *
    * Adapted from https://github.com/pgkelley4/line-segments-intersect/blob/master/js/line-segments-intersect.js
    */
  public static function lineSegmentsIntersect(p1:Pair<Float>,
                                               p2:Pair<Float>,
                                               q1:Pair<Float>,
                                               q2:Pair<Float>):Bool {
    var p_vec:Pair<Float> = p2 - p1;
    var q_vec:Pair<Float> = q2 - q1;

    var uNumerator = cross(q1 - p1, p_vec);
    var denominator = cross(p_vec, q_vec);

    if (uNumerator == 0 && denominator == 0) {
      // Lines are parallel 
      var test1:Array<Bool> = [q1.x - p1.x < 0,
                               q1.x - p2.x < 0,
                               q2.x - p1.x < 0,
                               q2.x - p2.x < 0];
      var test2:Array<Bool> = [q1.y - p1.y < 0,
                               q1.y - p2.y < 0,
                               q2.y - p1.y < 0,
                               q2.y - p2.y < 0];

      return test1[0] != test1[1] || test1[0] != test1[2] || test1[0] != test1[3] ||
             test2[0] != test2[1] || test2[0] != test2[2] || test2[0] != test2[3];
    }

    if (denominator == 0) {
      return false;
    }

    var u = uNumerator / denominator;
    var t = cross(q1 - p1, q_vec) / denominator;
    return t >= 0 && t <= 1 && u >= 0 && u <= 1;
  }

  public static function angleDistance(angle1:Float, angle2:Float):Float {
    var diff = Math.abs(angle1 - angle2);
    if (diff > Math.PI) {
      return 2 * Math.PI - diff;
    }
    return diff;
  }

  public static function angleIsBetween(angle:Float, lower:Float, upper:Float):Bool {
    while (lower > angle) lower -= Math.PI * 2;
    while (upper < angle) upper += Math.PI * 2;
    return upper - lower < Math.PI * 2;
  }
	
	public static function approx(p1:Pair<Float>, p2:Pair<Float>, eps:Float = 1e-6):Bool {
		return Math.abs(p1.x - p2.x) <= eps && Math.abs(p1.y - p2.y) <= eps;
	}
}
