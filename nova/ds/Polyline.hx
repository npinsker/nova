package nova.ds;

import nova.utils.ArrayUtils;
import nova.utils.Pair;

enum PolylineConnectStyle {
  /**
    * Polyline consists of line segments from point 0 to point 1, point 1 to point 2, etc.
    */
  SLOPED;

  /**
    * Polyline consists of line segments with slope 0 forming a piecewise line.
    */
  FLAT;
}

/**
 * Represents a polyline on the 2D plane, specified by the supplied points.
 * The points must be supplied in increasing order of x-value.
 */
class Polyline implements RealValuedFunction {
  public var points:Array<Pair<Float>>;
  public var connectStyle:PolylineConnectStyle;

  public function new(points:Array<Pair<Float>>, ?connectStyle:PolylineConnectStyle) {
    this.points = points;
    this.connectStyle = (connectStyle != null ? connectStyle: SLOPED);
    
    if (points.length <= 1 && connectStyle == SLOPED) {
      throw 'Sloped polyline must have at least two points.';
    }
  }

  /**
   * Looks up the y-value of the polyline at the point with the given x-value.
   * Has runtime O(lg n).
  */
  public function getValueAt(point:Float):Float {
    var idx = ArrayUtils.binarySearch(points, new Pair<Float>(point, 0),
        function(pt) { return pt.x; });

    if (idx == -1) {
      idx = 0;
    }
    if (idx == points.length - 1 && connectStyle == SLOPED) {
      idx = points.length - 2;
    }

    if (connectStyle == SLOPED) {
      var slope:Float = (points[idx + 1].y - points[idx].y) /
                        (points[idx + 1].x - points[idx].x);
      return points[idx].y + (points[idx].x - point) * slope;
    } else {
      return points[idx].y;
    }
  }
}
