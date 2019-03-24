package nova.ds;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.HashMap;
import haxe.ds.ObjectMap;
import haxe.ds.WeakMap;
import haxe.ds.EnumValueMap;
import haxe.Constraints.IMap;

/**
 * A map with a default value for missing elements.
 * You can optionally supply a function to generate missing values.
 * 
 * @author Nathan Pinsker
 */
@:generic
class DefaultIntMap<V> implements IMap<Int, V> {
	private var _map:IntMap<V>;
	private var defaultConstructor:Void -> V;
	
	public function new(defaultConstructor:Void -> V = null) {
		_map = new IntMap<V>();
		this.defaultConstructor = defaultConstructor;
	}

	public function get(key:Int) {
		if (_map.exists(key)) {
			return _map.get(key);
		}
		var toReturn:V = null;
		if (defaultConstructor != null) toReturn = defaultConstructor();
		_map.set(key, toReturn);
		return toReturn;
	}
	
	public inline function set(key:Int, value:V) _map.set(key, value);

	public inline function exists(key:Int) return _map.exists(key);

	public inline function remove(key:Int) return _map.remove(key);

	public inline function keys():Iterator<Int> { return _map.keys(); }

	public inline function iterator():Iterator<V> { return _map.iterator(); }

	public inline function toString():String {
		return _map.toString();
	}

	@:to
	public inline function toIntMap():IntMap<V> {
		return _map;
	}
}

@:generic
class DefaultStringMap<V> implements IMap<String, V> {
	private var _map:Map<String, V>;
	private var defaultConstructor:Void -> V;
	
	public function new(defaultConstructor:Void -> V = null) {
		_map = new Map<String, V>();
		this.defaultConstructor = defaultConstructor;
	}

	public function get(key:String) {
		if (_map.exists(key)) {
			return _map.get(key);
		}
		#if desktop
		var toReturn:V = defaultConstructor();
		#else
		var toReturn:V = null;
		if (defaultConstructor != null) toReturn = defaultConstructor();
		#end
		_map.set(key, toReturn);
		return toReturn;
	}
	
	public inline function set(key:String, value:V) _map.set(key, value);

	public inline function exists(key:String) return _map.exists(key);

	public inline function remove(key:String) return _map.remove(key);

	public inline function keys():Iterator<String> { return _map.keys(); }

	public inline function iterator():Iterator<V> { return _map.iterator(); }

	public inline function toString():String {
		return _map.toString();
	}

	@:to
	public inline function toStringMap():Map<String, V> {
		return _map;
	}
}