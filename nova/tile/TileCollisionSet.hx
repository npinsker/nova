package nova.tile;

import flixel.math.FlxRect;
import nova.utils.Pair;

/**
 * ...
 * @author Nathan Pinsker
 */
@:generic
class TileCollisionSet<T> {
	public var tiles:Array<Array<T>>;
	public var tileDims:Pair<Int>;
	public var collisionFn:T -> Bool = null;

	public function new(tiles:Array<Array<T>>, tileDims:Pair<Int>, ?collisionFn:T -> Bool) {
		this.tiles = tiles;
		this.tileDims = tileDims;
		this.collisionFn = collisionFn;
	}
	
	public function getOverlappingTiles(rect:FlxRect,
	                                    ?offset:Pair<Float>,
										?overrideCollisionFn:T -> Bool = null):Array<Pair<Int>> {
		// Returns the (x, y) positions of all tiles that overlap the given rectangle.
		// Supplying an 'offset' parameter of (A, B) has the same effect as translating the rectangle
		// by (-A, -B).
		var returnArray:Array<Pair<Int>> = new Array<Pair<Int>>();
		if (offset == null) {
			offset = [0, 0];
		}
		var usedCollisionFn = (overrideCollisionFn != null ? overrideCollisionFn : collisionFn);
		
		var startX:Int = Math.floor((rect.x - offset.x) / tileDims.x - 0.01);
		var endX:Int = Math.ceil((rect.x + rect.width - offset.x) / tileDims.x + 0.01);
		var startY:Int = Math.floor((rect.y - offset.y) / tileDims.y - 0.01);
		var endY:Int = Math.ceil((rect.y + rect.height - offset.y) / tileDims.y + 0.01);
		
		if (startX < 0) startX = 0;
		if (endX >= tiles[0].length) endX = tiles[0].length;
		if (startY < 0) startY = 0;
		if (endY >= tiles.length) endY = tiles.length;
		
		for (y in startY...endY) {
			for (x in startX...endX) {
				if (usedCollisionFn != null && !usedCollisionFn(tiles[y][x])) {
					continue;
				}
				
				var tileStart:Pair<Float> = offset + [x * tileDims.first, y * tileDims.second];
				
				if (tileStart.x + tileDims.x > rect.x && tileStart.y + tileDims.y > rect.y &&
				    rect.x + rect.width > tileStart.x && rect.y + rect.height > tileStart.y) {
					returnArray.push([x, y]);
				}
			}
		}
		return returnArray;
	}
	
	public function getOverlappingTilesPoint(point:Pair<Float>,
	                                         ?offset:Pair<Float>,
											 ?overrideCollisionFn:T -> Bool = null):Array<Pair<Int>> {
		// Returns the (x, y) positions of all tiles that overlap the given point.
		return getOverlappingTiles(new FlxRect(point.x, point.y, 0, 0), offset, overrideCollisionFn);
	}
	
	public function getRectanglesForNudge(rect:FlxRect,
	                                      ?offset:Pair<Float>,
										  ?overrideCollisionFn:T -> Bool = null):Array<FlxRect> {
		return getOverlappingTiles(rect, offset, overrideCollisionFn).map(
			function(idx) { return new FlxRect(idx.x * tileDims.x, idx.y * tileDims.y, tileDims.x, tileDims.y); });
	}
}