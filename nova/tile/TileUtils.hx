package nova.tile;

import flixel.math.FlxRect;
import nova.utils.ArrayUtils;
import nova.utils.Pair;
import openfl.geom.Rectangle;

/**
 * Utility methods for working with tiles and tilemaps,
 * including methods for dealing with tile collisions.
 */

class TileUtils {
  @:deprecated
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
		if (endX >= tiles[0].length) endX = tiles[0].length;
		if (startY < 0) startY = 0;
		if (endY >= tiles.length) endY = tiles.length;
		
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
  @:deprecated
	public static function horizontalNudgeOutOfObjects(collisionRects:Array<FlxRect>, rect:FlxRect, ?maxNudge:Float = 6):Float {
		var canNudgeLeft:Bool = true;
		var canNudgeRight:Bool = true;
		for (collisionRect in collisionRects) {
			if (collisionRect.x + collisionRect.width > rect.x && collisionRect.y + collisionRect.height > rect.y &&
			    rect.x + rect.width > collisionRect.x && rect.y + rect.height > collisionRect.y) {
				var candidateLeft = rect.x + rect.width - collisionRect.x;
				var candidateRight = collisionRect.x + collisionRect.width - rect.x;
				
				if (candidateLeft > maxNudge) canNudgeLeft = false;
				if (candidateRight > maxNudge) canNudgeRight = false;
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
	
  @:deprecated
	public static function verticalNudgeOutOfObjects(collisionRects:Array<FlxRect>, rect:FlxRect, ?maxNudge:Float = 6):Float {
		var canNudgeUp:Bool = true;
		var canNudgeDown:Bool = true;
		for (collisionRect in collisionRects) {
			if (collisionRect.x + collisionRect.width > rect.x && collisionRect.y + collisionRect.height > rect.y &&
			    rect.x + rect.width > collisionRect.x && rect.y + rect.height > collisionRect.y) {
				var candidateUp = rect.y + rect.height - collisionRect.y;
				var candidateDown = collisionRect.y + collisionRect.height - rect.y;
				
				if (candidateUp > maxNudge) canNudgeUp = false;
				if (candidateDown > maxNudge) canNudgeDown = false;
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
	
  @:deprecated
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
