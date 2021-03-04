package nova.tile;

import flixel.math.FlxRect;
import nova.render.FlxLocalSprite;

import nova.tile.CollisionShape.CollisionRect;
import nova.utils.Pair;

/**
 * Checks for collisions against a set of tiles.
 *
 * For most use cases these checks will have O(1) runtime since the tiles have fixed size.
 */
@:generic
class TileCollisionSet<T> implements CollisionSet {
	public var tiles:Array<Array<T>>;
	public var tileDims:Pair<Int>;
	public var collisionFn:T -> Bool = null;
  public var trackedObject:FlxLocalSprite = null;

	public function new(tiles:Array<Array<T>>, tileDims:Pair<Int>, ?collisionFn:T -> Bool) {
		this.tiles = tiles;
		this.tileDims = tileDims;
		this.collisionFn = collisionFn;
	}
  
  public function trackObject(sprite:FlxLocalSprite) {
    trackedObject = sprite;
  }
	
	public function getOverlappingObjects(rect:FlxRect):Array<CollisionShape> {
		// Returns the (x, y) positions of all tiles that overlap the given rectangle.
		var returnArray:Array<CollisionShape> = new Array<CollisionShape>();
    var offset:Pair<Float> = (trackedObject != null ? trackedObject.xy : [0, 0]);
    rect = new FlxRect(rect.x - offset.x, rect.y - offset.y, rect.width, rect.height);
		
		var startX:Int = Math.floor(rect.x / tileDims.x - 0.01);
		var endX:Int = Math.ceil((rect.x + rect.width) / tileDims.x + 0.01);
		var startY:Int = Math.floor(rect.y / tileDims.y - 0.01);
		var endY:Int = Math.ceil((rect.y + rect.height) / tileDims.y + 0.01);
		
		if (startX < 0) startX = 0;
		if (endX >= tiles[0].length) endX = tiles[0].length;
		if (startY < 0) startY = 0;
		if (endY >= tiles.length) endY = tiles.length;
		
		for (y in startY...endY) {
			for (x in startX...endX) {
				if (!collisionFn(tiles[y][x])) {
					continue;
				}
				
				var tileStart:Pair<Float> = offset + [x * tileDims.first, y * tileDims.second];
				
				if (tileStart.x + tileDims.x > rect.x && tileStart.y + tileDims.y > rect.y &&
				    rect.x + rect.width > tileStart.x && rect.y + rect.height > tileStart.y) {
          returnArray.push(new CollisionRect(new FlxRect(tileStart.x, tileStart.y, tileDims.first, tileDims.second)));
				}
			}
		}
		return returnArray;
	}
}
