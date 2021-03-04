package nova.tiled;

import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.math.FlxRect;
import nova.utils.ArrayUtils;
import nova.utils.Pair;
import nova.utils.StructureUtils;

class NovaTiledObject {
  public var id:Int;
	public var name:String;
	public var layer:String;
	public var type:String;
	public var properties:Map<String, String>;

	public function readPropertiesFrom(src:TiledObject) {
		if (src.xmlData.hasNode.properties) {
			for (property in src.xmlData.node.properties.nodes.property) {
			  properties.set(property.att.name, property.att.value);
			}
		}
		layer = src.layer.name;

    id = Std.parseInt(src.xmlData.att.id);

		var objectName:String = (src.name == '' ? '__id_'  + src.xmlData.att.id : src.name);
		name = objectName;
		properties.set('name', objectName);

		type = src.type;
		properties.set('type', type);
	}
}

class PointObject extends NovaTiledObject {
	public var position:Pair<Float>;
	
	public function new(position:Pair<Float>) {
		this.position = position;
		this.name = '';
		this.properties = new Map<String, String>();
	}
}

class RegionObject extends NovaTiledObject {
    public var rect:FlxRect;

    public function new(rect:FlxRect) {
		this.rect = rect;
		this.properties = new Map<String, String>();
    }
}

class PolylineObject extends NovaTiledObject {
    public var points:Array<Pair<Float>>;

    public function new(points:Array<Pair<Float>>) {
		this.points = points;
		this.properties = new Map<String, String>();
    }
}

class TiledObjectSet {
	public var polylines:Map<String, PolylineObject>;
	public var points:Map<String, PointObject>;
	public var regions:Map<String, RegionObject>;
	public var entities:Array<Dynamic>;
	
	public function new() {
		polylines = new Map<String, PolylineObject>();
		points = new Map<String, PointObject>();
		regions = new Map<String, RegionObject>();
		entities = [];
	}
}

typedef TiledObjectLoaderOptions = {
	@:optional var tilesPerScreen:Pair<Int>;
	@:optional var layers:Array<String>;
	@:optional var layersToSkip:Array<String>;
};

class TiledObjectLoader {
	public var idToObject:Map<String, Map<Int, Dynamic>>;
	public var objectTiles:Map<Int, Int>;
	public var tilesetOffsets:Map<String, Int>;
	public var tileDimensions:Pair<Int>;
	public var tilesPerScreen:Pair<Int>;
	
	private var _topLeftCoordinates:Pair<Int>;

	public function new(idToObject:Map<String, Map<Int, Dynamic>>,
						tilesetOffsets:Map<String, Int>,
						?tileDimensions:Pair<Int> = null) {
		this.idToObject = idToObject;
		this.tilesetOffsets = tilesetOffsets;
		this.tileDimensions = (tileDimensions != null ? tileDimensions : [16, 16]);
		this._topLeftCoordinates = [0, 0];
		
		
		this.objectTiles = new Map<Int, Int>();
		for (tilesetKey in idToObject.keys()) {
      if (!tilesetOffsets.exists(tilesetKey)) continue;

			var tileset = (idToObject.exists(tilesetKey) ? idToObject.get(tilesetKey) : new Map<Int, Dynamic>());
			var offset = tilesetOffsets.get(tilesetKey);
			for (key in tileset.keys()) {
                if (Reflect.hasField(tileset.get(key), 'tiles') && !Reflect.hasField(tileset.get(key), 'skipDeleteOtherFrames')) {
                  var tiles:Array<Int> = tileset.get(key).tiles;
                  for (tile in tiles) {
                    if (tile != -1) {
                      objectTiles.set(tile + offset, key + offset);
                    }
                  }
                } else {
                  objectTiles.set(key + offset, key + offset);
                }
			}
		}
		
		setScreenParameters(null);
	}
	
	public function setScreenParameters(tilesPerScreen:Pair<Int> = null) {
		this.tilesPerScreen = tilesPerScreen;
	}
	
	public function loadPolyline(object:TiledObject, set:TiledObjectSet):Void {
		var objectName:String = (object.name == '' ? object.xmlData.att.id : object.name);
		var pointsStr:String = object.xmlData.node.polyline.att.points;
		var originX:Float = Std.parseFloat(object.xmlData.att.x);
		var originY:Float = Std.parseFloat(object.xmlData.att.y);
		
		var polyline:PolylineObject = new PolylineObject(
			pointsStr.split(' ').map(
			    function(s:String):Pair<Float> {
				    var a = s.split(',');
            return [originX + Std.parseFloat(a[0]) - tileDimensions.x * _topLeftCoordinates.x,
                    originY + Std.parseFloat(a[1]) - tileDimensions.y * _topLeftCoordinates.y];
			    }
			));

		polyline.readPropertiesFrom(object);
		set.polylines.set(polyline.name, polyline);
	}
	
