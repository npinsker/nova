package nova.render;
import flash.display.BitmapData;
import flixel.math.FlxRect;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;

/**
 * Utilities for working with "9-slice" bitmaps.
 */
class NineSliceBitmapGen {
	public var bitmapData:BitmapData;
	public var centerRect:Pair<Int>;
	
	public function new(bitmapData:BitmapData, centerRect:Pair<Int>) {
		this.bitmapData = bitmapData;
		this.centerRect = centerRect;
	}
	
	public function generateBitmap(dimensions:Pair<Int>) {
		var borderWidth:Int = Std.int((bitmapData.width - centerRect.x) / 2);
		var borderHeight:Int = Std.int((bitmapData.height - centerRect.y) / 2);
		var widthStretched:BitmapData = BitmapDataUtils.horizontalStretchCenter(this.bitmapData, borderWidth, dimensions.x);
		return BitmapDataUtils.verticalStretchCenter(widthStretched, borderHeight, dimensions.y);
	}
}
