package nova.utils;

import openfl.Assets;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Utilities for manipulating and transforming BitmapData objects.
 * Particularly useful for tile-based games.
 * 
 * @author Nathan Pinsker
 */
class BitmapDataUtils {
	public static function scaleFn(scaleX:Int, scaleY:Int):BitmapData -> BitmapData {
		return function(bitmapData:BitmapData) {
			var newBitmapData:BitmapData = new BitmapData(bitmapData.width * scaleX, bitmapData.height * scaleY, true, 0);
			var mx:Matrix = new Matrix(scaleX, 0, 0, scaleY);
			newBitmapData.draw(bitmapData, mx);

			return newBitmapData;
		}
	}
	
	public static function rotateFn(rotation:Float):BitmapData -> BitmapData {
		// Note that rotation is clockwise!
		return function(bitmapData:BitmapData) {
			var newBitmapData:BitmapData = new BitmapData(bitmapData.width, bitmapData.height, true, 0);
			var mx:Matrix = new Matrix();
			mx.translate(-bitmapData.width / 2, -bitmapData.height / 2);
			mx.rotate(rotation);
			mx.translate(bitmapData.width / 2, bitmapData.height / 2);
			newBitmapData.draw(bitmapData, mx);
			
			return newBitmapData;
		}
	}
	
	public static function horizontalStretchCenter(bitmapData:BitmapData, borderWidth:Int, targetWidth:Int):BitmapData {
		// Horizontally partitions a BitmapData into "center" and "border" sections, and stretches only the
		// border section.
		// For example, if the BitmapData is 30 pixels wide, and `borderWidth` is set to 6, then the 18 pixels
		// in the center (30 - 2*6) will be stretched.
		var resultBitmapData:BitmapData = new BitmapData(targetWidth, bitmapData.height, true, 0);
		
		var middleWidth:Int = bitmapData.width - 2 * borderWidth;
		
		var middleBitmapData:BitmapData = new BitmapData(middleWidth, bitmapData.height);
		middleBitmapData.copyPixels(bitmapData, new Rectangle(borderWidth, 0, middleWidth, bitmapData.height), new Point(0, 0));
		
		resultBitmapData.copyPixels(bitmapData, new Rectangle(0, 0, borderWidth, bitmapData.height), new Point(0, 0));
		resultBitmapData.copyPixels(bitmapData, new Rectangle(borderWidth + middleWidth, 0, borderWidth, bitmapData.height),
		                            new Point(targetWidth - borderWidth, 0));
		
		var mx:Matrix = new Matrix((targetWidth - 2 * borderWidth) / (middleWidth), 0, 0, 1);
		mx.translate(borderWidth, 0);
		resultBitmapData.draw(middleBitmapData, mx);
		return resultBitmapData;
	}
	
	public static function getSpriteFromSheetFn(sourceBitmapData:BitmapData, tileDimensions:Pair<Int>):Pair<Int> -> ?(BitmapData -> BitmapData) -> BitmapData {
		return function(tileCoords:Pair<Int>, ?transformFn:BitmapData -> BitmapData = null):BitmapData {
			var tile:BitmapData = new BitmapData(tileDimensions.x, tileDimensions.y, true, 0);
			tile.copyPixels(sourceBitmapData,
				            new Rectangle(tileCoords.x * tileDimensions.x, tileCoords.y * tileDimensions.y, tileDimensions.x, tileDimensions.y),
							new Point(0, 0));
			return (transformFn == null ? tile : transformFn(tile));
		}
	}
	
	public static function stitchSpriteSheetsFn(sourceBitmapData:BitmapData, tileDimensions:Pair<Int>):Array<Pair<Int>> -> ?(BitmapData -> BitmapData) -> ?Int -> BitmapData {
		return function(tiles:Array<Pair<Int>>, ?transformFn:BitmapData -> BitmapData = null, ?columns:Int = 0):BitmapData {
			var transformedBitmapData:Array<BitmapData> = new Array<BitmapData>();
			var getSpriteFn = getSpriteFromSheetFn(sourceBitmapData, tileDimensions);

			for (i in 0...tiles.length) {
				var tileCoords = tiles[i];
				if (tileCoords.x >= 0 && tileCoords.y >= 0) {
					transformedBitmapData.push(getSpriteFn(tileCoords, transformFn));
				} else {
					var transparentBD:BitmapData = new BitmapData(tileDimensions.x, tileDimensions.y, true, 0);
					if (transformFn != null) {
						transparentBD = transformFn(transparentBD);
					}
					transformedBitmapData.push(transparentBD);
				}
			}
			
			var returnBitmapData:BitmapData;
			if (columns == 0) {
				returnBitmapData = new BitmapData(transformedBitmapData[0].width * tiles.length, transformedBitmapData[0].height, true, 0);
			} else {
				returnBitmapData = new BitmapData(transformedBitmapData[0].width * columns,
				                                  transformedBitmapData[0].height * Math.ceil(tiles.length / columns - 0.0001),
												  true, 0);
			}
			var intPairFromColumn:Int -> Pair<Int> = intToIntPairFn(columns);
			for (i in 0...transformedBitmapData.length) {
				var transformedTile:BitmapData = transformedBitmapData[i];
				var pointCoords = intPairFromColumn(i);
				returnBitmapData.copyPixels(transformedTile,
				                            transformedTile.rect,
											new Point(pointCoords.x * transformedBitmapData[0].width, pointCoords.y * transformedBitmapData[0].height));
			}
			return returnBitmapData;
		}
	}
	
	public static function intToIntPairFn(columns:Int):Int -> Pair<Int> {
		return function(id:Int) {
			if (columns == 0) {
				return [id, 0];
			}
			return [id % columns, Std.int(id / columns)];
		}
	}
	
	public static function loadFromObject(object:Dynamic):BitmapData {
		if (!Reflect.hasField(object, 'image')) {
			trace("Error: object " + object + " has no `image` field!");
			return null;
		}
		var toReturn:BitmapData = Assets.getBitmapData(object.image);
		if (Reflect.hasField(object, 'transform')) {
			toReturn = object.transform(toReturn);
		}
		return toReturn;
	}
}