package nova.tile;
import flixel.math.FlxRect;
import nova.utils.Pair;

/**
 * Checks for collisions against a set of rectangles.
 */
@:generic
class RectCollisionSet<T> {
	public var objects:Array<T>;
	public var objectToRect:T -> FlxRect;
	public var rects:Array<FlxRect>;
	public var subdivideDims:Pair<Int>;
	
	public var tileToObjects:Map<Int, Array<Int>>;
	public var X_MULT:Int = 64333;
	
	public function new(objects:Array<T>, subdivideDims:Pair<Int>, objectToRect:T -> FlxRect) {
		this.objects = [for (i in 0...objects.length) objects[i]];
		this.subdivideDims = subdivideDims;
		this.objectToRect = objectToRect;
		tileToObjects = new Map<Int, Array<Int>>();
		refresh();
	}
	
	public function add(object:T) {
		objects.push(object);
		rects.push(objectToRect(object));
	}
	
	public function refresh() {
		for (k in tileToObjects.keys()) {
			tileToObjects.remove(k);
		}
		
		for (objectIndex in 0...objects.length) {
			var object:T = objects[objectIndex];
			var rect:FlxRect = objectToRect(object);
			var startX:Int = Math.floor(rect.x / subdivideDims.x - 0.01);
			var endX:Int = Math.ceil((rect.x + rect.width) / subdivideDims.x + 0.01);
			var startY:Int = Math.floor(rect.y / subdivideDims.y - 0.01);
			var endY:Int = Math.ceil((rect.y + rect.height) / subdivideDims.y + 0.01);
			
			for (x in startX...endX + 1) {
				for (y in startY...endY + 1) {
					var coord:Int = X_MULT * x + y;
					if (!tileToObjects.exists(coord)) {
						tileToObjects.set(coord, new Array<Int>());
					}
					tileToObjects.get(coord).push(objectIndex);
				}
			}
		}
	}
	
	public function getOverlappingObjects(rect:FlxRect,
										  ?overrideCollisionFn:T -> Bool = null):Array<T> {
		// Returns the (x, y) positions of all tiles that overlap the given rectangle.
		// Supplying an 'offset' parameter of (A, B) has the same effect as translating the rectangle
		// by (-A, -B).
		var returnArray:Array<Int> = new Array<Int>();
		
		var startX:Int = Math.floor(rect.x / subdivideDims.x - 0.01);
		var endX:Int = Math.ceil((rect.x + rect.width) / subdivideDims.x + 0.01);
		var startY:Int = Math.floor(rect.y / subdivideDims.y - 0.01);
		var endY:Int = Math.ceil((rect.y + rect.height) / subdivideDims.y + 0.01);
		
		for (x in startX...endX + 1) {
			for (y in startY...endY + 1) {
				var coord:Int = X_MULT * x + y;
				if (tileToObjects.exists(coord)) {
					var objectsInThisTile:Array<Int> = tileToObjects.get(coord);
					for (ind in objectsInThisTile) {
						if (returnArray.indexOf(ind) == -1 && objectToRect(objects[ind]).overlaps(rect)) {
							returnArray.push(ind);
						}
					}
				}
			}
		}
		return returnArray.map(function(ind) { return objects[ind]; });
	}
	
	public function getOverlappingObjectsPoint(point:Pair<Float>,
											   ?overrideCollisionFn:T -> Bool = null):Array<T> {
		// Returns the (x, y) positions of all tiles that overlap the given point.
		return getOverlappingObjects(new FlxRect(point.x, point.y, 0, 0), overrideCollisionFn);
	}
	
	public function getRectanglesForNudge(rect:FlxRect,
										  ?overrideCollisionFn:T -> Bool = null):Array<FlxRect> {
		return getOverlappingObjects(rect, overrideCollisionFn).map(objectToRect);
	}
}
