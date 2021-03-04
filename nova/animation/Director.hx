package nova.animation;

import haxe.ds.Either;

import flash.display.Sprite;
import flixel.FlxSprite;
import flixel.util.typeLimit.OneOfThree;
import flixel.util.typeLimit.OneOfTwo;
import nova.ds.RealValuedFunction;
import nova.utils.OneOf;
import nova.utils.Pair;
import nova.utils.StructureUtils;
import openfl.geom.Point;

using nova.utils.ArrayUtils;

typedef InitFnType = FlxSprite -> Dynamic -> Void;
typedef UpdateFnType = FlxSprite -> Int -> Dynamic -> Void;

typedef DirectorActionParams = {
    @:optional var tag:String;
    @:optional var easeFn:RealValuedFunction;
}

/**
  * The functionality (both on creation and on update) that an Actor performs.
  */
class Action {
    public var initFn:InitFnType;
    public var updateFn:UpdateFnType;
    public var object:Dynamic;

    public function new(initFn:InitFnType, updateFn:UpdateFnType) {
        this.initFn = initFn;
        this.updateFn = updateFn;
        this.object = {};
    }

    public function init(sprite:FlxSprite) {
        if (this.initFn != null) {
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
  public var sprite:FlxSprite = null;
  public var newActor:OneOf<FlxSprite, Void -> FlxSprite> = null;
  public var action:Action;
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
  }

  public function init() {
      if (this.newActor != null) {
          switch (this.newActor) {
            case Left(l):
              this.sprite = l;
            case Right(r):
              this.sprite = r();
          }
      }

      if (this.action != null) {
          this.action.init(this.sprite);
      }
  }

  public function addAsDependencyOf(other:Actor) {
    this.nextSets.push(other);
    other.prevSets.push(this);
  }

  public function dependOn(other:Actor) {
    if (other == null) return;

    other.nextSets.push(this);
    this.prevSets.push(other);
  }
}

class AbstractPartialActor {
  public var initFn:InitFnType;
  public var updateFn:UpdateFnType;

  public function make(sprite:FlxSprite):Actor { return null; }
}

class PartialActor extends AbstractPartialActor {
    public var isDone:Actor -> Bool;

    public function new(initFn:InitFnType, updateFn:UpdateFnType, isDone:Actor -> Bool) {
        this.initFn = initFn;
        this.updateFn = updateFn;
        this.isDone = isDone;
    }
    override public function make(sprite:FlxSprite):Actor {
        return new Actor(sprite,
                         new Action(this.initFn, this.updateFn),
                         this.isDone);
    }
}

class PartialFrameBasedActor extends AbstractPartialActor {
    public var frames:Int;

    public function new(initFn:InitFnType, updateFn:UpdateFnType, frames:Int) {
      this.initFn = initFn;
      this.updateFn = updateFn;
      this.frames = frames;
    }

