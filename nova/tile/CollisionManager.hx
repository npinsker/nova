package nova.tile;
import flixel.math.FlxRect;
import nova.utils.Pair;

/**
  * Detects collisions across different types of collision sets.
  */
@:generic
class CollisionManager<TType, RType> {
	public var tileCollisionSet:TileCollisionSet<TType> = null;
	public var staticRectCollisionSet:RectCollisionSet<RType> = null;
	public var dynamicRectCollisionSet:RectCollisionSet<RType> = null;

	public function new<TType, RType>() {
	}
	
	public function isPointOccupied(point:Pair<Float>):Bool {
		if (tileCollisionSet != null && tileCollisionSet.getOverlappingTilesPoint(point).length > 0) {
			return true;
		}
		if (staticRectCollisionSet != null && staticRectCollisionSet.getOverlappingObjectsPoint(point).length > 0) {
			return true;
		}
		if (dynamicRectCollisionSet != null && dynamicRectCollisionSet.getOverlappingObjectsPoint(point).length > 0) {
			return true;
		}
		return false;
	}
	
	public function attemptMove(objectRect:FlxRect, movement:Pair<Float>):Pair<Float> {
		// Attempts to move the given rectangle in the given direction.
		// Returns a pair representing the direction it could move in.
		var rect:FlxRect = new FlxRect();
		rect.copyFrom(objectRect);
		
		var movementX = attemptMoveHorizontally(rect, movement.x);
		rect.x += movementX;
		
		var movementY = attemptMoveVertically(rect, movement.y);
		rect.y += movement.y;
		
		return [movementX, movementY];
	}
	
	public function attemptMoveHorizontally(objectRect:FlxRect, movementX:Float):Float {
		var rect:FlxRect = new FlxRect();
		rect.copyFrom(objectRect);
		
		rect.x += movementX;
		var horizontalCollisionRects:Array<FlxRect> = getCollisionRects(rect);
		rect.x += horizontalNudgeOutOfObjects(horizontalCollisionRects, rect);
		
		return rect.x - objectRect.x;
	}
	
	public function attemptMoveVertically(objectRect:FlxRect, movementY:Float):Float {
		var rect:FlxRect = new FlxRect();
		rect.copyFrom(objectRect);
		
		rect.y += movementY;
		var verticalCollisionRects:Array<FlxRect> = getCollisionRects(rect);
		rect.y += verticalNudgeOutOfObjects(verticalCollisionRects, rect);
		
		return rect.y - objectRect.y;
	}
	
	public function update() {
		if (dynamicRectCollisionSet != null) {
			dynamicRectCollisionSet.refresh();
		}
	}
	
	public function getCollisionRects(rect:FlxRect):Array<FlxRect> {
		var r = new Array<FlxRect>();
		if (tileCollisionSet != null) {
			var rects:Array<FlxRect> = tileCollisionSet.getRectanglesForNudge(rect);
			for (rect in rects) {
				r.push(rect);
			}
		}
		for (collisionSet in [staticRectCollisionSet, dynamicRectCollisionSet]) {
			if (collisionSet != null) {
				var rects:Array<FlxRect> = collisionSet.getRectanglesForNudge(rect);
				for (rect in rects) {
					r.push(rect);
				}
			}
		}
		return r;
	}
	
	public function horizontalNudgeOutOfObjects(collisionRects:Array<FlxRect>, rect:FlxRect):Float {
		var canNudgeLeft:Bool = true;
		var canNudgeRight:Bool = true;
		for (collisionRect in collisionRects) {
			if (collisionRect.x + collisionRect.width > rect.x && collisionRect.y + collisionRect.height > rect.y &&
			    rect.x + rect.width > collisionRect.x && rect.y + rect.height > collisionRect.y) {
				var candidateLeft = rect.x + rect.width - collisionRect.x;
				var candidateRight = collisionRect.x + collisionRect.width - rect.x;
				
				if (candidateLeft > 10) canNudgeLeft = false;
				if (candidateRight > 10) canNudgeRight = false;
			}
		}
		var maxAmt:Float = 100;
		var minAmt:Float = 0;
		if (canNudgeLeft && !canNudgeRight) {
			for (collisionRect in collisionRects) {
				if (collisionRect.y + collisionRect.height <= rect.y || rect.y + rect.height <= collisionRect.y) {
					continue;
				}
				
				if (rect.x > collisionRect.x + collisionRect.width) {
					maxAmt = Math.min(maxAmt, rect.x - collisionRect.x - collisionRect.width);
				} else if (rect.x + rect.width > collisionRect.x) {
					minAmt = Math.max(minAmt, rect.x + rect.width - collisionRect.x);
				}
			}
			if (minAmt <= maxAmt) {
				return -minAmt;
			}
		} else if (canNudgeRight && !canNudgeLeft) {
			for (collisionRect in collisionRects) {
				if (collisionRect.y + collisionRect.height <= rect.y || rect.y + rect.height <= collisionRect.y) {
					continue;
				}
				
				if (rect.x + rect.width < collisionRect.x) {
					maxAmt = Math.min(maxAmt, collisionRect.x - rect.x - rect.width);
				} else if (rect.x < collisionRect.x + collisionRect.width) {
					minAmt = Math.max(minAmt, collisionRect.x + collisionRect.width - rect.x);
				}
			}
			if (minAmt <= maxAmt) {
				return minAmt;
			}
		}
		return 0;
	}
	
	public function verticalNudgeOutOfObjects(collisionRects:Array<FlxRect>, rect:FlxRect):Float {
		// TODO(npinsker): Transform the rect coordinates and call `horizontalNudgeOutOfObjects` instead
		var canNudgeUp:Bool = true;
		var canNudgeDown:Bool = true;
		for (collisionRect in collisionRects) {
			if (collisionRect.x + collisionRect.width > rect.x && collisionRect.y + collisionRect.height > rect.y &&
			    rect.x + rect.width > collisionRect.x && rect.y + rect.height > collisionRect.y) {
				var candidateUp = rect.y + rect.height - collisionRect.y;
				var candidateDown = collisionRect.y + collisionRect.height - rect.y;
				
				if (candidateUp > 10) canNudgeUp = false;
				if (candidateDown > 10) canNudgeDown = false;
			}
		}
		var maxAmt:Float = 100;
		var minAmt:Float = 0;
		if (canNudgeUp && !canNudgeDown) {
			for (collisionRect in collisionRects) {
				if (collisionRect.x + collisionRect.width <= rect.x || rect.x + rect.width <= collisionRect.x) {
					continue;
				}
				
				if (rect.y > collisionRect.y + collisionRect.height) {
					maxAmt = Math.min(maxAmt, rect.y - collisionRect.y - collisionRect.height);
				} else if (rect.y + rect.height > collisionRect.y) {
					minAmt = Math.max(minAmt, rect.y + rect.height - collisionRect.y);
				}
			}
			if (minAmt <= maxAmt) {
				return -minAmt;
			}
		} else if (canNudgeDown && !canNudgeUp) {
			for (collisionRect in collisionRects) {
				if (collisionRect.x + collisionRect.width <= rect.x || rect.x + rect.width <= collisionRect.x) {
					continue;
				}
				
				if (rect.y + rect.height < collisionRect.y) {
					maxAmt = Math.min(maxAmt, collisionRect.y - rect.y - rect.height);
				} else if (rect.y < collisionRect.y + collisionRect.height) {
					minAmt = Math.max(minAmt, collisionRect.y + collisionRect.height - rect.y);
				}
			}
			if (minAmt <= maxAmt) {
				return minAmt;
			}
		}
		return 0;
	}
}
