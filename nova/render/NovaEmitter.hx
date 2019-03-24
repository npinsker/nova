package nova.render;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRangeBounds;
import nova.render.FlxLocalSprite;
import nova.utils.Pair;
import openfl.display.BitmapData;

using nova.utils.ArrayUtils;

typedef ParticleOptions = {
	@:optional var autoBuffer:Bool;
	@:optional var frameRate:Int;
	@:optional var looping:Bool;
};

/**
 * NovaEmitter is an enhanced FlxEmitter.
 * 
 * It supports particles from multiple different sprites, colorTransforms, and more.
 */
class NovaEmitter extends FlxLocalSprite {
	private var _timer:Float = 0;
	private var _waitForKill:Bool = false;
	public var markForDeletion:Bool = false;
	
	public var emitting:Bool = true;
	public var limit:Int = -1;
	
	public var particles:Array<NovaParticle>;
	
	public var lifespan:Pair<Float> = [1, 1];
	public var speed:Pair<Float> = [300, 300];
	public var launchAngle:Pair<Float> = [0, 2 * Math.PI];
	public var startAlpha:Pair<Float> = [1.0, 1.0];
	public var endAlpha:Pair<Float> = null;
	public var rate:Float = 0;
	
	public var onCreate:NovaParticle -> Void = null;
	public var onFinished:Void -> Void = null;
	
	public var colorTransformR:Pair<Float> = [0.0, 0.0];
	public var colorTransformG:Pair<Float> = [0.0, 0.0];
	public var colorTransformB:Pair<Float> = [0.0, 0.0];
	
	public static var DEFAULT_PARTICLE_FPS:Int = 9;
	
	/**
	 * Creates a new `FlxTypedEmitter` object at a specific position.
	 * Does NOT automatically generate or attach particles!
	 * 
	 * @param   X      The X position of the emitter.
	 * @param   Y      The Y position of the emitter.
	 * @param   Size   Optional, specifies a maximum capacity for this emitter.
	 */
	public function new(X:Float = 0.0, Y:Float = 0.0, limit:Int = -1) {
		super();
		
		particles = new Array<NovaParticle>();
		this.xy = [X, Y];
		this.limit = limit;
	}
	
	override public function destroy():Void {
		lifespan = null;
		speed = null;
		launchAngle = null;
		startAlpha = null;
		endAlpha = null;
		colorTransformR = null;
		colorTransformG = null;
		colorTransformB = null;
		
		super.destroy();
	}

	function loadParticle(Graphics:BitmapData, Quantity:Int, bakedRotationAngles:Int,
	                      graphicsTableDims:Pair<Int> = null,
						  getFrames:Void -> Array<Int> = null,
						  Options:ParticleOptions):FlxParticle {
		var particle:FlxParticle = new FlxParticle();
		
		if (FlxG.renderBlit && bakedRotationAngles > 0) {
			particle.loadRotatedGraphic(Graphics, bakedRotationAngles, 1, false,
				(Options != null && Reflect.hasField(Options, 'autoBuffer') ? Options.autoBuffer : false));
		} else if (graphicsTableDims == null || (graphicsTableDims.x == 1 && graphicsTableDims.y == 1)) {
			particle.loadGraphic(Graphics, false);
		} else {
			particle.loadGraphic(Graphics, true, Std.int(Graphics.width / graphicsTableDims.x), Std.int(Graphics.height / graphicsTableDims.y));
			if (getFrames == null) {
				particle.animation.frameIndex = 0;
			} else {
				var res:Array<Int> = getFrames();
				particle.animation.add('normal', res,
					(Options != null && Reflect.hasField(Options, 'frameRate') ? Options.frameRate : DEFAULT_PARTICLE_FPS),
					(Options != null && Reflect.hasField(Options, 'looping') ? Options.looping : false));
				particle.animation.play('normal');
			}
		}
		
		return particle;
	}

	public function addParticles(Graphics:BitmapData, Quantity:Int = 50, bakedRotationAngles:Int = 1,
								 graphicsTableDims:Pair<Int> = null,
							     getFrames:Void -> Array<Int> = null,
								 options:ParticleOptions = null):NovaEmitter {
		var totalFrames:Int = 1;
			
		for (i in 0...Quantity) {
			particles.push(new NovaParticle(loadParticle(Graphics, Quantity, bakedRotationAngles, graphicsTableDims, getFrames, options)));
		}
		
		particles.randomShuffle();
		
		return this;
	}

	public function addSimpleParticles(color:Int = 0, sideLength:Int = 3, Quantity:Int = 50):NovaEmitter {
		var squareBD = new BitmapData(sideLength, sideLength);
		squareBD.fillRect(squareBD.rect, color);
		
		return addParticles(squareBD, Quantity);
	}
	
	function tryEmit():Void {
		if (particles.length == 0) {
			return;
		}
		if (limit == 0) {
			return;
		} else if (limit > 0) {
			--limit;
		}
		emitParticle(particles[particles.length - 1]);
		particles.splice(particles.length - 1, 1);
		
		if (limit == 0) {
			_waitForKill = true;
			emitting = false;
			if (onFinished != null) onFinished();
		}
	}
	
	override public function update(elapsed:Float):Void {
		if (markForDeletion) return;
		
		if (emitting) {
			if (rate <= 0) {
				tryEmit();
			}
			else {
				_timer += elapsed;
				
				while (_timer > rate) {
					_timer -= rate;
					tryEmit();
				}
			}
		}
		else if (_waitForKill) {
			_timer += elapsed;
			
			if ((lifespan.y > 0) && (_timer > lifespan.y)) {
				markForDeletion = true;
				return;
			}
		}
		
		super.update(elapsed);
		
		var i = children.length - 1;
		while (i >= 0) {
			var c = children[i];
			var cp = cast(c, NovaParticle);
			if (cp.markedForDeath) {
				cp.reset(0, 0);
				particles.push(cp);
				children.remove(c);
			}
			--i;
		}
	}
	
	public function emitParticle(particle:NovaParticle):NovaParticle {
		if (Math.abs(colorTransformR.x) > 1e-6 || Math.abs(colorTransformG.x) > 1e-6 || Math.abs(colorTransformB.x) > 1e-6) {
			var adjustR = FlxG.random.float(colorTransformR.x, colorTransformR.y);
			var adjustG = FlxG.random.float(colorTransformG.x, colorTransformG.y);
			var adjustB = FlxG.random.float(colorTransformB.x, colorTransformB.y);
			particle.setColorTransform(1.0, 1.0, 1.0, 1.0, Std.int(adjustR), Std.int(adjustG), Std.int(adjustB), 0);
		}
		particle.lifespan = lifespan.x + Math.random() * (lifespan.y - lifespan.x);
		var startAlphaV:Float = startAlpha.x + Math.random() * (startAlpha.y - startAlpha.x);
		var speedV:Float = speed.x + Math.random() * (speed.y - speed.x);
		var launchV:Float = launchAngle.x + Math.random() * (launchAngle.y - launchAngle.x);
		var endAlphaV:Float = (endAlpha != null ? endAlpha.x + Math.random() * (endAlpha.y - endAlpha.x) : startAlphaV);
		particle.alphaRange = [startAlphaV, endAlphaV];
		particle.alpha = particle.alphaRange.x;
		particle.velocity.set(speedV * Math.cos(launchV), speedV * Math.sin(launchV));
		
		if (onCreate != null) {
			onCreate(particle);
		}
		add(particle);
		
		return particle;
	}
}
