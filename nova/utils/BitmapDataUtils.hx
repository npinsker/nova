package nova.utils;

import flixel.FlxSprite;
import flixel.util.typeLimit.OneOfTwo;
import nova.render.TiledBitmapData;
import openfl.Assets;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Utilities for manipulating and transforming BitmapData objects.
 * Particularly useful for tile-based games.
 */
class BitmapDataUtils {
	/**
	 * A function that generates a BitmapData scaling function.
	 * 
	 * @param	scaleX The amount to scale the BitmapData by horizontally.
	 * @param	scaleY The amount to the scale the BitmapData by vertically.
	 * @return A function that scales an input BitmapData by `(scaleX, scaleY)`.
	 */
	public static function scaleFn(scaleX:Int, scaleY:Int):BitmapData -> BitmapData {
		return function(bitmapData:BitmapData) {
			var newBitmapData:BitmapData = new BitmapData(bitmapData.width * scaleX, bitmapData.height * scaleY, true, 0);
			var mx:Matrix = new Matrix(scaleX, 0, 0, scaleY);
			newBitmapData.draw(bitmapData, mx);

			return newBitmapData;
		}
	}
	
	/**
	 * A function that generates a BitmapData rotation function.
	 * 
	 * @param	rotation The amount to rotate the BitmapData by, counterclockwise.
	 * @return A function that rotates an input BitmapData by `rotation` radians.
	 */
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
	
	/**
	 * Flips a BitmapData along the specified axis.
	 * 
	 * @param	bitmapData The bitmap to flip.
	 * @param	axis A string which visually represents the axis to flip upon. Should be '-', '|', '/', or '\'.
	 * @return The bitmap flipped along that axis.
	 */
	public static function flip(bitmapData:BitmapData, axis:String):BitmapData {
		if (['-', '|', '/', '\\'].indexOf(axis) == -1) {
			throw 'Invalid axis ' + axis + ' for flipping BitmapData!';
		}
		if (axis == '-' || axis == '|') {
			var newBitmapData:BitmapData = new BitmapData(bitmapData.width, bitmapData.height, true, 0);
			
			var mx:Matrix = new Matrix();
			mx.translate( -bitmapData.width / 2, -bitmapData.height / 2);
			if (axis == '-') {
				mx.d *= -1;
				mx.ty *= -1;
			} else {
				mx.a *= -1;
				mx.tx *= -1;
			}
			mx.translate(bitmapData.width / 2, bitmapData.height / 2);
			newBitmapData.draw(bitmapData, mx);
			return newBitmapData;
		}
		
		var newBitmapData:BitmapData = new BitmapData(bitmapData.height, bitmapData.width, true, 0);
	
		var mx:Matrix = new Matrix();
		if (axis == '/') {
			mx.tx = bitmapData.height;
			mx.ty = bitmapData.width;
			mx.a = 0;
			mx.b = -1;
			mx.c = -1;
			mx.d = 0;
		} else {
			mx.a = 0;
			mx.b = 1;
			mx.c = 1;
			mx.d = 0;
		}
		newBitmapData.draw(bitmapData, mx);
		return newBitmapData;
	}
	
	/**
	 * Horizontally partitions a BitmapData into "center" and "border" sections, and stretches only the
	 * border section.
	 * For example, if the BitmapData is 30 pixels wide, and `borderWidth` is set to 6, then the 18 pixels
	 * in the center (30 - 2*6) will be stretched.
	 * @param	bitmapData The bitmap to be stretched.
	 * @param	borderWidth The number of pixels on each side that should not be stretched.
	 * @param	targetWidth The number of pixels the output image should be.
	 * @return The input bitmap, horizontally stretched to `targetWidth` pixels.
	 */
	public static function horizontalStretchCenter(bitmapData:BitmapData, borderWidth:Int, targetWidth:Int):BitmapData {
		var resultBitmapData:BitmapData = new BitmapData(targetWidth, bitmapData.height, true, 0);
		
		var middleWidth:Int = bitmapData.width - 2 * borderWidth;
		
		var middleBitmapData:BitmapData = new BitmapData(middleWidth, bitmapData.height, true, 0);
		middleBitmapData.copyPixels(bitmapData, new Rectangle(borderWidth, 0, middleWidth, bitmapData.height), new Point(0, 0));
		
		resultBitmapData.copyPixels(bitmapData, new Rectangle(0, 0, borderWidth, bitmapData.height), new Point(0, 0));
		resultBitmapData.copyPixels(bitmapData, new Rectangle(borderWidth + middleWidth, 0, borderWidth, bitmapData.height),
		                            new Point(targetWidth - borderWidth, 0));
		
		var mx:Matrix = new Matrix((targetWidth - 2 * borderWidth) / (middleWidth), 0, 0, 1);
		mx.translate(borderWidth, 0);
		resultBitmapData.draw(middleBitmapData, mx);
		return resultBitmapData;
	}
	
