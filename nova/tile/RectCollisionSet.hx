package nova.tile;
import flixel.math.FlxRect;
import nova.utils.Pair;

/**
 * Checks for collisions against a set of rectangles.
 */
@:generic
class RectCollisionSet<T> implements CollisionSet {
    // TODO: use an Int -> Object map for objects instead of an array
	public var objects:Array<T>;
	public var objectToRect:T -> FlxRect;
	public var rects:Array<FlxRect>;
	public var subdivideDims:Pair<Int>;
    public var collisionHook:Array<T> -> Void = null;
	
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
				tileToObjects.get(coord).push(objects.length - 1);
			}
		}
	}
	
	public function remove(object:T) {
        var idx = objects.indexOf(object);
		objects.remove(object);
		
		var rect:FlxRect = objectToRect(object);
        var startX:Int = Math.floor(rect.x / subdivideDims.x - 0.01);
		var endX:Int = Math.ceil((rect.x + rect.width) / subdivideDims.x + 0.01);
		var startY:Int = Math.floor(rect.y / subdivideDims.y - 0.01);
		var endY:Int = Math.ceil((rect.y + rect.height) / subdivideDims.y + 0.01);
			
		for (x in startX...endX + 1) {
			for (y in startY...endY + 1) {
				var coord:Int = X_MULT * x + y;
				tileToObjects.get(coord).remove(idx);
			}
		}
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

  public function clear() {
		for (k in tileToObjects.keys()) {
			tileToObjects.remove(k);
		}
    objects = [];
  }
	
	public function getOverlappingObjects(rect:FlxRect):Array<CollisionShape> {
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
        var collisions = returnArray.map(function(ind) { return objects[ind]; });
        if (this.collisionHook != null) {
            collisionHook(collisions);
        }

		return cast returnArray.map(function(ind) { return new CollisionShape.CollisionRect(objectToRect(objects[ind])); });
	}
}
