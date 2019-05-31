package nova.animation;

import haxe.ds.Either;

import flash.display.Sprite;
import flixel.FlxSprite;
import flixel.util.typeLimit.OneOfThree;
import flixel.util.typeLimit.OneOfTwo;
import nova.ds.Polyline;
import nova.utils.OneOf;
import nova.utils.Pair;
import openfl.geom.Point;

using nova.utils.ArrayUtils;

typedef InitFnType = FlxSprite -> Dynamic -> Void;
typedef UpdateFnType = FlxSprite -> Int -> Dynamic -> Void;

typedef DirectorActionParams = {
  @:optional var tag:String;
  @:optional var polyLine:Polyline;
}
 
/**
  * The functionality (both on creation and on update) that an Actor performs.
  */
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
		if (initFn != null) {
		this.initFn(sprite, this.object);
		}
	}
	 
	public function update(sprite:FlxSprite, frame:Int) {
		if (updateFn != null) {
			this.updateFn(sprite, frame, this.object);
		}
	}
}
 
/**
  * A component in the Director execution graph. Contains information about
  * specific execution and animation behaviors.
  *
  * At any given time, some subset of Actors are currently "active". During each
  * update step, Director calls the action assigned to each Actor. It also uses
  * information within the Actor class to figure out whether the animation is
  * complete and, if so, whether any additional Actors should be marked active.
  */
class Actor {
	public var _id:Int = -1;
	public var tag:String = null;
	public var currentFrame = 0;
	public var sprite:FlxSprite;
	public var action:Action;
	public var callback:FlxSprite -> Void;
	public var isDone:Void -> Bool;
	
	public var prevSets:Array<Actor>;
	public var nextSets:Array<Actor>;
	
	public function new(sprite:FlxSprite, action:Action, isDoneA:Actor -> Bool) {
		this.sprite = sprite;
		this.action = action;
		this.isDone = function() { return isDoneA(this); };
		
		prevSets = new Array<Actor>();
		nextSets = new Array<Actor>();
		currentFrame = 0;
		callback = null;
	}
	
