package nova.tile;
import flixel.math.FlxRect;
import nova.geom.Direction;
import nova.utils.Pair;

/**
  * Detects collisions across different types of collision sets.
  */
class CollisionManager {
  public var staticCollisionSets:Array<CollisionSet>;
  public var dynamicCollisionSets:Array<CollisionSet>;

  public var lastCollisionShapes:Array<CollisionShape>;

	public function new() {
    staticCollisionSets = new Array<CollisionSet>();
    dynamicCollisionSets = new Array<CollisionSet>();
    lastCollisionShapes = [];
	}
  
  public function addStaticCollisionSet(set:CollisionSet) {
    staticCollisionSets.push(set);
  }
  
  public function addDynamicCollisionSet(set:CollisionSet) {
    dynamicCollisionSets.push(set);
  }
	
	public function attemptMove(objectRect:FlxRect, movement:Pair<Float>):Pair<Float> {
		// Attempts to move the given rectangle in the given direction.
		// Returns a pair representing the direction it could move in.
		var rect:FlxRect = new FlxRect();
		rect.copyFrom(objectRect);

        lastCollisionShapes = [];

		var movementX = attemptMoveHorizontally(rect, movement.x);
        rect.x += movement.x + movementX;

		var movementY = attemptMoveVertically(rect, movement.y);
        rect.y += movement.y + movementY;
    
        return [rect.x - objectRect.x, rect.y - objectRect.y];
	}
	
	public function attemptMoveHorizontally(objectRect:FlxRect, movementX:Float):Float {
		var rect:FlxRect = new FlxRect();
		rect.copyFrom(objectRect);
		
		rect.x += movementX;
    
    var leftMove:Float = nudgeOutOfObjects(rect, LEFT);
    var rightMove:Float = nudgeOutOfObjects(rect, RIGHT);
		
    if (leftMove < 10 || rightMove < 10) {
      if (Math.abs(leftMove) < Math.abs(rightMove)) return -leftMove;
      return rightMove;
    }
    return 0;
	}
	
	public function attemptMoveVertically(objectRect:FlxRect, movementY:Float):Float {
		var rect:FlxRect = new FlxRect();
		rect.copyFrom(objectRect);
		
		rect.y += movementY;
    
        var upMove:Float = nudgeOutOfObjects(rect, UP);
        var downMove:Float = nudgeOutOfObjects(rect, DOWN);
    
		if (upMove < 10 || downMove < 10) {
            if (upMove < downMove) return -upMove;
            return downMove;
        }
        return 0;
	}
	
	public function update() {
        for (collisionSet in dynamicCollisionSets) {
          //collisionSet.refresh();
        }
	}
	
	public function getCollisionShapes(rect:FlxRect):Array<CollisionShape> {
		var r = new Array<CollisionShape>();
        for (collisionSet in staticCollisionSets) {
          for (obj in collisionSet.getOverlappingObjects(rect)) {
            r.push(obj);
          }
        }
        
        for (collisionSet in dynamicCollisionSets) {
          for (obj in collisionSet.getOverlappingObjects(rect)) {
            r.push(obj);
          }
        }

		return r;
	}
	
	public function nudgeOutOfObjects(rect:FlxRect, direction:Direction):Float {
        var nudgeValue:Float = 0;
        var collisionShapes = getCollisionShapes(rect);
        for (collisionShape in collisionShapes) {
            lastCollisionShapes.push(collisionShape);
            nudgeValue = Math.max(nudgeValue, collisionShape.nudge(rect, direction));
        }
        return nudgeValue;
	}
}
