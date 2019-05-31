package nova.animation;
import flixel.FlxSprite;
import nova.utils.Pair;

using Lambda;
using StringTools;

class AnimationFrames {
	public var name:String;
	public var frames:Array<Int>;
	public var frameRate:Int;
	public var looped:Bool;
	public function new(name:String, frames:Array<Int>, frameRate:Int = 30, looped:Bool = false) {
		this.name = name;
		this.frames = frames;
		this.frameRate = frameRate;
		this.looped = looped;
	}
}

/**
  * A concise way of specifying sets of animations for a FlxSprite.
  */
class AnimationSet {
	public var animations:Array<AnimationFrames>;
	public var spriteSize:Pair<Int>;
	
	public function new(spriteSize:Pair<Int>, animations:Array<AnimationFrames>) {
		this.spriteSize = spriteSize;
		this.animations = animations;
	}
	
  /**
    * Adds the animations in this set to the supplied FlxSprite.
    */
	public function addToFlxSprite(sprite:FlxSprite) {
		for (frame in animations) {
			sprite.animation.add(frame.name, frame.frames, frame.frameRate, frame.looped);
		}
	}
	
	public function names():Array<String> {
		return animations.map(function(k:AnimationFrames) { return k.name; });
	}
	
	public function toString():String {
		return spriteSize.toString() + ' | ' + animations.toString();
	}
	
	public static function fromString(spriteSize:Pair<Int>, string:String):AnimationSet {
		var animationFrames:Array<AnimationFrames> = new Array<AnimationFrames>();
		
		for (line in string.split('\n')) {
			var index = line.indexOf(':');
			if (index == -1) {
				continue;
			}
			var name = line.substring(0, index);
			var frameRate:Int = 30;
			var looped:Bool = false;
			if (name.indexOf('[') != -1) {
				frameRate = Std.parseInt(name.substring(name.indexOf('[') + 1, name.indexOf(']')));
				name = name.substring(0, name.indexOf('[')).trim();
			}
			var frames = line.substring(index + 1).split(',').map(function(s:String):Int { return Std.parseInt(s.trim()); });
			animationFrames.push(new AnimationFrames(name, frames, frameRate));
		}
		return new AnimationSet(spriteSize, animationFrames);
	}
}
