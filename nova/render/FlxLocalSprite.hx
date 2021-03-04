package nova.render;

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

typedef LocalSpriteWrapper = LocalWrapper<FlxSprite>;

typedef LoadGraphicOptions = {
  /**
    * Two integer pairs representing a region to crop.
    * The first specifies the top-left corner, and the second specifies the width and height
    * of the area to crop.
    */
    @:optional var crop:Array<Pair<Int>>;

  /**
    * The (width, height) amount to scale the graphic by.
    */
    @:optional var scale:Pair<Float>;

    /**
    * Information about animation frames.
      * The 'animation' array is a quick way to initialize and play a single animation for
      * sprites that don't need multiple animations.
      * If `frameSize` is not set, then we assume the largest integer N in the 'animation'
      * array is the total number of frames. We also assume the loaded bitmap is a 1xN array.
      * If more complicated animation behavior is desired, then setting `frameSize` will mark the
      * sprite as animated, but you'll need to add individual animations just like in Flixel.
    */
    @:optional var animation:Array<Int>;
    @:optional var frameSize:Pair<Int>;
    @:optional var frameRate:Int;
};

/**
 * A `FlxLocalSprite` wrapper around a `FlxSprite`.
 *
 * In many cases, this can be initialized directly using `LocalWrapper.fromGraphic`.
 */
class LocalWrapper<T:FlxSprite> extends FlxLocalSprite {
    public var _sprite:T;

    public function new(sprite:T) {
        // Would be nice if this code could be rewritten to use composition,
    // but we need it to behave like a FlxSprite for easier interfacing with Flixel.
        var recordSpritePosn:Pair<Float> = [sprite.x, sprite.y];
        _sprite = sprite;
        animation = _sprite.animation;

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

    override public function add(Sprite:FlxSprite, relative:Bool = true, below:Bool = false) {
        trace("Cannot add sprite " + Sprite + " to FlxLocalSprite " + this);
    }

    override function set_x(Value:Float):Float {
        x = Value;
        return Value;
    }

    override function set_y(Value:Float):Float {
        y = Value;
        return Value;
    }

    function set_scale(Value:FlxPoint):FlxPoint {
        scale = Value;
        if (!_skipTransformChildren) {
            _sprite.scale = Value;
        }
        return Value;
    }

    override function set_alpha(Value:Float):Float {
        alpha = Value;
        if (!_skipTransformChildren) {
            _sprite.alpha = Value * globalAlpha;
        }
        return Value;
    }

    override function set_camera(Value:FlxCamera):FlxCamera {
        if (!_skipTransformChildren) {
          _sprite.set_camera(Value);
        }

        return Value;
    }

    @:noCompletion
    override function get_pixels():BitmapData {
        return _sprite.get_pixels();
    }

    @:noCompletion
    override function set_pixels(Pixels:BitmapData):BitmapData {
        return _sprite.set_pixels(Pixels);
    }

    override function updateColorTransform():Void {
        _sprite.alpha = alpha * globalAlpha;
    }

    override public function draw():Void {
        if (this.visible) {
            _sprite.alpha = alpha * globalAlpha;
            _sprite.x = globalX;
            _sprite.y = globalY;
            _sprite.draw();
        }

        #if FLX_DEBUG
        if (FlxG.debugger.drawDebug)
            drawDebug();
        #end
    }

    override public function destroy():Void {
        _sprite.destroy();

        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        _sprite.updateAnimation(elapsed);
    }

  /**
    * A quick and easy method to create a `LocalSpriteWrapper` from parameters.
    * See `LoadGraphicOptions` for the full parameter list.
    *
    * Basic usage:
    *
    * var sprite = LocalWrapper.fromGraphic('bitmap.png', {
    *   'crop': [[48, 16], [16, 16]],
    *   'scale': [4, 4],
    * });
    *
    * @param graphic The graphic asset to load from. Can be a string or BitmapData object.
    * @param options Additional configuration information for the sprite.
    * @returns A LocalSpriteWrapper created according to the supplied options.
    */
    public static function fromGraphic(graphic:FlxGraphicAsset, ?options:LoadGraphicOptions):LocalSpriteWrapper {
        var graphic:FlxGraphic = FlxG.bitmap.add(graphic, false, null);

        var bitmap:BitmapData = graphic.bitmap;

        if (options == null) {
            return new LocalSpriteWrapper(new FlxSprite().loadGraphic(bitmap));
        }

        if (options.crop != null) {
            bitmap = BitmapDataUtils.crop(bitmap, options.crop[0], options.crop[1]);
        }
        if (options.scale != null) {
            bitmap = BitmapDataUtils.scaleFn(options.scale.x, options.scale.y)(bitmap);
        }

        #if desktop
        // haxe -> C++ is weird yo
        var frameSizeNull:Bool = (!(options.frameSize == null) && !(options.frameSize != null));
        #else
        var frameSizeNull:Bool = (options.frameSize == null);
        #end
        if (frameSizeNull && options.animation == null) {
            return new LocalSpriteWrapper(new FlxSprite().loadGraphic(bitmap));
        }

        if (options.animation != null) {
            // quick initialization
            var bitmapData:BitmapData = FlxG.bitmap.add(bitmap).bitmap;

            var frameWidth:Int = Std.int(bitmapData.width / (ArrayUtils.max(options.animation) + 1));
            var frameHeight:Int = bitmapData.height;

            var wrapper = new LocalSpriteWrapper(new FlxSprite().loadGraphic(bitmapData, true, frameWidth, frameHeight));
            wrapper._sprite.animation.add('default', options.animation, (options.frameRate != null ? options.frameRate : 60));
            wrapper._sprite.animation.play('default');

            return wrapper;
        }

        var frameSizeX:Int = Std.int(options.frameSize.x * (options.scale != null ? options.scale.x : 1));
        var frameSizeY:Int = Std.int(options.frameSize.y * (options.scale != null ? options.scale.y : 1));

        var wrapper = new LocalSpriteWrapper(new FlxSprite().loadGraphic(bitmap, true, frameSizeX, frameSizeY));
        return wrapper;
    }
}

/**
 * A sprite class that contains a display hierarchy.
 *
 * If your sprite doesn't need to have children, or needs to inherit from a class other than `FlxSprite`
 * (e.g. `FlxText`), using the `LocalWrapper` class is recommended over this one.
 *
 * To add to and remove children from a `FlxLocalSprite`, use its `add` and `remove` methods respectively.
 * A `FlxLocalSprite` can only contain other `FlxLocalSprite`s as children.
 */
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

