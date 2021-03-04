package nova.tiled;

import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Point;

import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.math.FlxPoint;
import flixel.system.debug.interaction.Interaction;
import flixel.util.typeLimit.OneOfTwo;
import nova.render.TiledBitmapData;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;

using nova.utils.ArrayUtils;
using StringTools;

class TiledMapManager {
  public var map:TiledMap;
  public var path:String;

  public var widthPerTile:Int = 0;
  public var heightPerTile:Int = 0;

  public var tilesetWidth:Int;
  public var tilesetHeight:Int;

  public var tilesetOffsets:Map<String, Int>;

  public var tilesetBitmap:TiledBitmapData;

  public function new(path:String) {
    loadTileMap(path);
    loadTileSet();
  }

  public function loadTileMap(path:String) {
    this.path = path;
    this.map = new TiledMap(path);

    var tileSeparation:Int = (this.map.properties.keys.exists('tileSeparation') ?
                              Std.parseInt(this.map.properties.keys.get('tileSeparation'))
                              : 0);
    var tileSize:Pair<Int> = (this.map.properties.keys.exists('tileSize') ?
                              this.map.properties.keys.get('tileSize').split('x').map(function(k) { return Std.parseInt(k); }) :
                              [this.map.width, this.map.height]);
    widthPerTile = tileSize.x;
    heightPerTile = tileSize.y;

    if (tileSeparation > 0) {
      var realTileDimensions:Pair<Int> = [(tileSize.x + tileSeparation) * this.map.tileWidth,
                                          (tileSize.y + tileSeparation) * this.map.tileHeight];
      var convertToLocalCoords = function(loc:Pair<Float>):Pair<Float> {
        return [loc.x - this.map.tileWidth * Std.int(loc.x / realTileDimensions.x),
                loc.y - this.map.tileHeight * Std.int(loc.y / realTileDimensions.y)];
      }

      for (layer in this.map.layers) {
        if (layer.type == TiledLayerType.TILE) {
          var tileLayer:TiledTileLayer = cast layer;

          // This is a hack to get around the insane fact that you
          // aren't allowed to modify the tileArray for some reason
          var tileArray = tileLayer.tileArray;
          var filteredArray = tileArray.filterByIndex(function(s) {
                                  var row:Int = Std.int(s / tileLayer.width);
                                  var col:Int = s % tileLayer.width;

                                  return row % (tileSize.y + tileSeparation) < tileSize.y &&
                                         col % (tileSize.x + tileSeparation) < tileSize.x;
                                });
          tileLayer.width -= Std.int(tileLayer.width / (tileSize.x + tileSeparation));
          tileLayer.height -= Std.int(tileLayer.height / (tileSize.y + tileSeparation));

          tileArray.splice(0, tileArray.length);
          for (elem in filteredArray) {
            tileArray.push(elem);
          }
        } else if (layer.type == TiledLayerType.OBJECT) {
          var objectLayer:TiledObjectLayer = cast layer;

          for (object in objectLayer.objects) {
            var newXY = convertToLocalCoords([object.x, object.y]);
            object.x = Std.int(newXY.x);
            object.y = Std.int(newXY.y);

            if (object.points != null) {
              object.points = object.points.map(function(k:FlxPoint):FlxPoint {
                return convertToLocalCoords(k);
              });
            }
          }
        }
      }
    }
  }

  public function loadTileSet() {
    tilesetHeight = 0;
    
    tilesetOffsets = new Map<String, Int>();
    for (k in this.map.tilesets.keys()) {
        tilesetOffsets.set(k, this.map.tilesets.get(k).firstGID - 1);
    }

    var tilesetKeys:Array<String> = [for (i in this.map.tilesets.keys()) i];
    tilesetKeys.sort(function(a:String, b:String):Int { 
      return (tilesetOffsets.get(a) < tilesetOffsets.get(b) ? 1 : -1);
    });

    tilesetWidth = this.map.tilesets.get(tilesetKeys[0]).numCols;

    for (tileset in tilesetKeys) {
      var src:String = this.map.tilesets.get(tileset).imageSource;
      tilesetHeight += this.map.tilesets.get(tileset).numRows;
    }

    var tilesetBitmapData = new BitmapData(tilesetWidth * this.map.tileWidth,
                                           tilesetHeight * this.map.tileHeight,
                                           true,
                                           0);

    var pointer:Int = 0;
    for (tileset in tilesetKeys) {
      var bd:BitmapData = Assets.getBitmapData(
          this.map.tilesets.get(tileset).imageSource.replace('..', 'assets')
      );
      tilesetBitmapData.copyPixels(bd, bd.rect, new Point(0, this.map.tileHeight * pointer));
      pointer += this.map.tilesets.get(tileset).numRows;
    }

    tilesetBitmap = new TiledBitmapData(tilesetBitmapData, this.map.tileWidth, this.map.tileHeight);
  }

  public function getTilesetName(index:Int):String {
    var maxIndex:Int = -1;
    var maxIndexTilesetName:String = '';
    for (k in tilesetOffsets.keys()) {
      var offset:Int = tilesetOffsets.get(k);
      if (offset <= index) {
        maxIndex = offset;
        maxIndexTilesetName = k;
      }
    }
    return maxIndexTilesetName;
  }
}
