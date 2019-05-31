package nova.render;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.FlxSprite;

/**
 * FlxCamera with support for multiple 'rooms'. The camera will always show
 * the player on screen but will never show more than one room at once.
 *
 * Rooms should be provided as an Array of FlxRects.
 */
class FlxRoomsCamera extends FlxCamera {
	private var _roomData:Array<FlxRect>;
	
	public function new(X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0,
	                    RoomData:Array<FlxRect> = null) {
		super(X, Y, Width, Height, Zoom);
		
		_roomData = RoomData.copy();
	}
	
	override public function updateFollow():Void
	{
		//Either follow the object closely, 
		//or double check our deadzone and update accordingly.
		if (deadzone == null) {
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			focusOn(_point);
		}
		else {
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
				{
					_scrollTarget.x = edge;
				} 
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
				{
					_scrollTarget.x = edge;
				}
				
				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
				{
					_scrollTarget.y = edge;
				}
				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
				{
					_scrollTarget.y = edge;
				}
			}
			
			if (Std.is(target, FlxSprite))
			{
				if (_lastTargetPosition == null)  
				{
					_lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
				} 
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;
				
				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}
			
			if (followLerp >= 60 / FlxG.updateFramerate)
			{
				scroll.copyFrom(_scrollTarget); // no easing
			}
			else
			{
				scroll.x += (_scrollTarget.x - scroll.x) * followLerp * FlxG.updateFramerate / 60;
				scroll.y += (_scrollTarget.y - scroll.y) * followLerp * FlxG.updateFramerate / 60;
			}
		}
	}
	
	override public function updateScroll():Void {
		if (target == null || _roomData == null) {
			return;
		}
		
		var currentRoomBounds:FlxRect = null;
		for (rect in _roomData) {
			if (rect.containsPoint(target.getPosition())) {
				currentRoomBounds = rect;
				break;
			}
		}
		
		if (currentRoomBounds == null) {
			return;
		}
		
		// Adjust bounds to account for zoom
		var zoom = this.zoom / FlxG.initialZoom;
		
		var minX:Null<Float> = currentRoomBounds.x;
		var maxX:Null<Float> = currentRoomBounds.x + currentRoomBounds.width;
		var minY:Null<Float> = currentRoomBounds.y;
		var maxY:Null<Float> = currentRoomBounds.y + currentRoomBounds.height;
		
		// Make sure we didn't go outside the camera's bounds
		scroll.x = FlxMath.bound(scroll.x, minX, (maxX != null) ? maxX - width : null);
		scroll.y = FlxMath.bound(scroll.y, minY, (maxY != null) ? maxY - height : null);
	}
}
