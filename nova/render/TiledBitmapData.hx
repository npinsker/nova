package nova.render;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.typeLimit.OneOfTwo;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;

/**
 * A class for working with bitmaps that represent sets of tiles.
 */
class TiledBitmapData {
	public var graphic:FlxGraphic;
	public var tileWidth:Int;
	public var tileHeight:Int;

	public var numRows:Int;
	public var numColumns:Int;
	public var transform:BitmapData -> BitmapData;

	public function new(graphicAsset:FlxGraphicAsset, tileWidth:Int = 0, tileHeight:Int = 0, ?transform:BitmapData -> BitmapData = null) {
		graphic = FlxG.bitmap.add(graphicAsset);
		if (graphic == null) {
			return null;
		}

		this.tileWidth = (tileWidth == 0 ? graphic.bitmap.width : tileWidth);
		this.tileHeight = (tileHeight == 0 ? graphic.bitmap.height : tileHeight);
		this.transform = transform;

		numColumns = Std.int(graphic.bitmap.width / tileWidth);
		numRows = Std.int(graphic.bitmap.height / tileHeight);
	}

	/**
	 * Returns a `BitmapData` of the tile at the given coordinates.
	 * @param	coords Either an integer or a pair of integers designating the tile.
	 * If an integer is supplied, then it will be parsed as a tile by numbering the tiles in book-reading order.
	 * @return A `BitmapData` of the tile at those coordinates.
	 */
	public function getTile(coords:OneOfTwo<Int, Pair<Int>>):BitmapData {
		var pairCoords:Pair<Int> = BitmapDataUtils.toIntPairFn(numColumns)(coords);

		var tile:BitmapData = new BitmapData(tileWidth, tileHeight);
		tile.copyPixels(graphic.bitmap, new Rectangle(pairCoords.x * tileWidth,
		                                              pairCoords.y * tileHeight,
													  tileWidth,
													  tileHeight),
				        new Point(0, 0));

		if (transform == null) {
			return tile;
		}
		return transform(tile);
	}

	/**
	 * 
	 * @param	coords An array of tiles to stitch into a BitmapData. Each coordinate is specified
	 * in the same way as in `getTile`.
	 * @return A BitmapData consisting of all requested tiles, horizontally stitched into a single
	 * `BitmapData` object having dimensions `(tileWidth * coords.length, tileHeight)`.
	 */
	public function stitchTiles(coords:Array<OneOfTwo<Int, Pair<Int>>>):BitmapData {
		var pairCoords:Array<Pair<Int>> = coords.map(BitmapDataUtils.toIntPairFn(numColumns));

		var tile:BitmapData = new BitmapData(coords.length * tileWidth, tileHeight);

		for (i in 0...coords.length) {
			tile.copyPixels(graphic.bitmap, new Rectangle(pairCoords[i].x * tileWidth,
														  pairCoords[i].y * tileHeight,
														  tileWidth,
														  tileHeight),
							new Point(i * tileWidth, 0));
		}
		if (transform == null) {
			return tile;
		}
		return transform(tile);
	}
}
