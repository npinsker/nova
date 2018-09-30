package nova;

import nova.utils.ArrayUtils;
import nova.utils.DefaultMaps.DefaultIntMap;
import nova.utils.DefaultMaps.DefaultStringMap;

/**
 * ...
 * @author Nathan Pinsker
 */

@:generic
class GroupsIntMap<K> {
	public var _map:DefaultIntMap<Array<K>>;
	public var _evalFn:K -> Int;
	public var _cmpFn:K -> K -> Bool;
	
	public function new(evalFn:K -> Int, objectsToGroup:Iterable<K> = null, ?cmpFn:K -> K -> Bool = null) {
		_map = new DefaultIntMap<Array<K>>(function() { return []; });
		_evalFn = evalFn;
		_cmpFn = cmpFn;
		
		if (objectsToGroup != null) {
			for (object in objectsToGroup) {
				this.add(object);
			}
		}
	}
	
	public function get(group:Int):Array<K> {
		return _map.get(group);
	}
	
	public function remove(object:K, ?isUpdated:Bool = true) {
		_map.get(_evalFn(object)).remove(object);
	}
	
	public function add(object:K) {
		var group:Int = _evalFn(object);
		_map.get(group).push(object);
	}
	
	public function update(object:K, ?oldGroup:Int = null) {
		if (oldGroup != null) {
			if (_cmpFn != null) {
			}
			ArrayUtils.remove(_map.get(oldGroup), object, _cmpFn);
		} else {
			for (group in _map.keys()) {
				ArrayUtils.remove(_map.get(group), object, _cmpFn);
			}
		}
		add(object);
	}
	
	public function toString():String {
		return _map.toString();
	}
}

@:generic
class GroupsStringMap<K> {
	public var _map:DefaultStringMap<Array<K>>;
	public var _evalFn:K -> String;
	
	public function new(evalFn:K -> String, objectsToGroup:Array<K> = null) {
		_map = new DefaultStringMap<Array<K>>(function() { return []; });
		_evalFn = evalFn;
		
		if (objectsToGroup != null) {
			for (object in objectsToGroup) {
				this.add(object);
			}
		}
	}
	
	public function get(group:String):Array<K> {
		return _map.get(group);
	}
	
	public function remove(object:K, ?isUpdated:Bool = true) {
		_map.get(_evalFn(object)).remove(object);
	}
	
	public function add(object:K) {
		var group:String = _evalFn(object);
		_map.get(group).push(object);
	}
	
	public function update(object:K, ?oldGroup:String = null) {
		if (oldGroup != null) {
			_map.get(oldGroup).remove(object);
		} else {
			for (group in _map.keys()) {
				_map.get(group).remove(object);
			}
		}
		add(object);
	}
	
	public function toString():String {
		return _map.toString();
	}
}