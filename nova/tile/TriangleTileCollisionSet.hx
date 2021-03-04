package nova.tile;

import flixel.math.FlxRect;
import nova.render.FlxLocalSprite;
import nova.utils.Pair;
import nova.tile.CollisionShape.CollisionRect;
import nova.tile.CollisionShape.CollisionTileTriangle;

enum TriangleTileType {
  EMPTY;
  SOLID;
  TRIANGLE;
}

typedef TriangleCollisionInfo = {
  var type:TriangleTileType;
  @:optional var orientation:CollisionShape.CollisionTileTriangleOrientation;
}

/**
 * Checks for collisions against a set of tiles. The tiles can be rectangular or triangular.
 *
 * For most use cases these checks will have O(1) runtime since the tiles have fixed size.
 */
@:generic
class TriangleTileCollisionSet<T> implements CollisionSet {
	public var tiles:Array<Array<T>>;
	public var tileDims:Pair<Int>;
	public var typeToCollisionInfo:T -> TriangleCollisionInfo;
  public var trackedObject:FlxLocalSprite = null;

	public function new(tiles:Array<Array<T>>, tileDims:Pair<Int>, ?typeToCollisionInfo:T -> TriangleCollisionInfo) {
		this.tiles = tiles;
		this.tileDims = tileDims;
		this.typeToCollisionInfo = typeToCollisionInfo;
	}
  
  public function trackObject(sprite:FlxLocalSprite) {
    trackedObject = sprite;
  }
	
	public function getOverlappingObjects(rect:FlxRect):Array<CollisionShape> {
		// Returns the (x, y) positions of all tiles that overlap the given rectangle.
		var returnArray:Array<CollisionShape> = new Array<CollisionShape>();
    var offset:Pair<Float> = (trackedObject != null ? trackedObject.xy : [0, 0]);
    var offsetRect = new FlxRect(rect.x - offset.x, rect.y - offset.y, rect.width, rect.height);
		
		var startX:Int = Math.floor(offsetRect.x / tileDims.x - 0.01);
		var endX:Int = Math.ceil((offsetRect.x + offsetRect.width) / tileDims.x + 0.01);
		var startY:Int = Math.floor(offsetRect.y / tileDims.y - 0.01);
		var endY:Int = Math.ceil((offsetRect.y + offsetRect.height) / tileDims.y + 0.01);
		
		if (startX < 0) startX = 0;
		if (endX >= tiles[0].length) endX = tiles[0].length;
		if (startY < 0) startY = 0;
		if (endY >= tiles.length) endY = tiles.length;
		
		for (y in startY...endY) {
			for (x in startX...endX) {
        var result = typeToCollisionInfo(tiles[y][x]);
        if (result.type == EMPTY) {
          continue;
        }
				
				var tileStart:Pair<Float> = [x * tileDims.first, y * tileDims.second];
				
				if (!(tileStart.x + tileDims.x > offsetRect.x && tileStart.y + tileDims.y > offsetRect.y &&
				      offsetRect.x + offsetRect.width > tileStart.x && offsetRect.y + offsetRect.height > tileStart.y)) {
					continue;
				}
        if (result.type == SOLID) {
          returnArray.push(new CollisionRect(new FlxRect(tileStart.x + offset.x, tileStart.y + offset.y, tileDims.first, tileDims.second)));
          continue;
        }
        
        var triangleCollision = new CollisionTileTriangle(new FlxRect(tileStart.x + offset.x, tileStart.y + offset.y, tileDims.first, tileDims.second), result.orientation);
        if (triangleCollision.overlapsWithRect(rect)) {
          returnArray.push(triangleCollision);
        }
			}
		}
		return returnArray;
	}
}
