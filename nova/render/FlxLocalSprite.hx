package nova.render;

import flixel.FlxCamera;
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
class FlxLocalSprite extends FlxSprite {
	public var globalOffset:Pair<Float>;
	public var children:Array<FlxLocalSprite>;

	var _skipTransformChildren:Bool = false;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset) {
		globalOffset = [0, 0];
		children = new Array<FlxLocalSprite>();
		
		super(X, Y, SimpleGraphic);
	}
	
	public var globalX(get, set):Float;
	public var globalY(get, set):Float;
	
	public function preAdd(Sprite:FlxLocalSprite, relative:Bool) {
		Sprite.globalOffset = [globalOffset.x + x, globalOffset.y + y];
		if (!relative) {
			Sprite.x -= globalOffset.x;
			Sprite.y -= globalOffset.y;
		}
	}
	
	public function add(Sprite:FlxLocalSprite, relative:Bool = true):Int {
		preAdd(Sprite, relative);
		return children.push(Sprite);
	}
	
	public function remove(sprite:FlxLocalSprite, Splice:Bool = false):Bool {
		sprite.x += globalOffset.x;
		sprite.y += globalOffset.y;
		sprite.cameras = null;
		return children.remove(sprite);
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
		trace(_flashPoint);
		camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
	}
	
	
	
	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);
		
		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			
			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		
		_point.add(origin.x, origin.y);		
		_matrix.translate(_point.x + globalOffset.x, _point.y + globalOffset.y);
		
		if (isPixelPerfectRender(camera))
		{
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
}