	public function loadRegion(object:TiledObject, set:TiledObjectSet):Void {
		var r = object.xmlData.att;
		var rect:FlxRect = new FlxRect(object.x - tileDimensions.x * _topLeftCoordinates.x,
                                   object.y - tileDimensions.y * _topLeftCoordinates.y,
                                   Std.parseFloat(r.width),
                                   Std.parseFloat(r.height));

		var region:RegionObject = new RegionObject(rect);
		region.readPropertiesFrom(object);
		set.regions.set(region.name, region);
	}
	
	public function loadObjects(map:TiledMap,
								bounds:Array<Int>,
								?options:TiledObjectLoaderOptions = null):TiledObjectSet {
		var set:TiledObjectSet = new TiledObjectSet();

		var objectSet:Array<Dynamic> = new Array<Dynamic>();
		var annotationSet:Array<PointObject> = new Array<PointObject>();
		
		if (options != null) {
			setScreenParameters(options.tilesPerScreen);
		}
		
		for (layer in map.layers) {
			if (options != null && options.layers != null && options.layers.indexOf(layer.name) == -1) {
				continue;
			} else if (options != null && options.layersToSkip != null && options.layersToSkip.indexOf(layer.name) != -1) {
				continue;
			}
			if (Std.is(layer, TiledObjectLayer)) {
				loadFromObjectLayer(cast(layer, TiledObjectLayer), bounds, set, annotationSet);
			}
		}
		
		objectSet = [for (i in set.entities) i];
		
		for (layer in map.layers) {
			if (options != null && options.layers != null && options.layers.indexOf(layer.name) == -1) {
				continue;
			} else if (options != null && options.layersToSkip != null && options.layersToSkip.indexOf(layer.name) != -1) {
				continue;
			}
			if (Std.is(layer, TiledTileLayer)) {
				loadFromTileLayer(cast(layer, TiledTileLayer), bounds, set, objectSet);
			}
		}
		
		for (object in set.entities) {
            if (object._loadedFromObject) {
                continue;
            }

			for (annotation in annotationSet) {
				if (object.x == annotation.position.x && object.y == annotation.position.y) {
					for (prop in annotation.properties.keys()) {
						if (prop != 'type') {
							Reflect.setField(object, prop, annotation.properties.get(prop));
						}
					}
				}
			}
		}
		
		return set;
	}

	public function loadFromObjectLayer(tileLayer:TiledObjectLayer,
										bounds:Array<Int>,
										set:TiledObjectSet,
										annotationSet:Array<PointObject>) {
		_topLeftCoordinates = [bounds[0], bounds[1]];
    
		for (object in tileLayer.objects) {
			var xml:Xml = object.xmlData.x;
			var coords:Pair<Float> = [object.x, object.y - tileDimensions.y];
      if (!object.xmlData.has.gid) {
        coords.y += tileDimensions.y;
      }

			if (coords.x < _topLeftCoordinates.x * tileDimensions.x ||
			    coords.x > (_topLeftCoordinates.x + bounds[2]) * tileDimensions.x ||
			    coords.y < _topLeftCoordinates.y * tileDimensions.y ||
				coords.y > (_topLeftCoordinates.y + bounds[3]) * tileDimensions.y) {
				continue;
			}

			if (object.xmlData.hasNode.polyline) {
				loadPolyline(object, set);
				continue;
			} else if (object.xmlData.has.width && object.xmlData.has.height && !object.xmlData.has.gid) {
				loadRegion(object, set);
				continue;
			} else if (object.xmlData.hasNode.point) {
				var pointObject:PointObject = new PointObject([object.x - tileDimensions.x * _topLeftCoordinates.x,
                                                       object.y - tileDimensions.y * _topLeftCoordinates.y]);
				pointObject.readPropertiesFrom(object);
				
				if (object.type == 'annotation') {
					// Points with type 'annotation' are not considered to be objects.
					// Instead, they "attach" themselves to an object which is loaded from a tile
					// layer, and their properties are applied to that object.
					annotationSet.push(pointObject);
				} else {
					set.points.set(pointObject.name, pointObject);
				}
				continue;
			}
			
			var oInfo:Dynamic = {x: coords.x - tileDimensions.x * _topLeftCoordinates.x,
				                 y: coords.y - tileDimensions.y * _topLeftCoordinates.y,
								 layer: tileLayer.name,
								 id: (object.xmlData.has.id ? object.xmlData.att.id : ''),
								 name: (object.xmlData.has.name ? object.xmlData.att.name : ''),
								 type: (object.xmlData.has.type ? object.xmlData.att.type : ''),
                                 _loadedFromObject: true,
								};
				
			if (object.xmlData.has.gid) {
				var gid:Int = Std.parseInt(object.xmlData.att.gid) - 1;
				
				if (objectExists(gid)) {
					oInfo = StructureUtils.merge(oInfo, objectInfo(gid));
					oInfo.gid = gid;
					if (!Reflect.hasField(oInfo, 'tiles')) {
						oInfo.tiles = [gid];
					} else {
                        var tileOffset = tilesetOffsets.get(tilesetSource(gid));
                        oInfo.tiles = [for (t in cast(oInfo.tiles, Array<Dynamic>)) t + tileOffset];
                    }
				} else {
					oInfo.tiles = [gid];
				}
			}
			if (object.xmlData.hasNode.properties) {
				for (property in object.xmlData.node.properties.nodes.property) {
					Reflect.setField(oInfo, property.att.name, property.att.value);
				}
			}
			set.entities.push(oInfo);
		}
		
		return set;
	}
	
