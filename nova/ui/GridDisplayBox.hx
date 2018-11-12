package nova.ui;

using nova.animation.Director;

import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo;
import nova.render.FlxLocalSprite;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import nova.input.InputController;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.filters.ColorMatrixFilter;
import openfl.filters.GlowFilter;

using nova.utils.StructureUtils;

class GridDisplayBox extends FlxLocalSprite {
	public var bitmapData:BitmapData;
	public var bgBitmapData:BitmapData;
	public var bg:LocalSpriteWrapper;
	public var checked:LocalSpriteWrapper;
	public var checkedVisible:Bool = false;
	public var options:Dynamic;
	
	public function new(bitmapData:BitmapData, item:Dynamic, options:Dynamic) {
		super();
		this.bitmapData = bitmapData;
		this.options = options;
		
		width = (options.prop('width') != null ? options.prop('width') : 48);
		height = (options.prop('height') != null ? options.prop('height') : 48);
		
		bg = new LocalSpriteWrapper(new FlxSprite());
		if (Reflect.hasField(options, 'bgBitmapData')) {
			bgBitmapData = options.bgBitmapData;
		} else {
			bgBitmapData = new BitmapData(Std.int(width), Std.int(height), false, 0x999999);
		}
		bg._sprite.loadGraphic(bgBitmapData);
		add(bg);
		
		var fg = new FlxSprite();
		fg.loadGraphic(bitmapData);
		var lbd = new LocalSpriteWrapper(fg);
		add(lbd);
		lbd.x = (width - bitmapData.width) / 2;
		lbd.y = (height - bitmapData.height) / 2;
		
		var cs = new FlxSprite();
		cs.loadGraphic(BitmapDataUtils.getSpriteFromSheetFn(Assets.getBitmapData('assets/images/bobs.png'), [20, 20])([0, 0]));
		checked = new LocalSpriteWrapper(cs);
		checked.x = 40;
		checked.y = 0;
	}
	
	public function focus() {
		var nbg = new BitmapData(bgBitmapData.width + 30, bgBitmapData.height + 30, true, 0);
		nbg.copyPixels(bgBitmapData, bgBitmapData.rect, new Point(15, 15));
		nbg.applyFilter(nbg, nbg.rect, new Point(0, 0), new GlowFilter(0x00FF00, 1, 20, 20, 5, 1, false, true));
		nbg.applyFilter(nbg, nbg.rect, new Point(0, 0),
			new ColorMatrixFilter([0, 0, 0, 0, 255, 0, 0, 0, 0, 255, 0, 0, 0, 0, 63, 0, 0, 0, 0.75, 0]));
		nbg.copyPixels(bgBitmapData, bgBitmapData.rect, new Point(15, 15));
		bgBitmapData = nbg;
		bg._sprite = new FlxSprite();
		bg._sprite.loadGraphic(bgBitmapData);
		bg.x = -15;
		bg.y = -15;
	}

	public function loseFocus() {
		if (Reflect.hasField(options, 'bgBitmapData')) {
			bgBitmapData = options.bgBitmapData;
		} else {
			bgBitmapData = new BitmapData(Std.int(width), Std.int(height), false, 0x999999);
		}
		bg._sprite = new FlxSprite();
		bg._sprite.loadGraphic(bgBitmapData);
		bg.x = 0;
		bg.y = 0;
	}
	
	public function setChecked(visible:Bool) {
		if (checkedVisible != visible) {
			checkedVisible = visible;
			if (checkedVisible) {
				add(checked);
			} else {
				remove(checked);
			}
		}
	}
}