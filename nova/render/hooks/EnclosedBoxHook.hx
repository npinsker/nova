package nova.render.hooks;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSort;
import nova.utils.ArrayUtils;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class FlxLocalSprite extends FlxSprite {
  @:noCompletion
	public var globalOffset:Pair<Float>;

  @:noCompletion
	public var globalAlpha:Float;

  /**
    * The children of this FlxLocalSprite.
    * They are rendered in increasing order of index, with the last child being on top.
    */
	public var children:Array<FlxLocalSprite>;

  /**
    * The parent of this FlxLocalSprite, if it exists.
    */
	public var parent:FlxLocalSprite = null;

	#if debug
	public var debugTag:String = null;
	#end

	var _skipTransformChildren:Bool = false;
	
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset) {
		globalOffset = [0, 0];
		globalAlpha = 1;
		children = new Array<FlxLocalSprite>();
		
		super(X, Y, SimpleGraphic);
	}
	
  /**
    * The global x position of the sprite (where it is rendered on screen).
    */
	public var globalX(get, set):Float;

  /**
    * The global y position of the sprite (where it is rendered on screen).
    */
	public var globalY(get, set):Float;
	
  /**
    * The (x, y) position of the sprite as a float pair.
    */
	public var xy(get, set):Pair<Float>;

  /**
    * The (width, height) of the sprite as an integer pair.
    */
	public var wh(get, never):Pair<Int>;
	
	@:noCompletion
	override function checkEmptyFrame() {
		return;
	}
	
  @:noCompletion
	public function preAdd(Sprite:FlxLocalSprite, relative:Bool) {
		Sprite.globalOffset = [globalOffset.x + x, globalOffset.y + y];
		Sprite.globalAlpha = globalAlpha * alpha;
		
		if (!relative) {
			Sprite.x -= globalOffset.x;
			Sprite.y -= globalOffset.y;
			Sprite.alpha /= globalAlpha;
		} else {
			// needed to trigger percolation
			Sprite.x = Sprite.x;
			Sprite.y = Sprite.y;
			Sprite.alpha = Sprite.alpha;
		}
    Sprite.camera = camera;
		Sprite.parent = this;
	}
	
  /**
    * Adds a FlxSprite as a direct child of this.
    *
    * If the adding sprite is not already a FlxLocalSprite, it will be wrapped by a
    * LocalSpriteWrapper before being added. Note that this means the original sprite
    * will *not* be a child of this one.
    */
	public function add(Sprite:FlxSprite, relative:Bool = true, below:Bool = false) {
		var castSprite:FlxLocalSprite;
		if (Std.is(Sprite, FlxLocalSprite)) {
			castSprite = cast(Sprite, FlxLocalSprite);
		} else {
			castSprite = new LocalSpriteWrapper(Sprite);
		}
		
		preAdd(castSprite, relative);
		if (below) {
			children.unshift(castSprite);
		} else {
			children.push(castSprite);
		}
	}
	
  /**
    * Removes a FlxSprite that is a direct child of this one from the display hierarchy.
    *
    * If the sprite is not a FlxLocalSprite, then the LocalSpriteWrapper wrapping this
    * object will be removed (if it exists).
    */
	public function remove(sprite:FlxSprite, Splice:Bool = false):Bool {
		if (Std.is(sprite, FlxLocalSprite)) {
			sprite.cameras = null;
			cast(sprite, FlxLocalSprite).parent = null;
			return children.remove(cast(sprite, FlxLocalSprite));
		} else {
			for (i in 0...children.length) {
				if (Std.is(children[i], LocalSpriteWrapper)) {
					var localSprite = cast(children[i], LocalWrapper<Dynamic>);
					if (localSprite._sprite == sprite) {
						localSprite._sprite.x += globalX;
						localSprite._sprite.y += globalY;
						remove(localSprite);
						return true;
					}
				}
			}
		}
		return false;
	}
	
	override public function isOnScreen(?Camera:FlxCamera):Bool {
		var minX = this.globalX;
		var minY = this.globalY;
		var maxX = this.globalX + this.width;
		var maxY = this.globalY + this.height;
		
		return (minX <= FlxG.camera.scroll.x + FlxG.width || maxX >= FlxG.camera.scroll.x) &&
		       (minY <= FlxG.camera.scroll.y + FlxG.height && maxY >= FlxG.camera.scroll.y);
	}
	
	override public function draw():Void {
		if (_frame != null) {
			super.draw();
		}
		
		for (child in children) {
			if (child.visible) {
				child.draw();
			}
		}
		
		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}
	
  @:noCompletion
	public inline function sort(Function:FlxLocalSprite->FlxLocalSprite->Int):Void {
		children.sort(Function);
	}
	
	override function set_x(Value:Float):Float {
		x = Value;
		if (!_skipTransformChildren) {
			_percolate(function(n:FlxLocalSprite, v:Float) { n.globalOffset.x = v; },
					   function(n:FlxLocalSprite) { return n.globalOffset.x + n.x; });
		}
		return x;
	}
	
	override function set_y(Value:Float):Float {
		y = Value;
		if (!_skipTransformChildren) {
			_percolate(function(n:FlxLocalSprite, v:Float) { n.globalOffset.y = v; },
					   function(n:FlxLocalSprite) { return n.globalOffset.y + n.y; });
		}
		return y;
	}
	
	override function set_alpha(Value:Float):Float {
		alpha = Value;
		
		if (!_skipTransformChildren) {
			_percolate(function(n:FlxLocalSprite, v:Float) { n.globalAlpha = v; n.updateColorTransform(); },
					   function(n:FlxLocalSprite) { return n.globalAlpha * n.alpha; });
		}
		return Value;
	}
  
	override function set_camera(Value:FlxCamera):FlxCamera {
    if (!_skipTransformChildren) {
      for (child in children) {
        child.set_camera(Value);
      }
    }
    
    return super.set_camera(Value);
  }
	
	override function updateColorTransform():Void {
		if (colorTransform == null)
			colorTransform = new ColorTransform();

		useColorTransform = (alpha * globalAlpha) != 1 || color != 0xffffff;
		if (useColorTransform)
			colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha * globalAlpha);
		else
			colorTransform.setMultipliers(1, 1, 1, 1);
		
		dirty = true;
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
	
  @:noCompletion
	public function get_xy():Pair<Float> {
		return [this.x, this.y];
	}
	
  @:noCompletion
	public function set_xy(xy:Pair<Float>):Pair<Float> {
		this.x = xy.x;
		this.y = xy.y;
		return xy;
	}
	
  @:noCompletion
	public function get_wh():Pair<Int> {
		return [Std.int(width), Std.int(height)];
	}
	
  /**
    * Sets the (x, y) position of the parent without modifying the position of the children.
    */
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

	override public function destroy():Void {
        for (child in this.children) {
            child.destroy();
        }
		super.destroy();
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		
		for (child in children) {
			child.update(elapsed);
		}
	}
	
	override public function toString():String {
		#if debug
		if (debugTag != null) {
			return '[' + debugTag + ']: ' + super.toString();
		}
		#end
		return super.toString();
	}
}
