package nova.tile;

import flixel.math.FlxRect;
import nova.utils.ArrayUtils;
import nova.utils.Pair;
import openfl.geom.Rectangle;

/**
 * Utility methods for working with tiles and tilemaps.
 * 
 * @author Nathan Pinsker
 */

class TileUtils {
	public static function nudgeIntoBounds<T>(tiles:Array<Array<T>>, rect:FlxRect,
	                                          testCollisionFn:T -> Bool,
	                                          offset:Pair<Float>,
	                                          tileDims:Pair<Int>):Pair<Float> {
		var nudgeX:Float = 0;
		var nudgeY:Float = 0;
		var nudged:Bool = false;
		
		var startX:Int = Math.floor((rect.x - offset.x) / tileDims.x - 0.01);
		var endX:Int = Math.ceil((rect.x + rect.width - offset.x) / tileDims.x + 0.01);
		var startY:Int = Math.floor((rect.y - offset.y) / tileDims.y - 0.01);
		var endY:Int = Math.ceil((rect.y + rect.height - offset.y) / tileDims.y + 0.01);
		
		if (startX < 0) startX = 0;
		if (endX >= tiles[0].length) endX = tiles[0].length - 1;
		if (startY < 0) startY = 0;
		if (endY >= tiles.length) endY = tiles.length - 1;
		
		for (y in startY...endY) {
			for (x in startX...endX) {
				var tileStart:Pair<Float> = offset + [x * tileDims.first, y * tileDims.second];
				
				if (tileStart.x + tileDims.x > rect.x && tileStart.y + tileDims.y > rect.y &&
				    rect.x + rect.width > tileStart.x && rect.y + rect.height > tileStart.y && testCollisionFn(tiles[y][x])) {
					nudged = true;

					var nudgeLeft:Float = (rect.x + rect.width) - tileStart.x;
					var nudgeRight:Float = (tileStart.x + tileDims.x) - rect.x;
					var nudgeUp:Float = (rect.y + rect.height) - tileStart.y;
					var nudgeDown:Float = (tileStart.y + tileDims.y) - rect.y;
					
					if (x > 0 && testCollisionFn(tiles[y][x - 1])) {
						nudgeLeft += tileDims.first;
					}
					if (x < tiles[0].length - 1 && testCollisionFn(tiles[y][x + 1])) {
						nudgeRight += tileDims.first;
					}
					
					var best = ArrayUtils.min([nudgeLeft, nudgeRight, nudgeUp, nudgeDown]);
					
					if (Math.abs(best - nudgeLeft) <= 1e-6) {
						nudgeX -= nudgeLeft;
						rect.x -= nudgeLeft;
					} else if (Math.abs(best - nudgeRight) <= 1e-6) {
						nudgeX += nudgeRight;
						rect.x += nudgeRight;
					} else if (Math.abs(best - nudgeUp) <= 1e-6) {
						nudgeY -= nudgeUp;
						rect.y -= nudgeUp;
					} else {
						nudgeY += nudgeDown;
						rect.y += nudgeDown;
					}
				}
			}
		}
		if (!nudged) {
			return [0, 0];
		}
		return [nudgeX, nudgeY];
	}
	
	public static function nudgeOutOfObjects(collisionRects:Array<FlxRect>, rect:FlxRect):Pair<Float> {
		var nudgeX:Float = 0;
		var nudgeY:Float = 0;
		var nudged:Bool = false;
		var borderedLeft:Bool = false;
		var borderedRight:Bool = false;
		for (collisionRect in collisionRects) {
			if (collisionRect.x + collisionRect.width > rect.x && collisionRect.y + collisionRect.height > rect.y &&
			    rect.x + rect.width > collisionRect.x && rect.y + rect.height > collisionRect.y) {
				if (rect.x > collisionRect.x) {
					borderedLeft = true;
				}
				if (rect.x + rect.width < collisionRect.x + collisionRect.width) {
					borderedRight = true;
				}
			}
		}
		for (collisionRect in collisionRects) {
			if (collisionRect.x + collisionRect.width > rect.x && collisionRect.y + collisionRect.height > rect.y &&
			    rect.x + rect.width > collisionRect.x && rect.y + rect.height > collisionRect.y) {
				nudged = true;
				var nudgeLeft:Float = (rect.x + rect.width) - collisionRect.x;
				var nudgeRight:Float = (collisionRect.x + collisionRect.width) - rect.x;
				var nudgeUp:Float = (rect.y + rect.height) - collisionRect.y;
				var nudgeDown:Float = (collisionRect.y + collisionRect.height) - rect.y;
				
				if (borderedLeft) {
					nudgeLeft += 100;
				}
				if (borderedRight) {
					nudgeRight += 100;
				}
				
				var best = ArrayUtils.min([nudgeLeft, nudgeRight, nudgeUp, nudgeDown]);
				
				if (Math.abs(best - nudgeLeft) <= 1e-6) {
					nudgeX -= nudgeLeft;
					rect.x -= nudgeLeft;
				} else if (Math.abs(best - nudgeRight) <= 1e-6) {
					nudgeX += nudgeRight;
					rect.x += nudgeRight;
				} else if (Math.abs(best - nudgeUp) <= 1e-6) {
					nudgeY -= nudgeUp;
					rect.y -= nudgeUp;
				} else {
					nudgeY += nudgeDown;
					rect.y += nudgeDown;
				}
			}
		}
		if (!nudged) {
			return [0, 0];
		}
		return [nudgeX, nudgeY];
	}
}