    public var topLeftBounds:Pair<Float> = null;

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

    public function _recomputeBounds() {
        if (children.length == 0) {
            return;
        }

        topLeftBounds = [children[0].x, children[0].y];
        var bottomRightBounds:Pair<Float> = [0, 0];
        if (_frame != null) {
            bottomRightBounds = [_frame.frame.width, _frame.frame.height];
        }

        for (child in children) {
            topLeftBounds.x = Math.min(topLeftBounds.x, child.x);
            topLeftBounds.y = Math.min(topLeftBounds.y, child.y);
            bottomRightBounds.x = Math.max(bottomRightBounds.x, child.x + child.width);
            bottomRightBounds.y = Math.max(bottomRightBounds.y, child.y + child.height);
        }
        width = bottomRightBounds.x - topLeftBounds.x;
        height = bottomRightBounds.y - topLeftBounds.y;

        if (this.parent != null) {
            this.parent._recomputeBounds();
        }
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

        _recomputeBounds();
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
            var r = children.remove(cast(sprite, FlxLocalSprite));
            _recomputeBounds();
            return r;
        } else {
            for (i in 0...children.length) {
                if (Std.is(children[i], LocalSpriteWrapper)) {
                    var localSprite = cast(children[i], LocalWrapper<Dynamic>);
                    if (localSprite._sprite == sprite) {
                        localSprite._sprite.x += globalX;
                        localSprite._sprite.y += globalY;
                        remove(localSprite);
                        _recomputeBounds();
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
        if (this.parent != null) {
            this.parent._recomputeBounds();
        }
        return x;
    }

    override function set_y(Value:Float):Float {
        y = Value;
        if (!_skipTransformChildren) {
            _percolate(function(n:FlxLocalSprite, v:Float) { n.globalOffset.y = v; },
                       function(n:FlxLocalSprite) { return n.globalOffset.y + n.y; });
        }
        if (this.parent != null) {
            this.parent._recomputeBounds();
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
