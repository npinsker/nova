package nova;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxParticle;
import flixel.effects.particles.FlxEmitter;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRangeBounds;

typedef FlxEmitter = FlxTypedEmitter<FlxParticle>;

/**
 * NovaEmitter is an enhanced FlxEmitter.
 * 
 * It supports particles from multiple different sprites, colorTransforms, and more.
 */
class NovaEmitter extends FlxEmitter {
	
	public var colorTransformR(default, null):FlxRangeBounds<Float> = new FlxRangeBounds<Float>(0.0, 0.0);
	public var colorTransformG(default, null):FlxRangeBounds<Float> = new FlxRangeBounds<Float>(0.0, 0.0);
	public var colorTransformB(default, null):FlxRangeBounds<Float> = new FlxRangeBounds<Float>(0.0, 0.0);
	
	/**
	 * Creates a new `FlxTypedEmitter` object at a specific position.
	 * Does NOT automatically generate or attach particles!
	 * 
	 * @param   X      The X position of the emitter.
	 * @param   Y      The Y position of the emitter.
	 * @param   Size   Optional, specifies a maximum capacity for this emitter.
	 */
	public function new(X:Float = 0.0, Y:Float = 0.0, Size:Int = 0) {
		super(Size);
		
		setPosition(X, Y);
		exists = false;
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		velocity = FlxDestroyUtil.destroy(velocity);
		scale = FlxDestroyUtil.destroy(scale);
		drag = FlxDestroyUtil.destroy(drag);
		acceleration = FlxDestroyUtil.destroy(acceleration);
		_point = FlxDestroyUtil.put(_point);
		
		blend = null;
		angularAcceleration = null;
		angularDrag = null;
		angularVelocity = null;
		angle = null;
		speed = null;
		launchAngle = null;
		lifespan = null;
		alpha = null;
		color = null;
		elasticity = null;
		maxSize = 0;
		
		super.destroy();
	}
	
	/**
	 * This function generates a new array of particle sprites to attach to the emitter.
	 * 
	 * @param   Graphics         If you opted to not pre-configure an array of `FlxParticle` objects,
	 *                           you can simply pass in a particle image or sprite sheet.
	 * @param   Quantity         The number of particles to generate when using the "create from image" option.
	 * @param   BakedRotations   How many frames of baked rotation to use (boosts performance).
	 *                           Set to zero to not use baked rotations.
	 * @param   Multiple         Whether the image in the `Graphics` param is a single particle or a bunch of particles
	 *                           (if it's a bunch, they need to be square!).
	 * @param   AutoBuffer       Whether to automatically increase the image size to accommodate rotated corners.
	 *                           Default is `false`. Will create frames that are 150% larger on each axis than the
	 *                           original frame or graphic.
	 * @return  This `FlxEmitter` instance (nice for chaining stuff together).
	 */
	public function addParticles(Graphics:FlxGraphicAsset, Quantity:Int = 50, bakedRotationAngles:Int = 16,
		Multiple:Bool = false, AutoBuffer:Bool = false):NovaEmitter {
		maxSize += Quantity;
		var totalFrames:Int = 1;
		
		if (Multiple)
		{ 
			var sprite = new FlxSprite();
			sprite.loadGraphic(Graphics, true);
			totalFrames = sprite.numFrames;
			sprite.destroy();
		}
			
		for (i in 0...Quantity)
			add(loadParticle(Graphics, Quantity, bakedRotationAngles, Multiple, AutoBuffer, totalFrames));
		
		return this;
	}
	
	public override function loadParticles(Graphics:FlxGraphicAsset, Quantity:Int = 50, bakedRotationAngles:Int = 16,
		Multiple:Bool = false, AutoBuffer:Bool = false):NovaEmitter { trace("Use addParticles instead!!");  return this;  }
	
	/**
	 * Called automatically by the game loop, decides when to launch particles and when to "die".
	 */
	override public function update(elapsed:Float):Void
	{
		if (emitting)
		{
			if (_explode)
				explode();
			else
				emitContinuously(elapsed);
		}
		else if (_waitForKill)
		{
			_timer += elapsed;
			
			if ((lifespan.max > 0) && (_timer > lifespan.max))
			{
				kill();
				return;
			}
		}
		
		super.update(elapsed);
	}
	
	public override function emitParticle():FlxParticle {
		var particle:FlxParticle = super.emitParticle();
		
		if (colorTransformR.active) {
			var adjustR = FlxG.random.float(colorTransformR.start.min, colorTransformR.start.max);
			var adjustG = FlxG.random.float(colorTransformG.start.min, colorTransformG.start.max);
			var adjustB = FlxG.random.float(colorTransformB.start.min, colorTransformB.start.max);
			particle.setColorTransform(1.0, 1.0, 1.0, 1, Std.int(adjustR), Std.int(adjustG), Std.int(adjustB));
		}
		return particle;
	}
}