	public function setCallback(callback:OneOf<Void -> Void, FlxSprite -> Void>) {
    this.callback = callback;
    switch(callback) {
      case Left(l):
        var castCallback:Void -> Void = callback;
        this.callback = function(sp:FlxSprite) { return castCallback(); };
      case Right(r):
        this.callback = callback;
    }
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

/**
 * Director is an easy way to chain animations and functions together.
 *
 * Basic usage:
 *
 * ```
 * using nova.animation.Director;
 *
 * sprite.moveBy([100, 0], 30).moveBy([0, 100], 20).call(function() {
 *   remove(sprite);
 * });
 * sprite.fadeIn(20);  // will happen concurrently with movement
 * ```
 *
 * Custom animations can also be added. See `directorChainableFn` for more details.
 */
class Director {
	public static var instance(default, null):Director = new Director();
	
	private var nextID:Int = 0;
	private var _liveActors:Array<Actor>;
	private var _animationInfoMap:Map<FlxSprite, Array<Actor>>;
	public var paused:Bool = false;

	private function new() {
		_animationInfoMap = new Map<FlxSprite, Array<Actor>>();
		
		_liveActors = new Array<Actor>();
	}
	
	private static function _noopAction(frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void { },
						  frames);
	}
	
	private static function _moveToAction(point:Pair<Int>, frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
                        object.x = sprite.x; object.y = sprite.y; object.params = params;
                      },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        var diff:Float = 1.0 / frames;
                        if (object.params.polyLine != null) {
                          var lastPos = object.params.polyLine.getValueAt((frame - 1) / frames);
                          var newPos = object.params.polyLine.getValueAt(frame / frames);
                          diff = newPos - lastPos;
                        }
                        sprite.x += diff * (point.x - object.x);
                        sprite.y += diff * (point.y - object.y);
                      },
                      frames);
	}
	
	private static function _moveByAction(point:Pair<Int>, frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
                        object.x = sprite.x; object.y = sprite.y; object.point = point; object.params = params;
                      },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        var diff:Float = 1.0 / frames;
                        if (object.params.polyLine != null) {
                          var lastPos = object.params.polyLine.getValueAt((frame - 1) / frames);
                          var newPos = object.params.polyLine.getValueAt(frame / frames);
                          diff = newPos - lastPos;
                        }
                        sprite.x += diff * object.point[0];
                        sprite.y += diff * object.point[1];
                      },
                      frames);
	}
	
	private static function _fadeInAction(frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { sprite.alpha = 0; object.params = params; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        sprite.alpha = (object.params.polyLine != null ?
                                        object.params.polyLine.getValueAt(frame / frames) :
                                        frame / frames);
                      },
						  frames);
	}
	
	private static function _fadeOutAction(frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { sprite.alpha = 1; object.params = params; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        sprite.alpha = (object.params.polyLine != null ?
                                        object.params.polyLine.getValueAt(1.0 - frame / frames) :
                                        1.0 - frame / frames);
                      },
						  frames);
	}
	
	private static function _scaleInAction(startingScale:Float, frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
                        sprite.scale.set(startingScale, startingScale); object.params = params;
                      },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  var s:Float = startingScale - (startingScale - 1.0) * frame / frames;
                if (object.params.polyLine != null) s = object.params.polyLine.getValueAt(s);
							  sprite.scale.set(s, s);
						  },
						  frames);
	}
	
	private static function _scaleOutAction(endingScale:Float, frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) { object.params = params; },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  var s:Float = 1.0 + (endingScale - 1) * frame / frames;
                if (object.params.polyLine != null) s = object.params.polyLine.getValueAt(s);
							  sprite.scale.set(s, s);
						  },
						  frames);
	}
	
	private static function _bobAction(point:Pair<Int>, reps:Int, frames:Int, params:DirectorActionParams):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
							  object.point = point; object.reps = reps;
                object.lastOffsetX = 0.0;
                object.lastOffsetY = 0.0;
                for (field in Reflect.fields(params)) {
                  Reflect.setField(object, field, Reflect.field(params, field));
                }
						  },
              function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  if (frame == frames) {
								  sprite.x -= object.lastOffsetX;
								  sprite.y -= object.lastOffsetY;
								  return;
							  }
							  
							  var pct:Float = frame / frames * reps;
							  pct -= Math.ffloor(pct);
							  if (pct < 0.25) {
								  pct = 4 * pct;
							  } else if (pct < 0.75) {
								  pct = 1.0 - 4.0 * (pct - 0.25);
							  } else {
								  pct = -1.0 + 4.0 * (pct - 0.75);
							  }
                if (Reflect.hasField(object, 'polyLine')) {
                  pct = object.polyLine.getValueAt(pct);
                }

							  sprite.x += (object.point[0] * pct - object.lastOffsetX);
                object.lastOffsetX = object.point[0] * pct;
							  sprite.y += (object.point[1] * pct - object.lastOffsetY);
                object.lastOffsetY = object.point[1] * pct;
						  },
						  frames);
	}
	
	private static function _jumpInArcAction(verticalDist:Int, frames:Int):Action {
		return new Action(function(sprite:FlxSprite, object:Dynamic) {
						      object.mult = verticalDist / Std.int(frames * frames / 4 + 0.2);
		                  },
		                  function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
							  var dist:Float = (2 * frame - frames - 1);
							  sprite.y = sprite.y + dist * object.mult;
						  },
						  frames);
	}
	
	public static function getID() {
		return instance.nextID++;
	}
	
  /**
    * Used to create custom Director functions.
    */
	public static function directorChainableFn(action:Action, sprite:OneOfTwo<FlxSprite, Actor>, tag:String, ?overrideCheck:Actor -> Bool):Actor {
		if (Std.is(sprite, FlxSprite) || sprite == null) {
			var a:Actor = new Actor((sprite != null ? cast(sprite, FlxSprite) : null), action,
				(overrideCheck != null ? overrideCheck : function(a:Actor) { return a.currentFrame == a.action.length; }));
			a._id = instance.nextID++;
			a.tag = tag;
			if (action.initFn != null) {
				action.init((sprite != null ? cast(sprite, FlxSprite) : null));
			}
			instance._liveActors.push(a);
			return a;
		}

		var prevActor = cast(sprite, Actor);
		if (prevActor.action == null && prevActor.callback == null) {
			prevActor.action = action;
			prevActor.isDone = (overrideCheck != null ? function() { return overrideCheck(prevActor); } : function() { return prevActor.currentFrame == prevActor.action.length; });
			return prevActor;
		}
		var a:Actor = new Actor(prevActor.sprite, action,
		                        (overrideCheck != null ? overrideCheck : function(a:Actor) { return a.currentFrame == a.action.length; }));
		a._id = getID();
		a.tag = tag;
		a.dependOn(prevActor);
		return a;
	}
	
  /**
    * Moves the sprite to the specified (x, y) position over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply a polyline to override this.
    * Values above 1 will move the sprite along the same line from the start point to the end point.
    */
	public static function moveTo(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_moveToAction(point, frames, params), sprite, params.tag);
	}
	
  /**
    * Moves the sprite by the specified (x, y) amount over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply a polyline to override this.
    */
	public static function moveBy(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_moveByAction(point, frames, params), sprite, params.tag);
	}
	
  /**
    * Fades the sprite in over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply a polyline to override this.
    */
	public static function fadeIn(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_fadeInAction(frames, params), sprite, params.tag);
	}
	
  /**
    * Fades the sprite out over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply a polyline to override this.
    */
	public static function fadeOut(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_fadeOutAction(frames, params), sprite, params.tag);
	}
	
	public static function scaleIn(sprite:OneOfTwo<FlxSprite, Actor>, startingScale:Float, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_scaleInAction(startingScale, frames, params), sprite, params.tag);
	}
	
	public static function scaleOut(sprite:OneOfTwo<FlxSprite, Actor>, endingScale:Float, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_scaleOutAction(endingScale, frames, params), sprite, params.tag);
	}
	
  /**
    * Causes the sprite to 'bob' for a certain number of repetitions,
    * over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply a polyline to override this.
    */
	public static function bob(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, reps:Int, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
		return directorChainableFn(_bobAction(point, reps, frames, params), sprite, params.tag);
	}
	
  /**
    * Causes the sprite to jump in an arc (as if it were being pulled by a constant downward force)
    * over the specified number of frames. Very useful for jumping animations.
    */
	public static function jumpInArc(sprite:OneOfTwo<FlxSprite, Actor>, verticalDist:Int, frames:Int, tag:String = null):Actor {
		var startPoint:Pair<Int>;
		if (Std.is(sprite, FlxSprite)) {
			startPoint = [Std.int(cast(sprite, FlxSprite).x), Std.int(cast(sprite, FlxSprite).y)];
		} else {
			startPoint = [Std.int(cast(sprite, Actor).sprite.x), Std.int(cast(sprite, Actor).sprite.y)];
		}
		return directorChainableFn(_jumpInArcAction(verticalDist, frames), sprite, tag);
	}
	
  /**
    * Does nothing for the specified number of frames.
    *
    * Since it is common to want to wait without a target,
    * the first argument can be an integer in addition to a FlxSprite or Actor.
    * In this case the target will be null.
    *
    * ```
    * Director.wait(60).then(function() {
    *   trace("One second passed!");
    * });
    * ```
    */
	public static function wait(sprite:OneOfThree<FlxSprite, Actor, Int>, frames:Int = null, tag:String = null):Actor {
		if (frames == null) {
			return directorChainableFn(_noopAction(cast(sprite, Int)), null, tag);
		}
		var ootSprite:OneOfTwo<FlxSprite, Actor> = null;
		if (sprite != null) {
			ootSprite = (Std.is(sprite, FlxSprite) ? cast(sprite, FlxSprite) : cast(sprite, Actor));
		}
		return directorChainableFn(_noopAction(frames), ootSprite, tag);
	}
	
  /**
    * Calls the specified function, which must take the actor as an argument.
    */
	public static function call(actor:Actor,
                              callback:OneOf<Void -> Void, FlxSprite -> Void>):Actor {
    actor.setCallback(callback);
		return actor;
	}
	
	public static function then(prevActor:Actor, newActor:FlxSprite):Actor {
		var a:Actor = new Actor(newActor, null, null);
		a._id = instance.nextID++;
		a.dependOn(prevActor);
		return a;
	}
	
  /**
    * Creates an empty Actor that is triggered after all previous actors finish
    * their animations.
    *
    * Can optionally take a sprite as target.
    */
	public static function afterAll(sprite:OneOfTwo<FlxSprite, Array<Actor>>,
                                  prevActors:Array<Actor> = null):Actor {
    var _sprite:FlxSprite = (prevActors == null ? null : sprite);
    var _prevActors:Array<Actor> = (prevActors == null ? sprite : prevActors);

		var a:Actor = new Actor(_sprite, null, null);
		a._id = instance.nextID++;
		for (prevActor in _prevActors) {
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
	
  /**
    * Returns all actors that have the given tag.
    */
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
			
			if (liveActor.action == null || (liveActor.isDone != null && liveActor.isDone())) {
				if (liveActor.callback != null) {
					liveActor.callback(liveActor.sprite);
				}
				for (nextActor in liveActor.nextSets) {
					nextActor.prevSets.remove(liveActor);
					if (nextActor.prevSets.length == 0) {
						if (nextActor.action != null) {
							nextActor.action.init(nextActor.sprite);
						}
						if (nextActor.action == null) {
							instance._liveActors.insert(0, nextActor);
							++i;
						} else {
							instance._liveActors.push(nextActor);
						}
					}
				}
				instance._liveActors.splice(i, 1);
			}
			--i;
		}
	}
	
	public static function update():Void {
		if (!instance.paused) {
			instance._update();
		}
	}
	
	public static function pause():Void {
		instance.paused = true;
	}
	
	public static function resume():Void {
		instance.paused = false;
	}
	
	public static function clear():Void {
		instance._liveActors.splice(0, instance._liveActors.length);
	}
	
  /**
    * Deletes all actors with the given tag.
    *
    * Use this with care; it does not trigger actors that depend on this one.
    */
	public static function clearTag(tag:String):Void {
		var i = instance._liveActors.length - 1;
		while (i >= 0) {
			if (instance._liveActors[i].tag == tag) {
				instance._liveActors.splice(i, 1);
			}
			--i;
		}
	}
}
