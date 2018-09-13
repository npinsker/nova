package nova.animation;
import flash.display.Sprite;
import flixel.FlxSprite;
import flixel.util.typeLimit.OneOfTwo;
import haxe.ds.Either;
import nova.utils.Pair;
import openfl.geom.Point;

using nova.utils.ArrayUtils;

/**
 * Director is an easy way to chain animations together.
 * 
 * @author Nathan Pinsker
 */

 
 typedef InitFnType = FlxSprite -> Dynamic -> Void;
 typedef UpdateFnType = FlxSprite -> Int -> Dynamic -> Void;
 
 class Action {
	 public var initFn:InitFnType;
	 public var updateFn:UpdateFnType;
	 public var object:Dynamic;
	 public var length:Int;
	 
	 public function new(initFn:InitFnType, updateFn:UpdateFnType, length:Int) {
		 this.initFn = initFn;
		 this.updateFn = updateFn;
		 this.object = {};
		 this.length = length;
	 }
	 
	 public function init(sprite:FlxSprite) {
		 this.initFn(sprite, this.object);
	 }
	 
	 public function update(sprite:FlxSprite, frame:Int) {
		 this.updateFn(sprite, frame, this.object);
	 }
 }
 
class Actor {
	public var _id:Int = -1;
	public var tag:String = null;
	public var currentFrame = 0;
	public var sprite:FlxSprite;
	public var action:Action;
	public var callback:FlxSprite -> Void;
	
	public var prevSets:Array<Actor>;
	public var nextSets:Array<Actor>;
	
	public function new(sprite:FlxSprite, action:Action) {
		this.sprite = sprite;
		this.action = action;
		
		prevSets = new Array<Actor>();
		nextSets = new Array<Actor>();
		currentFrame = 0;
		callback = null;
	}
	
	public function setCallback(callback:FlxSprite -> Void) {
		this.callback = callback;
	}
	
	public function addAsDependencyOf(other:Actor) {
		this.nextSets.push(other);
		other.prevSets.push(this);
	}
	
	public function dependOn(other:Actor) {
		other.nextSets.push(this);
		this.prevSets.push(other);
	}
}
 
class Director {
	public static var instance(default, null):Director = new Director();
	
	private var nextID:Int = 0;
	private var _liveActors:Array<Actor>;
	private var _animationInfoMap:Map<FlxSprite, Array<Actor>>;

	private function new() {
		_animationInfoMap = new Map<FlxSprite, Array<Actor>>();
		
		_liveActors = new Array<Actor>();
	}
	
	private static function _noopAction(frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void { },
						  frames);
	}
	
	private static function _fadeInAction(frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { sprite.alpha = 0; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void { sprite.alpha = frame / frames; },
						  frames);
	}
	
	private static function _fadeOutAction(frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { sprite.alpha = 1; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void { sprite.alpha = 1.0 - frame / frames; },
						  frames);
	}
	
	private static function _moveToAction(point:Pair<Int>, frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { object.x = sprite.x; object.y = sprite.y; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  sprite.x = object.x + (frame / frames) * (point.x - object.x);
							  sprite.y = object.y + (frame / frames) * (point.y - object.y);
						  },
						  frames);
	}
	
	public static function directorChainableFn(action:Action, sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, tag:String):Actor {
		if (Std.is(sprite, FlxSprite)) {
			var a:Actor = new Actor(cast(sprite, FlxSprite), action);
			a._id = instance.nextID++;
			a.tag = tag;
			if (action.initFn != null) {
				action.init(cast(sprite, FlxSprite));
			}
			instance._liveActors.push(a);
			return a;
		}

		var prevActor = cast(sprite, Actor);
		if (prevActor.action == null) {
			prevActor.action = action;
			return prevActor;
		}
		var a:Actor = new Actor(prevActor.sprite, action);
		a._id = instance.nextID++;
		a.tag = tag;
		a.dependOn(prevActor);
		return a;
	}
	
	public static function fadeIn(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, tag:String = null):Actor {
		return directorChainableFn(_fadeInAction(frames), sprite, frames, tag);
	}
	
	public static function fadeOut(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, tag:String = null):Actor {
		return directorChainableFn(_fadeOutAction(frames), sprite, frames, tag);
	}
	
	public static function moveTo(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, frames:Int, tag:String = null):Actor {
		return directorChainableFn(_moveToAction(point, frames), sprite, frames, tag);
	}
	
	public static function moveBy(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, frames:Int, tag:String = null):Actor {
		var startPoint:Pair<Int>;
		if (Std.is(sprite, FlxSprite)) {
			startPoint = [Std.int(cast(sprite, FlxSprite).x), Std.int(cast(sprite, FlxSprite).y)];
		} else {
			startPoint = [Std.int(cast(sprite, Actor).sprite.x), Std.int(cast(sprite, Actor).sprite.y)];
		}
		return directorChainableFn(_moveToAction(startPoint + point, frames), sprite, frames, tag);
	}
	
	public static function wait(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, tag:String):Actor {
		return directorChainableFn(_noopAction(frames), sprite, frames, tag);
	}
	
	public static function call(actor:Actor, callback:FlxSprite -> Void):Actor {
		actor.setCallback(callback);
		return actor;
	}
	
	public static function then(prevActor:Actor, newActor:FlxSprite):Actor {
		var a:Actor = new Actor(newActor, null);
		a._id = instance.nextID++;
		a.dependOn(prevActor);
		return a;
	}
	
	public static function afterAll(sprite:FlxSprite, prevActors:Array<Actor>):Actor {
		var a:Actor = new Actor(sprite, null);
		a._id = instance.nextID++;
		for (prevActor in prevActors) {
			a.dependOn(prevActor);
		}
		return a;
	}
	
	public static function skipToEnd(actor:Actor):Void {
		if (actor.action != null) {
			actor.action.update(actor.sprite, actor.action.length);
		}
		for (nextActor in actor.nextSets) {
			nextActor.prevSets.remove(actor);
			if (nextActor.prevSets.length == 0) {
				if (nextActor.action != null) {
					nextActor.action.init(nextActor.sprite);
				}
				instance._liveActors.push(nextActor);
			}
		}
		if (actor.callback != null) {
			actor.callback(actor.sprite);
		}
		instance._liveActors.remove(actor);
	}
	
	public static function actorsWithTag(tag:String):Array<Actor> {
		return instance._liveActors.filter(function(a:Actor) { return a.tag == tag; });
	}
	
	private function _update():Void {
		var i = instance._liveActors.length - 1;
		while (i >= 0) {
			var liveActor = instance._liveActors[i];
			liveActor.currentFrame += 1;
			if (liveActor.action != null) {
				liveActor.action.update(liveActor.sprite, liveActor.currentFrame);
			}
			
			if (liveActor.action == null || liveActor.currentFrame == liveActor.action.length) {
				for (nextActor in liveActor.nextSets) {
					nextActor.prevSets.remove(liveActor);
					if (nextActor.prevSets.length == 0) {
						if (nextActor.action != null) {
							nextActor.action.init(nextActor.sprite);
						}
						instance._liveActors.push(nextActor);
					}
				}
				if (liveActor.callback != null) {
					liveActor.callback(liveActor.sprite);
				}
				instance._liveActors.splice(i, 1);
			}
			--i;
		}
	}
	
	public static function update():Void {
		instance._update();
	}
}