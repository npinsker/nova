package nova.tile;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import nova.geom.Direction;
import nova.utils.Pair;


interface CollisionShape {
  public function overlapsWithRect(otherRect:FlxRect):Bool;
  public function overlapsWithPoint(point:FlxPoint):Bool;
  
  public function nudge(otherRect:FlxRect, direction:Direction):Float;
}

enum CollisionTileTriangleOrientation {
  TOP_LEFT;
  TOP_RIGHT;
  BOTTOM_LEFT;
  BOTTOM_RIGHT;
}

class CollisionRect implements CollisionShape {
  public var rect:FlxRect;
  
  public function new(rect:FlxRect) {
    this.rect = rect;
  }
  
  public function overlapsWithRect(otherRect:FlxRect):Bool {
    return otherRect.x + otherRect.width > rect.x &&
           otherRect.y + otherRect.height > rect.y &&
			     rect.x + rect.width > otherRect.x &&
           rect.y + rect.height > otherRect.y;
  }
  
  public function overlapsWithPoint(point:FlxPoint):Bool {
    return point.x > rect.x &&
           point.y > rect.y &&
			     point.x < rect.x + rect.width &&
           point.y < rect.y + rect.height;
  }
  
  public function nudge(otherRect:FlxRect, direction:Direction):Float {
    if (direction == LEFT) return otherRect.x + otherRect.width - rect.x;
    else if (direction == RIGHT) return rect.x + rect.width - otherRect.x;
    else if (direction == UP) return otherRect.y + otherRect.height - rect.y;
    return rect.y + rect.height - otherRect.y;
	}
}

class CollisionTileTriangle implements CollisionShape {
  public var rect:FlxRect;
  public var orientation:CollisionTileTriangleOrientation;
  
  public function new(rect:FlxRect, orientation:CollisionTileTriangleOrientation) {
    this.rect = rect;
    this.orientation = orientation;
  }
  
  public function overlapsWithRect(otherRect:FlxRect):Bool {
    if (!(otherRect.x + otherRect.width > rect.x &&
          otherRect.y + otherRect.height > rect.y &&
			    rect.x + rect.width > otherRect.x &&
          rect.y + rect.height > otherRect.y)) {
      return false;
    }
    
    if (orientation == TOP_LEFT || orientation == BOTTOM_RIGHT) {
      var top_leftness = otherRect.x + otherRect.y;
      var bottom_rightness = otherRect.x + otherRect.width + otherRect.y + otherRect.height;
      var diagonal = rect.x + rect.y + rect.width;
      return (orientation == TOP_LEFT ? top_leftness < diagonal : bottom_rightness > diagonal);
    }
    
    var top_rightness = -otherRect.x - otherRect.width + otherRect.y;
    var bottom_leftness = -otherRect.x + otherRect.y + otherRect.height;
    var diagonal = -rect.x + rect.y;
    return (orientation == TOP_RIGHT ? top_rightness < diagonal : bottom_leftness > diagonal);
  }

  public function overlapsWithPoint(point:FlxPoint):Bool {
    if (!(point.x > rect.x &&
          point.y > rect.y &&
			    point.x < rect.x + rect.width &&
          point.y < rect.y + rect.height)) {
      return false;
    }
    
    if (orientation == TOP_LEFT || orientation == BOTTOM_RIGHT) {
      var top_leftness = point.x + point.y;
      var diagonal = rect.x + rect.y + rect.width;
      return (orientation == TOP_LEFT ? top_leftness < diagonal : top_leftness > diagonal);
    }
    
    var top_rightness = -point.x + point.y;
    var diagonal = -rect.x + rect.y + rect.height;
    return (orientation == TOP_RIGHT ? top_rightness < diagonal : top_rightness > diagonal);
  }

  public function nudge(otherRect:FlxRect, direction:Direction):Float {
    if (!(otherRect.x + otherRect.width > rect.x &&
          otherRect.y + otherRect.height > rect.y &&
			    rect.x + rect.width > otherRect.x &&
          rect.y + rect.height > otherRect.y)) {
      return 0;
    }
    
    var diagonal = (orientation == TOP_LEFT || orientation == BOTTOM_RIGHT ?
                      rect.x + rect.y + rect.width :
                      -rect.x + rect.y);
    
    var candidate = 0.0;
    if (direction == LEFT) {
      candidate = otherRect.x + otherRect.width - rect.x;
    } else if (direction == UP) {
      candidate = otherRect.y + otherRect.height - rect.y;
    } else if (direction == RIGHT) {
      candidate = rect.x + rect.width - otherRect.x;
    } else {
      candidate = rect.y + rect.height - otherRect.y;
    }
    
    if (orientation == TOP_LEFT && (direction == RIGHT || direction == DOWN)) {
      candidate = Math.min(diagonal - (otherRect.x + otherRect.y), candidate);
    } else if (orientation == TOP_RIGHT && (direction == LEFT || direction == DOWN)) {
      candidate = Math.min(diagonal - ( -(otherRect.x + otherRect.width) + otherRect.y), candidate);
    } else if (orientation == BOTTOM_LEFT && (direction == UP || direction == RIGHT)) {
      candidate = Math.min( -otherRect.x + (otherRect.y + otherRect.height) - diagonal, candidate);
    } else if (orientation == BOTTOM_RIGHT && (direction == UP || direction == LEFT)) {
      candidate = Math.min(otherRect.right + otherRect.bottom - diagonal, candidate);
    }

    return Math.max(0, candidate);
  }
}