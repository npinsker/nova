package nova.render;

import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRange;
import nova.render.FlxLocalSprite.LocalSpriteWrapper;
import nova.utils.Pair;

class NovaParticle extends LocalSpriteWrapper {
	public var lifespan:Float = 1;
	public var markedForDeath:Bool = false;

	public var age(default, null):Float = 0;
    public var v:Pair<Float> = [0, 0];
	public var alphaRange:Pair<Float> = [1, 1];
	public var onUpdate:NovaParticle -> Void = null;

	var _delta:Float = 0;
	var percent:Float = 0;
	
	/**
	 * Instantiate a new particle. Like `FlxSprite`, all meaningful creation
	 * happens during `loadGraphic()` or `makeGraphic()` or whatever.
	 */
	@:keep
	public function new(sprite:FlxSprite) {
		super(sprite);
	}

	override public function destroy():Void {
		super.destroy();
	}
	
	public function get_animation():FlxAnimationController {
		return _sprite.animation;
	}

    public function setSolidColor(rgb:Int) {
        var c = FlxColor.fromInt(rgb);
        this._sprite.setColorTransform(
            0, 0, 0, 1,
            c.red, c.green, c.blue
        );
    }
	
	override public function update(elapsed:Float):Void {
		if (age < lifespan) {
			age += elapsed;
		}
		
		if (age >= lifespan && lifespan != 0) {
			markedForDeath = true;
			return;
		}
		else {
			_delta = elapsed / lifespan;
			percent = age / lifespan;
			
			if (onUpdate != null) {
				onUpdate(this);
			}
			
			if (alpha != 0) {
				alpha = alphaRange.x + percent * (alphaRange.y - alphaRange.x);
			}
			
			/*if (colorRange.active) {
				color = FlxColor.interpolate(colorRange.start, colorRange.end, percent);
			}*/
		}

		super.update(elapsed);

		if (_sprite.animation.curAnim != null && _sprite.animation.curAnim.numFrames > 1 && _sprite.animation.finished) {
			markedForDeath = true;
		}
	}
	
	override public function reset(X:Float, Y:Float):Void {
		super.reset(X, Y);
		age = 0;
		markedForDeath = false;
		visible = true;
	}
	
	/**
	 * Triggered whenever this object is launched by a `FlxEmitter`.
	 * You can override this to add custom behavior like a sound or AI or something.
	 */
	public function onEmit():Void {}
}
