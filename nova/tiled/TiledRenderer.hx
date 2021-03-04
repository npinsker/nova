package nova.tiled;

import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.system.debug.interaction.Interaction;
import flixel.util.typeLimit.OneOfTwo;
import nova.render.TiledBitmapData;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using StringTools;

typedef TiledRendererOptions = {
	@:optional var layersToSkip:Array<String>;
};

/**
 * Renders sprites based on information contained within a Tiled map.
 * 
 * Stores a Tiled map as input, and can render sprites based on the contents of
 * a TiledObjectSet.
 */
class TiledRenderer {
	public var tilesetOffsets:Map<String, Int>;
	public var scaleFn:BitmapData -> BitmapData;
	public var tileset:TiledBitmapData;
	public var map:TiledMap;

	public function new(map:TiledMap, ?scaleFn:Pair<Int>) {
		this.map = map;
		this.scaleFn = (scaleFn != null ? BitmapDataUtils.scaleFn(scaleFn.x, scaleFn.y) : null);

		var tilesetKeys:Array<String> = [for (i in map.tilesets.keys()) i];
        tilesetKeys.sort(function(a:String, b:String):Int {
			return (map.tilesets.get(a).firstGID < map.tilesets.get(b).firstGID ? -1 : 1);
		});
		
		var heightInTiles:Int = 0;
		var pointer:Int = 0;
		var tilesetWidth:Int = 0;
		
		tilesetOffsets = new Map<String, Int>();
		for (tileset in tilesetKeys) {
			var src:String = map.tilesets.get(tileset).imageSource;
			var numCols = map.tilesets.get(tileset).numCols;

			tilesetOffsets.set(src.substring(src.lastIndexOf('/') + 1, src.lastIndexOf('.')), numCols * heightInTiles);
			heightInTiles += map.tilesets.get(tileset).numRows;
			
			if (tilesetWidth != 0 && tilesetWidth != numCols) {
				throw 'All tilesets must have the same width to be stitched!';
			}
			tilesetWidth = numCols;
		}

		var tilesetBitmap = new BitmapData(tilesetWidth * map.tileWidth, heightInTiles * map.tileHeight, true, 0);
		for (tileset in tilesetKeys) {
			var bd:BitmapData = Assets.getBitmapData(map.tilesets.get(tileset).imageSource.replace('..', 'assets'));
			tilesetBitmap.copyPixels(bd, bd.rect, new Point(0, map.tileHeight * pointer));
			pointer += map.tilesets.get(tileset).numRows;
		}

		tileset = new TiledBitmapData(tilesetBitmap, map.tileWidth, map.tileHeight);
	}
	
	public function renderTile(code:OneOfTwo<Int, Pair<Int>>):BitmapData {
		if (scaleFn != null) {
			return scaleFn(tileset.getTile(code));
		}
		return tileset.getTile(code);
	}
	
	public function renderObject(object:Dynamic):BitmapData {
		if (!Reflect.hasField(object, 'frames')) {
			if (scaleFn != null) {
				return scaleFn(tileset.stitchTiles(object.tiles, object.columns));
			}
			return tileset.stitchTiles(object.tiles, object.columns);
		}

		var frames:Int = object.frames;
		var tiles:Array<Int> = object.tiles;
		var columns:Int = object.columns;
		var objectWidth:Int = (Reflect.hasField(object, 'columns') ? frames * columns : tiles.length);
		var targetBitmapData:BitmapData = new BitmapData(objectWidth * tileset.tileWidth, Std.int(tiles.length / objectWidth * tileset.tileHeight));
		for (i in 0...frames) {
			var tileSlice:Array<Int> = tiles.slice(i * Std.int(tiles.length / frames), (i + 1) * Std.int(tiles.length / frames));
			var render:BitmapData = tileset.stitchTiles(cast tileSlice, object.columns);
			targetBitmapData.copyPixels(render, render.rect, new Point(i * render.width, 0));
		}
		if (scaleFn != null) {
			return scaleFn(targetBitmapData);
		}
		return targetBitmapData;
	}

	public function renderStaticScreen(bounds:Array<Int>,
	                                   objectLoader:TiledObjectLoader,
                                     ?options:TiledRendererOptions = null):BitmapData {
		var tileWidth = bounds[2];
		var tileHeight = bounds[3];
		var returnBitmapData = new BitmapData(objectLoader.tileDimensions.x * tileWidth, objectLoader.tileDimensions.y * tileHeight, true, 0);
		
		for (row in 0...tileHeight) {
			for (col in 0...tileWidth) {
				var trueRow = row + bounds[1];
				var trueCol = col + bounds[0];
				for (layer in map.layers) {
					if (layer.type != TiledLayerType.TILE) continue;
          if (options != null && options.layersToSkip != null && options.layersToSkip.indexOf(layer.name) != -1) {
            continue;
          }

					var tileLayer = cast(layer, TiledTileLayer);
					var id = tileLayer.tileArray[trueRow * tileLayer.width + trueCol] - 1;

					if (id == -1) {
						continue;
					}
					if (objectLoader != null && objectLoader.objectTiles.exists(id)) {
						continue;
					}

					var renderedTileRect = tileset.getTileRect(id);
					returnBitmapData.copyPixels(tileset.graphic.bitmap, renderedTileRect,
												new Point(col * objectLoader.tileDimensions.x, row * objectLoader.tileDimensions.y),
												null, null, true);
				}
			}
		}

		if (scaleFn != null) {
			return scaleFn(returnBitmapData);
		}
		return returnBitmapData;
	}
}
