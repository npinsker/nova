package nova;

import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import flixel.tile.FlxTilemap;
import openfl.Assets;

using StringTools;

class HalfTileFitMap extends FlxTilemap {
    public var Map:Array<Int>;
    public var mainChunkSquares:Array<Int>;

    public var MapWidth:Int;
    public var MapHeight:Int;
    public var PercentAreWalls:Int;
    public var mode:Int;
    public var builtMap:Bool = false;

    public var MIN_PATHABLE_SQUARES:Int = 200;

    private var _raw_data: Array<Array<Int>>;

    public function new():Void {
        super();
    }
    public function loadHalfTileMapFromCSV(MapData:String) {
        if (Assets.exists(MapData)) {
            MapData = Assets.getText(MapData);
        }

        // Figure out the map dimensions based on the data string
        _raw_data = new Array<Array<Int>>();
        _data = new Array<Int>();
        var columns:Array<String>;

        var regex:EReg = new EReg("[ \t]*((\r\n)|\r|\n)[ \t]*", "g");
        var lines:Array<String> = regex.split(MapData);
        var rows:Array<String> = lines.filter(function(line) return line != "");

        heightInTiles = rows.length;
        widthInTiles = 0;

        var row:Int = 0;
        while (row < heightInTiles) {
            _raw_data.push(new Array<Int>());
            var rowString = rows[row];
            if (rowString.endsWith(","))
                rowString = rowString.substr(0, rowString.length - 1);
            columns = rowString.split(",");

            if (columns.length == 0) {
                heightInTiles--;
                continue;
            }
            if (widthInTiles == 0) {
                widthInTiles = columns.length;
            }

            var column = 0;
            while (column < widthInTiles) {
                //the current tile to be added:
                var columnString = columns[column];
                var curTile = Std.parseInt(columnString);

                if (curTile == null)
                    throw 'String in row $row, column $column is not a valid integer: "$columnString"';

                if (curTile < 0) {
                    curTile = 0;
                }

                _raw_data[row].push(curTile);
                column++;
            }
            row++;
        }
        widthInTiles *= 2;
        heightInTiles *= 2;

        for (y in 0...2 * _raw_data.length) {
            for (x in 0...2 * _raw_data[0].length) {
                var tileCode:Int = 15;  // empty tile
                if (!isHalfTileSolid(x, y)) {
                    var occupiedNW:Bool = isHalfTileSolid(x - 1, y - 1);
                    var occupiedNE:Bool = isHalfTileSolid(x + 1, y - 1);
                    var occupiedSW:Bool = isHalfTileSolid(x - 1, y + 1);
                    var occupiedSE:Bool = isHalfTileSolid(x + 1, y + 1);

                    if (isHalfTileSolid(x - 1, y)) {
                        occupiedNW = occupiedSW = true;
                    }
                    if (isHalfTileSolid(x + 1, y)) {
                        occupiedNE = occupiedSE = true;
                    }
                    if (isHalfTileSolid(x, y - 1)) {
                        occupiedNW = occupiedNE = true;
                    }
                    if (isHalfTileSolid(x, y + 1)) {
                        occupiedSW = occupiedSE = true;
                    }

                    tileCode =  (occupiedNW ? 1 : 0) +
                            2 * (occupiedNE ? 1 : 0) +
                            4 * (occupiedSW ? 1 : 0) +
                            8 * (occupiedSE ? 1 : 0);
                }
                _data.push(tileCode);
            }
        }
    }

    public function drawMapFromAsset(TileGraphic:FlxTilemapGraphicAsset, TileWidth:Int = 0, TileHeight:Int = 0,
                                     StartingIndex:Int = 0, DrawIndex:Int = 0, CollideIndex:Int = 1) {
        // This assumes the data is already loaded into _data!
        loadMapHelper(TileGraphic, TileWidth, TileHeight, flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling.OFF, StartingIndex, DrawIndex, CollideIndex);
        return this;
    }

    public function isHalfTileSolid(x:Int, y:Int):Bool {
        if (x < 0 || y < 0 || y >= 2 * _raw_data.length || x >= 2 * _raw_data[0].length) {
            return true;
        }
        return _raw_data[Std.int(y / 2)][Std.int(x / 2)] > 0;
    }
}