	public function loadFromTileLayer(tileLayer:TiledTileLayer,
									  bounds:Array<Int>,
									  set:TiledObjectSet,
									  objectSet:Array<Dynamic>) {
		var topLeftCoordinates:Pair<Int> = [bounds[0], bounds[1]];
		var tiles = [for (i in 0...bounds[3])
						[for (j in 0...bounds[2])
							tileLayer.tileArray[tileLayer.width * (i + topLeftCoordinates.y) + topLeftCoordinates.x + j]
						]
					];
		if (tilesPerScreen != null) {
			tiles = ArrayUtils.eachRow(tiles, function(arr) { return ArrayUtils.filterByIndex(arr, function(k) { return k % tilesPerScreen.x < tilesPerScreen.x; }); });
			tiles = ArrayUtils.filterByIndex(tiles, function(k) { return k % tilesPerScreen.y < tilesPerScreen.y; });
		}

		for (i in 0...tiles.length) {
			for (j in 0...tiles[i].length) {
				var oInfo:Dynamic = {};
				var tileCode:Int = tiles[i][j] - 1;

				if (objectTiles.exists(tileCode)) {
					var tileKey = objectTiles.get(tileCode);
					var tileKeyInfo:Dynamic = objectInfo(tileKey);
					var tileKeyTiles:Array<Int> = tileKeyInfo.tiles;
					var tileOffset = tilesetOffsets.get(tilesetSource(tileCode));
					
					var offset:Pair<Int> = [0, 0];
					var shouldAdd:Bool = false;
					var cols:Int = (Reflect.hasField(tileKeyInfo, 'columns') ? tileKeyInfo.columns : 1);
					var rows:Int = (Reflect.hasField(tileKeyInfo, 'tiles') ? Std.int(tileKeyInfo.tiles.length / cols + 1e-6) : 1);
					
					if (tileKey == tileCode) {
						shouldAdd = true;
					} else if (tileKeyTiles[cols - 1] == tileCode && j < cols - 1) {
						shouldAdd = true;
						offset.x = -(cols - 1);
					} else if (tileKeyTiles[tileKeyTiles.length - cols] == tileCode && i < rows - 1) {
						shouldAdd = true;
						offset.y = -(rows - 1);
					} else if (tileKeyTiles[tileKeyTiles.length - 1] == tileCode && j < cols - 1 && i < rows - 1) {
						shouldAdd = true;
						offset = [ -(cols + 1), -(rows - 1)];
					}
					
					if (shouldAdd) {
						oInfo = StructureUtils.clone(tileKeyInfo);
						oInfo.gid = tileKey;
						oInfo.layer = tileLayer.name;
						oInfo.x = (j + offset.x) * tileDimensions.x;
						oInfo.y = (i + offset.y) * tileDimensions.y;
						if (!Reflect.hasField(oInfo, 'tiles')) {
							oInfo.tiles = [tileKey];
						} else {
                            oInfo.tiles = [for (t in cast(oInfo.tiles, Array<Dynamic>)) t + tileOffset];
                        }
                        oInfo._loadedFromObject = false;

						if (Reflect.hasField(oInfo, 'transformFromObjects')) {
							oInfo.transformFromObjects(oInfo, objectSet);
						}

						set.entities.push(oInfo);
					}
				}
			}
		}
	}
	
	public function offsetForIndex(i:Int):Int {
		var maxIndex:Int = -1;
		var maxValue:String = '';
		for (k in tilesetOffsets.keys()) {
			var val:Int = tilesetOffsets.get(k);
			if (val <= i) {
				maxIndex = val;
				maxValue = k;
			}
		}
		if (maxIndex == -1) {
			throw 'Tileset source for index ${i} undefined!';
		}
		return maxIndex;
	}
	
	public function tilesetSource(i:Int):String {
		var maxIndex:Int = -1;
		var maxValue:String = '';
		for (k in tilesetOffsets.keys()) {
			var val:Int = tilesetOffsets.get(k);
			if (val <= i && val > maxIndex) {
				maxIndex = val;
				maxValue = k;
			}
		}
		if (maxIndex == -1) {
			throw 'Tileset source for index ${i} undefined!';
		}
		return maxValue;
	}

	public function objectExists(i:Int):Bool {
		if (i < 0) return false;
		if (!tilesetOffsets.keys().hasNext()) return false;

		var source:String = tilesetSource(i);
		if (!idToObject.exists(source)) {
			trace("Warning: object map for tileset ${source} does not exist!");
			return false;
		}
		return idToObject.get(source).exists(i - tilesetOffsets.get(source));
	}
	
	public function objectInfo(i:Int):Dynamic {
		if (i < 0) return null;

		var source:String = tilesetSource(i);
		return idToObject.get(source).get(i - tilesetOffsets.get(source));
	}
}
