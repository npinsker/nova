package nova.graphics;

import openfl.display.BitmapData;
import openfl.display.DisplayObjectRenderer;
import openfl.display.Shader;
import openfl.filters.BitmapFilter;
import openfl.filters.BitmapFilterShader;
import openfl.geom.Point;
import openfl.geom.Rectangle;

#if lime
import lime._internal.graphics.ImageCanvasUtil;
import lime.math.RGBA;
#end

@:final class ColorizeFilter extends BitmapFilter {
	
	
	@:noCompletion private static var __colorizeShader = new ColorizeShader();
	
	public var blackColor:Array<Float>;
	public var whiteColor:Array<Float>;
	
	@:noCompletion private var __color:Array<Float>;
	
	public function new (blackColor:Array<Float> = null, whiteColor:Array<Float> = null) {
		
		super ();
		
		this.blackColor = blackColor;
    this.whiteColor = whiteColor;
		
		__numShaderPasses = 1;
		__needSecondBitmapData = false;
		
	}
	
	
	public override function clone ():BitmapFilter {
		return new ColorizeFilter (blackColor, whiteColor);
	}
	
	
	@:noCompletion private override function __applyFilter (destBitmapData:BitmapData, sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point):BitmapData {
		
		#if lime
		var sourceImage = sourceBitmapData.image; 
		var image = destBitmapData.image;
		
		#if (js && html5)
		ImageCanvasUtil.convertToData (sourceImage);
		ImageCanvasUtil.convertToData (image);
		#end
		
		var sourceData = sourceImage.data;
		var destData = image.data;
		
		var offsetX = Std.int (destPoint.x - sourceRect.x);
		var offsetY = Std.int (destPoint.y - sourceRect.y);
		var sourceStride = sourceBitmapData.width * 4;
		var destStride = destBitmapData.width * 4;
		
		var sourceFormat = sourceImage.buffer.format;
		var destFormat = image.buffer.format;
		var sourcePremultiplied = sourceImage.buffer.premultiplied;
		var destPremultiplied = image.buffer.premultiplied;
		
		var sourcePixel:RGBA, destPixel:RGBA = 0;
		var sourceOffset:Int, destOffset:Int;
		
		for (row in Std.int (sourceRect.y)...Std.int (sourceRect.height)) {
			
			for (column in Std.int (sourceRect.x)...Std.int (sourceRect.width)) {
				
				sourceOffset = (row * sourceStride) + (column * 4);
				destOffset = ((row + offsetX) * destStride) + ((column + offsetY) * 4);
				
				sourcePixel.readUInt8 (sourceData, sourceOffset, sourceFormat, sourcePremultiplied);
				
				if (sourcePixel.a == 0) {
					destPixel = 0;
				} else {
          var lum:Float = (sourcePixel.r + sourcePixel.g + sourcePixel.b) / 255 / 3;
					
					destPixel.r = Std.int (blackColor[0] + (lum * (whiteColor[0] - blackColor[0])));
					destPixel.g = Std.int (blackColor[1] + (lum * (whiteColor[1] - blackColor[1])));
					destPixel.b = Std.int (blackColor[2] + (lum * (whiteColor[2] - blackColor[2])));
					destPixel.a = Std.int ((sourcePixel.a / 255) * (blackColor[3] + (lum * (whiteColor[3] - blackColor[3]))));
				}
				destPixel.writeUInt8 (destData, destOffset, destFormat, destPremultiplied);
			}
		}
		
		destBitmapData.image.dirty = true;
		#end
		return destBitmapData;
		
	}
	
	
	@:noCompletion private override function __initShader (renderer:DisplayObjectRenderer, pass:Int, sourceBitmapData:BitmapData):Shader {
		
		__colorizeShader.init (whiteColor, blackColor);
		return __colorizeShader;
		
	}
}

private class ColorizeShader extends BitmapFilterShader {
	
	
	@:glFragmentSource( 
		"varying vec2 openfl_TextureCoordv;
		uniform sampler2D openfl_Texture;
		
		uniform vec4 blackColor;
		uniform vec4 whiteColor;
		
		void main(void) {
			
			vec4 color = texture2D (openfl_Texture, openfl_TextureCoordv);
			
			if (color.a == 0.0) {

				gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);

			} else {

        float lum = (color.r + color.g + color.b) / 3.0;

        gl_FragColor = blackColor + lum * (whiteColor - blackColor);

			}
			
		}"
		
	)
	
	
	public function new () {
		
		super ();
		
		#if !macro
		blackColor.value = [ 0, 0, 0, 1 ];
		whiteColor.value = [ 1, 1, 1, 1 ];
		#end
		
	}
	
	
	public function init (whiteColor:Array<Float>, blackColor:Array<Float>):Void {
		
		#if !macro
    this.whiteColor.value = whiteColor;
    this.blackColor.value = blackColor;
		#end
		
	}
}
