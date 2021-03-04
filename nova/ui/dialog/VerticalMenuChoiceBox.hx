package nova.ui.dialog;

import nova.input.Focusable;
import nova.render.FlxLocalSprite;
import nova.ui.Counter;
import nova.ui.GridDisplay;
import nova.ui.dialog.DialogBox;
import nova.ui.dialog.DialogBoxFactory;

import flash.geom.Point;
import flash.geom.Rectangle;
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

using nova.animation.Director;
using nova.render.NineSliceBitmapGen;
using nova.utils.ArrayUtils;
using nova.utils.StructureUtils;

class VerticalMenuChoiceBox extends DialogChoiceBox {
  public var choices:Array<String>;
  public var jumps:Array<String>;
  public var options:Dynamic;
  public var textBlocks:Array<LocalWrapper<FlxText>>;
  public var textSpacing:Int;
  public var selectedIndex:Int = 0;
  public var selectedSprite:LocalSpriteWrapper;
	
	public function new(choices:Array<String>, jumps:Array<String>, ?options:Dynamic) {
		super();

    this.choices = choices;
    this.jumps = jumps;
    this.options = options;
    this.textBlocks = [];
    
    var maxWidth:Float = 0;
    var maxHeight:Float = 0;
    textSpacing = (Reflect.hasField(options, 'textSpacing') ? options.textSpacing : 35);
    for (i in 0...choices.length) {
      var text:String = choices[i];
      var textWrapper = new LocalWrapper<FlxText>(new FlxText(0, 0, 0, text, 24));
      if (Reflect.hasField(options, 'textFormat')) {
        nova.ui.text.TextFormat.TextFormatUtils.setTextFormat(
          textWrapper._sprite, options.textFormat);
      }
      textWrapper.x = 40;
      textWrapper.y = 26 + textSpacing * i;
      maxWidth = Math.max(maxWidth, textWrapper._sprite.width);
      maxHeight = textWrapper.y + textWrapper._sprite.height;
      textBlocks.push(textWrapper);
    }

    if (Reflect.hasField(options, 'background')) {
      // nine-slice bitmap
      var source:String = options.background.image;
      var centerRectDims:Pair<Int> = options.background.centerRect;

      var nineslice = new NineSliceBitmapGen(Assets.getBitmapData(source), centerRectDims);

      var bg:BitmapData = nineslice.generateBitmap([20 + Std.int(maxWidth / 4), Std.int(maxHeight / 4) + 9]);
      if (Reflect.hasField(options.background, 'transform')) {
        bg = options.background.transform(bg);
      }
      width = bg.width;
      height = bg.height;
      add(LocalWrapper.fromGraphic(bg));
    }

    for (textWrapper in textBlocks) {
      add(textWrapper);
    }

    if (Reflect.hasField(options, 'selectSprite')) {
      var selectedBD:BitmapData = Assets.getBitmapData(options.selectSprite.image);
      if (Reflect.hasField(options.selectSprite, 'transform')) {
        selectedBD = options.selectSprite.transform(selectedBD);
      }
      selectedSprite = LocalWrapper.fromGraphic(selectedBD);
    } else {
      selectedSprite = LocalWrapper.fromGraphic(new BitmapData(16, 16, false, 0xFF0000FF));
    }

    add(selectedSprite);
    selectedSprite.xy = [18, 38 - selectedSprite.height / 2];
    
	}

  override public function setPositionFromDB(db:DialogBox) {
    if (Reflect.hasField(options, 'align')) {
      var align:String = options.align.toLowerCase();
      if (align == 'right') {
        this.x = db.width - this.width;
        this.y = -this.height;
      }
    }
    if (Reflect.hasField(options, 'offset')) {
      var offset:Pair<Float> = cast options.offset;
      this.x += offset.x;
      this.y += offset.y;
    }
  }
	
	override public function handleInput():Void {
		if (InputController.justPressed(UP) || InputController.justPressed(DOWN)) {
			if (InputController.justPressed(UP)) {
        selectedIndex -= 1;
        if (selectedIndex < 0) selectedIndex += choices.length;
      } else if (InputController.justPressed(DOWN)) {
        selectedIndex += 1;
        if (selectedIndex >= choices.length) selectedIndex -= choices.length;
      }

      selectedSprite.y = 30 + textSpacing * selectedIndex;
		}
  }

  override public function selectOption():String {
    return jumps[selectedIndex];
	}
}
