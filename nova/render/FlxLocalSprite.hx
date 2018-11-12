package nova.render;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxAngle;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSort;
import nova.utils.Pair;

/**
 * ...
 * @author Nathan Pinsker
 */

typedef LocalSpriteWrapper = LocalWrapper<FlxSprite>;

class LocalWrapper<T:FlxSprite> extends FlxLocalSprite {
	public var _sprite:T;
	
	public function new(sprite:T) {
		var recordSpritePosn:Pair<Float> = [sprite.x, sprite.y];
		_sprite = sprite;
		
		super();
		
		x = recordSpritePosn.x;
		y = recordSpritePosn.y;
		width = sprite.width;
		height = sprite.height;
	}
	
	@:from
	public function toT(sprite:T):LocalWrapper<T> {
		return new LocalWrapper<T>(sprite);
	}
	
	override function set_x(Value:Float):Float {
		x = Value;
		if (!_skipTransformChildren) {
			_sprite.x = globalX;
		}
		return Value;
	}
	
	override function set_y(Value:Float):Float {
		y = Value;
		if (!_skipTransformChildren) {
			_sprite.y = globalY;
		}
		return Value;
	}
	
	override function set_alpha(Value:Float):Float {
		alpha = Value;
		if (!_skipTransformChildren) {
			_sprite.alpha = Value;
		}
		return Value;
	}
	
	override public function draw():Void {
		_sprite.draw();
		
		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	override public function destroy():Void {
		_sprite.destroy();
		
		super.destroy();
	}
}

class FlxLocalSprite extends FlxSprite {
	public var globalOffset:Pair<Float>;
	public var globalAlpha:Float;
	public var children:Array<FlxLocalSprite>;

	var _skipTransformChildren:Bool = false;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset) {
		globalOffset = [0, 0];
		globalAlpha = 1;
		children = new Array<FlxLocalSprite>();
		
		super(X, Y, SimpleGraphic);
	}
	
	public var globalX(get, set):Float;
	public var globalY(get, set):Float;
	
	public var xy(get, set):Pair<Float>;
	
	@:noCompletion
	override function checkEmptyFrame() {
		return;
	}
	
	public function preAdd(Sprite:FlxLocalSprite, relative:Bool) {
		Sprite.globalOffset = [globalOffset.x + x, globalOffset.y + y];
		if (!relative) {
			Sprite.x -= globalOffset.x;
			Sprite.y -= globalOffset.y;
		}
	}
	
	public function add(Sprite:FlxSprite, relative:Bool = true):Int {
		if (Std.is(Sprite, FlxLocalSprite)) {
			preAdd(cast(Sprite, FlxLocalSprite), relative);
			return children.push(cast(Sprite, FlxLocalSprite));
		}

		var wrapper:LocalSpriteWrapper = new LocalSpriteWrapper(Sprite);
		preAdd(wrapper, relative);
		return children.push(wrapper);
	}
	
	public function remove(sprite:FlxSprite, Splice:Bool = false):Bool {
		if (Std.is(sprite, FlxLocalSprite)) {
			sprite.cameras = null;
			return children.remove(cast(sprite, FlxLocalSprite));
		} else {
			/*for (i in 0...children.length) {
				if (Std.is(children[i], LocalSpriteWrapper)) {
					var localSprite = cast(children[i], LocalSpriteWrapper);
					if (localSprite._sprite == sprite) {
						localSprite._sprite.x += globalX;
						localSprite._sprite.y += globalY;
						remove(localSprite);
						return true;
					}
				}
			}*/
		}
		return false;
	}
	
	override public function draw():Void {
		if (_frame != null) {
			super.draw();
		}
		
		for (child in children) {
			child.draw();
		}
		
		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
	public inline function sort(Function:FlxLocalSprite->FlxLocalSprite->Int):Void {
		children.sort(Function);
	}
	
	override function set_x(Value:Float):Float {
		if (!_skipTransformChildren) {
			for (child in children) {
				_percolate(function(n:FlxLocalSprite, v:Float) { n.globalOffset.x = v; },
						   function(n:FlxLocalSprite) { return n.globalOffset.x + n.x; });
			}
		}
		return x = Value;
	}
	
	override function set_y(Value:Float):Float {
		if (!_skipTransformChildren) {
			for (child in children) {
				_percolate(function(n:FlxLocalSprite, v:Float) { n.globalOffset.y = v; },
						   function(n:FlxLocalSprite) { return n.globalOffset.y + n.y; });
			}
		}
		return y = Value;
	}
	
	@:noCompletion
	override function set_alpha(Value:Float):Float {
		if (!_skipTransformChildren) {
			for (child in children) {
				_percolate(function(n:FlxLocalSprite, v:Float) { n.globalAlpha = v; },
						   function(n:FlxLocalSprite) { return n.globalAlpha * n.alpha; });
			}
		}
		return super.set_alpha(Value);
	}
	
	function get_globalX():Float {
		return globalOffset.x + x;
	}
	
	function set_globalX(v:Float):Float {
		x = v - globalOffset.x;
		return v;
	}
	
	function get_globalY():Float {
		return globalOffset.y + y;
	}
	
	function set_globalY(v:Float):Float {
		y = v - globalOffset.y;
		return v;
	}
	
	public function get_xy():Pair<Float> {
		return [this.x, this.y];
	}
	
	public function set_xy(xy:Pair<Float>):Pair<Float> {
		this.x = xy.x;
		this.y = xy.y;
		return xy;
	}
	
	public function setPositionNoChildren(pos:Pair<Float>) {
		for (child in children) {
			child._skipTransformChildren = true;
			child.x += (x - pos.x);
			child.y += (y - pos.y);
			child._skipTransformChildren = false;
		}

		_skipTransformChildren = true;
		x = pos.x;
		y = pos.y;
		_skipTransformChildren = false;
	}
	
	@:noCompletion
	override function drawSimple(camera:FlxCamera):Void {
		if (isPixelPerfectRender(camera))
			_point.floor();
		
		_flashPoint.x = _point.x + globalOffset.x;
		_flashPoint.y = _point.y + globalOffset.y;
		camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
	}
	
	
	
	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void {
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		
		if (bakedRotationAngle <= 0) {
			updateTrig();
			
			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		
		_point.add(origin.x, origin.y);		
		_matrix.translate(_point.x + globalOffset.x, _point.y + globalOffset.y);
		
		if (isPixelPerfectRender(camera)) {
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}
		
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}
	
	function _percolate(applyFn:FlxLocalSprite -> Float -> Void, computeFn:FlxLocalSprite -> Float) {
		for (child in children) {
			applyFn(child, computeFn(this));
			child._percolate(applyFn, computeFn);
		}
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		
		for (child in children) {
			child.update(elapsed);
		}
	}
}