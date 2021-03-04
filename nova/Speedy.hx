package nova;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import openfl.display.Sprite;

import nova.render.FlxLocalSprite;
import nova.ui.text.TextFormat;

class Speedy {
    public static function makeSprite(graphic:FlxGraphicAsset,
                                      ?options:LoadGraphicOptions):LocalSpriteWrapper {
        return LocalWrapper.fromGraphic(graphic, options);
    }

    public static function playLoop(wrapper:LocalSpriteWrapper, fps:Int = 60) {
        var sp:FlxSprite = wrapper._sprite;
        sp.animation.add('_loop', [for (i in 0...sp.animation.frames) i], fps);
        sp.animation.play('_loop');
    }

    public static function goToAndStop(wrapper:LocalSpriteWrapper, frame:Int) {
        var sp:FlxSprite = wrapper._sprite;
        sp.animation.stop();
        sp.animation.frameIndex = frame;
    }

    public static function makeText(text:String, ?options:TextFormat):LocalWrapper<FlxText> {
        var tf:LocalWrapper<FlxText> = new LocalWrapper<FlxText>(new FlxText());
        if (options != null) {
            TextFormatUtils.setTextFormat(tf._sprite, options);
        }
        return tf;
    }
}