	/**
	 * Same as `horizontalStretchCenter`, except operates vertically instead of horizontally.
	 */
	public static function verticalStretchCenter(bitmapData:BitmapData, borderHeight:Int, targetHeight:Int):BitmapData {
		var resultBitmapData:BitmapData = new BitmapData(bitmapData.width, targetHeight, true, 0);
		
		var middleHeight:Int = bitmapData.height - 2 * borderHeight;
		
		var middleBitmapData:BitmapData = new BitmapData(bitmapData.width, middleHeight);
		middleBitmapData.copyPixels(bitmapData, new Rectangle(0, borderHeight, bitmapData.width, middleHeight), new Point(0, 0));
		
		resultBitmapData.copyPixels(bitmapData, new Rectangle(0, 0, bitmapData.width, borderHeight), new Point(0, 0));
		resultBitmapData.copyPixels(bitmapData, new Rectangle(0, borderHeight + middleHeight, bitmapData.width, borderHeight),
		                            new Point(0, targetHeight - borderHeight));
		
		var mx:Matrix = new Matrix(1, 0, 0, (targetHeight - 2 * borderHeight) / (middleHeight));
		mx.translate(0, borderHeight);
		resultBitmapData.draw(middleBitmapData, mx);
		return resultBitmapData;
	}
	
	@:deprecated
	public static function getSpriteFromSheetFn(sourceBitmapData:BitmapData, tileDimensions:Pair<Int>):Pair<Int> -> ?(BitmapData -> BitmapData) -> BitmapData {
		return function(tileCoords:Pair<Int>, ?transformFn:BitmapData -> BitmapData = null):BitmapData {
			var tile:BitmapData = new BitmapData(tileDimensions.x, tileDimensions.y, true, 0);
			tile.copyPixels(sourceBitmapData,
				            new Rectangle(tileCoords.x * tileDimensions.x, tileCoords.y * tileDimensions.y, tileDimensions.x, tileDimensions.y),
							new Point(0, 0));
			return (transformFn == null ? tile : transformFn(tile));
		}
	}
	
	@:deprecated
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
	
	/**
	 * Crops and returns the input bitmap.
	 * @param	bitmapData The input bitmap.
	 * @param	point The upper-left corner of the area to crop.
	 * @param	dims The dimensions of the area to crop, expressed as `[width, height]`.
	 * @return  A BitmapData corresponding to the cropped area of the input bitmap.
	 */
	public static function crop(bitmapData:BitmapData, point:Pair<Int>, dims:Pair<Int>):BitmapData {
		var newBitmapData:BitmapData = new BitmapData(dims.x, dims.y);
		newBitmapData.copyPixels(bitmapData, new Rectangle(point.x, point.y, point.x + dims.x, point.y + dims.y), new Point(0, 0));
		return newBitmapData;
	}
	
	@:deprecated
	public static function intToIntPairFn(columns:Int):Int -> Pair<Int> {
		if (columns == 0) {
			return function(id:Int) {
				return [id, 0];
			}
		}
		return function(id:Int) {
			return [id % columns, Std.int(id / columns)];
		}
	}
	
	public static function toIntPairFn(columns:Int):OneOfTwo<Int, Pair<Int>> -> Pair<Int> {
		if (columns == 0) {
			return function(id:OneOfTwo<Int, Pair<Int>>):Pair<Int> {
				if (Std.is(id, Int)) {
					return [id, 0];
				}
				return id;
			}
		}
		return function(id:OneOfTwo<Int, Pair<Int>>):Pair<Int> {
			if (Std.is(id, Int)) {
				return [id % columns, Std.int(id / columns)];
			}
			return id;
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

	public static function loadTilesFromObject(object:Dynamic):TiledBitmapData {
		if (!Reflect.hasField(object, 'image')) {
			trace("Error: object " + object + " has no `image` field!");
			return null;
		}
		var tileWidth = 0;
		var tileHeight = 0;
		if (Reflect.hasField(object, 'width')) tileWidth = object.width;
		if (Reflect.hasField(object, 'tileWidth')) tileWidth = object.tileWidth;
		if (Reflect.hasField(object, 'height')) tileHeight = object.height;
		if (Reflect.hasField(object, 'tileHeight')) tileHeight = object.tileHeight;
		
		return new TiledBitmapData(object.image, tileWidth, tileHeight, StructureUtils.prop(object, 'transform'));
	}
}