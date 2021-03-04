package nova.graphics;

import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Point;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxImageFrame;
import nova.utils.Rectangle;


class BitmapDataPointer {
    public var bitmapData:BitmapData;
    public var area:Rectangle<Int>;

    public var code:String;

    public function new(bitmapData:BitmapData, area:Rectangle<Int> = null) {
        this.bitmapData = bitmapData;
        this.area = area;

        this.code = (area != null ? area.toString() : "");
    }

    public function makeGraphic():FlxGraphic {
        var imageFrame:FlxImageFrame = FlxImageFrame.fromGraphic(
            FlxGraphic.fromBitmapData(this.bitmapData, false, null, false),
            this.area
        );
        return FlxGraphic.fromFrame(imageFrame.frame, false, null, false);
    }
}