    override public function make(sprite:FlxSprite):Actor {
        return new Actor(sprite,
                         new Action(this.initFn, this.updateFn),
                         function(a:Actor) { return a.currentFrame == this.frames; });
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
  private var _actorIDsToDelete:Array<Int>;
  private var _animationInfoMap:Map<FlxSprite, Array<Actor>>;
  public var paused:Bool = false;

  private function new() {
    _animationInfoMap = new Map<FlxSprite, Array<Actor>>();

    _liveActors = new Array<Actor>();
  }

  private static function _noopActor(frames:Int):PartialFrameBasedActor {
    return new PartialFrameBasedActor(
               function(sprite:FlxSprite, object:Dynamic) { },
               function(sprite:FlxSprite, frame:Int, object:Dynamic):Void { },
               frames
           );
  }

  private static function _moveToActor(point:Pair<Int>, frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(
              function(sprite:FlxSprite, object:Dynamic) {
                  object.x = sprite.x;
                  object.y = sprite.y;
                  object.params = params;
              },
              function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                  var diff:Float = 1.0 / frames;
                  var params:DirectorActionParams = cast object.params;
                  if (params.easeFn != null) {
                      var lastPos = params.easeFn.getValueAt((frame - 1) / frames);
                      var newPos = params.easeFn.getValueAt(frame / frames);
                      diff = newPos - lastPos;
                  }
                  sprite.x += diff * (point.x - object.x);
                  sprite.y += diff * (point.y - object.y);
              },
              frames
          );
  }
  private static function _moveToDynamicActor(point:Void -> Pair<Int>,
                                              frames:Int,
                                              params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) {
                        object.x = sprite.x;
                        object.y = sprite.y;
                        object.point = point();
                        object.params = params;
                      },
                      function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        var diff:Float = 1.0 / frames;
                        var params:DirectorActionParams = cast object.params;
                        if (params.easeFn != null) {
                          var lastPos = params.easeFn.getValueAt((frame - 1) / frames);
                          var newPos = params.easeFn.getValueAt(frame / frames);
                          diff = newPos - lastPos;
                        }
                        sprite.x += diff * (object.point[0] - object.x);
                        sprite.y += diff * (object.point[1] - object.y);
                      },
                      frames);
  }

  private static function _moveByActor(point:Pair<Int>, frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(
               function(sprite:FlxSprite, object:Dynamic) {
                   object.x = sprite.x;
                   object.y = sprite.y;
                   object.point = point;
                   object.params = params;
               },
               function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                   var diff:Float = 1.0 / frames;
                   var params:DirectorActionParams = cast object.params;
                   if (params.easeFn != null) {
                       var lastPos = params.easeFn.getValueAt((frame - 1) / frames);
                       var newPos = params.easeFn.getValueAt(frame / frames);
                       diff = newPos - lastPos;
                   }
                   sprite.x += diff * object.point[0];
                   sprite.y += diff * object.point[1];
               },
               frames
           );
  }

  private static function _fadeInActor(frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) { sprite.alpha = 0; object.params = params; },
                      function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        sprite.alpha = (object.params.easeFn != null ?
                                        object.params.easeFn.getValueAt(frame / frames) :
                                        frame / frames);
                      },
              frames);
  }

  private static function _fadeOutActor(frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) { sprite.alpha = 1; object.params = params; },
                      function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        sprite.alpha = (object.params.easeFn != null ?
                                        object.params.easeFn.getValueAt(1.0 - frame / frames) :
                                        1.0 - frame / frames);
                      },
              frames);
  }

  private static function _scaleInActor(startingScale:Float, frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) {
                        sprite.scale.set(startingScale, startingScale); object.params = params;
                      },
                      function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                var s:Float = startingScale - (startingScale - 1.0) * frame / frames;
                if (object.params.easeFn != null) s = object.params.easeFn.getValueAt(s);
                sprite.scale.set(s, s);
              },
              frames);
  }

  private static function _scaleOutActor(endingScale:Float, frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) { object.params = params; },
                      function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                var s:Float = 1.0 + (endingScale - 1) * frame / frames;
                if (object.params.easeFn != null) s = object.params.easeFn.getValueAt(s);
                sprite.scale.set(s, s);
              },
              frames);
  }

  private static function _bobActor(point:Pair<Int>, reps:Int, frames:Int, params:DirectorActionParams):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) {
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
                if (Reflect.hasField(object, 'easeFn')) {
                  pct = object.easeFn.getValueAt(pct);
                }

                sprite.x += (object.point[0] * pct - object.lastOffsetX);
                object.lastOffsetX = object.point[0] * pct;
                sprite.y += (object.point[1] * pct - object.lastOffsetY);
                object.lastOffsetY = object.point[1] * pct;
              },
              frames);
  }

  private static function _jumpInArcActor(verticalDist:Int, frames:Int):PartialFrameBasedActor {
      return new PartialFrameBasedActor(
          function(sprite:FlxSprite, object:Dynamic) {
              object.mult = verticalDist / Std.int(frames * frames / 4 + 0.2);
          },
          function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
              var dist:Float = (2 * frame - frames - 1);
              sprite.y = sprite.y + dist * object.mult;
          },
          frames
      );
  }

  private static function _callRepeatedlyActor(fn:OneOf<FlxSprite -> Int -> Void,
                                                        Int -> Void>,
                                                frames:Int):PartialFrameBasedActor {
    return new PartialFrameBasedActor(function(sprite:FlxSprite, object:Dynamic) {
                        object.fn = fn;
                      },
                      function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                        switch (object.fn) {
                          case Left(l):
                            l(sprite, frame);
                          case Right(r):
                            r(frame);
                        }
                      },
                      frames);
  }

  private static function _callUntilActor(fn:OneOf<FlxSprite -> Int -> Void,
                                                   FlxSprite -> Void>,
                                          check:FlxSprite -> Bool):PartialActor {
      return new PartialActor(function(sprite:FlxSprite, object:Dynamic) {
                          object.fn = fn;
                        },
                        function(sprite:FlxSprite, frame:Int, object:Dynamic):Void {
                          switch (object.fn) {
                            case Left(l):
                              l(sprite, frame);
                            case Right(r):
                              r(sprite);
                          }
                        },
                        function(a:Actor) { return check(a.sprite); }
      );
  }

  public static function getID() {
    return instance.nextID++;
  }

  /**
    * Used to create custom Director functions.
    */
  public static function directorChainableFn(partialActor:AbstractPartialActor,
                                             sprite:OneOfTwo<FlxSprite, Actor>,
                                             ?tag:String):Actor {
      if (Std.is(sprite, FlxSprite) || sprite == null) {
          var a:Actor = partialActor.make(sprite);
          a._id = getID();
          a.tag = tag;
          a.init();
          instance._liveActors.push(a);
          return a;
      }

    var a:Actor = partialActor.make(null);
    a._id = getID();
    a.tag = tag;

    var prevActor:Actor = cast sprite;
    a.dependOn(prevActor);

    return a;
  }

  /**
    * Moves the sprite to the specified (x, y) position over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply an easeFn to override this.
    * Values above 1 will move the sprite along the same line from the start point to the end point.
    */
  public static function moveTo(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_moveToActor(point, frames, params), sprite, params.tag);
  }

  /**
    * Moves the sprite to the specified (x, y) position.
    * This position is calculated at the point the Actor begins running,
    * rather than when the Actor is created.
    */
  public static function moveToDynamic(sprite:OneOfTwo<FlxSprite, Actor>,
                                       point:Void -> Pair<Int>,
                                       frames:Int,
                                       ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_moveToDynamicActor(point, frames, params), sprite, params.tag);
  }

  /**
    * Moves the sprite by the specified (x, y) amount over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply an easeFn to override this.
    */
  public static function moveBy(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_moveByActor(point, frames, params), sprite, params.tag);
  }

  /**
    * Fades the sprite in over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply an easeFn to override this.
    */
  public static function fadeIn(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_fadeInActor(frames, params), sprite, params.tag);
  }

  /**
    * Fades the sprite out over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply an easeFn to override this.
    */
  public static function fadeOut(sprite:OneOfTwo<FlxSprite, Actor>, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_fadeOutActor(frames, params), sprite, params.tag);
  }

  public static function scaleIn(sprite:OneOfTwo<FlxSprite, Actor>, startingScale:Float, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_scaleInActor(startingScale, frames, params), sprite, params.tag);
  }

  public static function scaleOut(sprite:OneOfTwo<FlxSprite, Actor>, endingScale:Float, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_scaleOutActor(endingScale, frames, params), sprite, params.tag);
  }

  /**
    * Causes the sprite to 'bob' for a certain number of repetitions,
    * over the specified number of frames.
    *
    * Uses linear interpolation by default, but you can supply an easeFn to override this.
    */
  public static function bob(sprite:OneOfTwo<FlxSprite, Actor>, point:Pair<Int>, reps:Int, frames:Int, ?params:DirectorActionParams):Actor {
    if (params == null) params = {};
    return directorChainableFn(_bobActor(point, reps, frames, params), sprite, params.tag);
  }

  /**
    * Causes the sprite to jump in an arc (as if it were being pulled by a constant downward force)
    * over the specified number of frames. Very useful for jumping animations.
    */
  public static function jumpInArc(sprite:OneOfTwo<FlxSprite, Actor>, verticalDist:Int, frames:Int, tag:String = null):Actor {
    return directorChainableFn(_jumpInArcActor(verticalDist, frames), sprite, tag);
  }

  /**
    * Causes the supplied function to be called for a given number of frames.
    */
  public static function callRepeatedly(sprite:OneOfTwo<FlxSprite, Actor>,
                                        fn:OneOf<FlxSprite -> Int -> Void,
                                                 Int -> Void>,
                                        frames:Int,
                                        ?params:DirectorActionParams):Actor {
    if (params == null) params = {};

    return directorChainableFn(_callRepeatedlyActor(fn, frames), sprite, params.tag);
  }

  /**
    * Causes the supplied function to be called until 'check' evaluates to true.
    */
  public static function callUntil(sprite:OneOfTwo<FlxSprite, Actor>,
                                   fn:OneOf<FlxSprite -> Int -> Void,
                                            FlxSprite -> Void>,
                                   check:FlxSprite -> Bool,
                                   ?params:DirectorActionParams):Actor {
    if (params == null) params = {};

    return directorChainableFn(_callUntilActor(fn, check), sprite, params.tag);
  }


  /**
    * Does nothing for the specified number of frames.
    *
    * Since it is common to want to wait without a target,
    * the first argument can be an integer in addition to a FlxSprite or Actor.
    * In this case the target will be null.
    *
    * ```
    * Director.wait(60).call(function() {
    *   trace("One second passed!");
    * });
    * ```
    */
  public static function wait(spriteOrFrames:OneOfThree<FlxSprite, Actor, Int>,
                              frames:Int = null,
                              tag:String = null):Actor {
    if (frames == null) {
        // 'spriteOrFrames' is being used as the number of frames
        return directorChainableFn(_noopActor(cast(spriteOrFrames, Int)), null, tag);
    }
    var ootSprite:OneOfTwo<FlxSprite, Actor> = null;
    if (spriteOrFrames != null) {
        ootSprite = (Std.is(spriteOrFrames, FlxSprite) ?
                     cast(spriteOrFrames, FlxSprite) :
                     cast(spriteOrFrames, Actor));
    }
    return directorChainableFn(_noopActor(frames), ootSprite, tag);
  }

  /**
    * Calls the specified function, which must take the actor as an argument.
    */
  public static function call(actor:Actor,
                              callback:OneOf<Void -> Void, FlxSprite -> Void>):Actor {
    var callbackWithArg:FlxSprite -> Void;
    switch(callback) {
      case Left(l):
        callbackWithArg = function(sprite:FlxSprite) { return l(); };
      case Right(r):
        callbackWithArg = r;
    }

    if (actor == null) {
        callbackWithArg(null);
        return null;
    }

    var a:Actor = new Actor(
        null,
        new Action(
            function(sprite:FlxSprite, obj:Dynamic) {
                callbackWithArg(sprite);
            },
            function(sprite:FlxSprite, frame:Int, obj:Dynamic) { }
        ),
        function(a:Actor) { return true; }
    );
    a._id = getID();
    a.dependOn(actor);
    return a;
  }

  public static function then(prevActor:Actor, newActor:OneOfTwo<FlxSprite, Void -> FlxSprite>):Actor {
      var a:Actor = new Actor(null, null, function(a) { return true; });
      a._id = getID();
      if (Std.is(newActor, FlxSprite)) {
        var sp:FlxSprite = cast newActor;
        a.newActor = sp;
      } else {
        var sp:Void -> FlxSprite = cast newActor;
        a.newActor = sp;
      }

      if (prevActor != null) {
          a.dependOn(prevActor);
      } else {
          a.init();
          instance._liveActors.push(a);
      }
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
    var _sprite:FlxSprite = (prevActors == null ? null : cast sprite);
    var _prevActors:Array<Actor> = (prevActors == null ? cast sprite : prevActors);

    var a:Actor = new Actor(null, null, null);
    a.sprite = _sprite;
    a._id = getID();
    for (prevActor in _prevActors) {
      a.dependOn(prevActor);
    }
    return a;
  }

  /**
    * Returns all actors that have the given tag.
    */
  public static function actorsWithTag(tag:String):Array<Actor> {
    return instance._liveActors.filter(function(a:Actor) { return a.tag == tag; });
  }

  private function _update():Void {
    instance._actorIDsToDelete = [];

    var i = instance._liveActors.length - 1;
    while (i >= 0) {
      var liveActor = instance._liveActors[i];

      liveActor.currentFrame += 1;
      if (liveActor.action != null) {
        liveActor.action.update(liveActor.sprite, liveActor.currentFrame);
      }

      if (liveActor.action == null || (liveActor.isDone != null && liveActor.isDone())) {
        for (nextActor in liveActor.nextSets) {
          nextActor.prevSets.remove(liveActor);
          if (nextActor.prevSets.length == 0) {
              // Lazily evaluate which sprite the new Actor is responsible for.
              // This is in order to handle sprites that may not exist when the Director graph
              // begins execution.
              if (nextActor.newActor == null) {
                  nextActor.sprite = liveActor.sprite;
              }

              nextActor.init();

              if (liveActor.action == null) {
                  instance._liveActors.insert(0, nextActor);
                  ++i;
              } else {
                  instance._liveActors.push(nextActor);
              }
          }
        }
        instance._liveActors.remove(liveActor);
      }
      --i;
    }

    // Tags that we've cleared in the update loop shouldn't be removed during the loop,
    // as this can cause unpredictable behavior.
    i = instance._liveActors.length - 1;
    while (i >= 0) {
      var liveActor = instance._liveActors[i];
      if (instance._actorIDsToDelete.indexOf(liveActor._id) != -1) {
        instance._liveActors.remove(liveActor);
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
        instance._actorIDsToDelete.push(instance._liveActors[i]._id);
      }
      --i;
    }
  }
}
