package nova.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

import nova.render.FlxLocalSprite;
import nova.utils.Pair;

	
#if FLX_DEBUG
@:bitmap("assets/images/nova_star.png")
private class GraphicSpriteSelector extends BitmapData {}
#end

/**
 * A debugging tool for graphically selecting and examining sprites.
 */
class SpriteSelector extends FlxLocalSprite {
	#if FLX_DEBUG
	public static var selector:SpriteSelector;
	#end
	
	public var rect:FlxSprite = null;
	public var target:FlxSprite = null;
	public var callback:FlxSprite -> Void;
	
	public function new(callback:FlxSprite -> Void = null) {
		super();
		this.callback = callback;
	}
	
	public function checkStillAttachedToTarget(mouse:Pair<Float>) {
		if (target.x <= mouse.x && mouse.x <= target.x + target.width &&
		    target.y <= mouse.y && mouse.y <= target.y + target.height) {
			return;
		}
		
		remove(rect);
		rect = null;
		target = null;
	}
	
	public function tryAcquireNewTarget(mouse:Pair<Float>) {
		for (memberObj in FlxG.state.members) {
			if (!Std.is(memberObj, FlxSprite)) {
				continue;
			}
			
			var result:Bool = tryAcquireFlxSprite(mouse, cast(memberObj, FlxSprite));
			if (result) {
				break;
			}
		}
		
		if (target != null) {
			var bd:BitmapData = new BitmapData(Std.int(Math.max(target.width, 1)), Std.int(Math.max(target.height, 1)));
			bd.fillRect(bd.rect, FlxColor.RED);
			bd.fillRect(new Rectangle(3, 3, bd.width - 6, bd.height - 6), FlxColor.TRANSPARENT);
			
			rect = new FlxSprite();
			rect.loadGraphic(bd);
			rect.x = (Std.is(target, FlxLocalSprite) ? cast(target, FlxLocalSprite).globalX : target.x);
			rect.y = (Std.is(target, FlxLocalSprite) ? cast(target, FlxLocalSprite).globalY : target.y);
			add(rect);
		}
	}

	public function tryAcquireFlxSprite(mouse:Pair<Float>, member:FlxSprite):Bool {
		if (Std.is(member, FlxLocalSprite)) {
			if (Std.is(member, LocalWrapper)) {
				return tryAcquireFlxSprite(mouse, cast(member, LocalWrapper<Dynamic>)._sprite);
			}
			
			for (child in cast(member, FlxLocalSprite).children) {
				var result:Bool = tryAcquireFlxSprite(mouse, child);
				if (result) {
					if (member.width == child.width && member.height == child.height) {
						target = member;
						return true;
					}
					return false;
				}
			}
			return false;
		}
			
		if (member.x <= mouse.x && mouse.x <= member.x + member.width &&
			member.y <= mouse.y && mouse.y <= member.y + member.height) {
			target = member;
			return true;
		}

		return false;
	}
	
	public function handleClick(target:FlxSprite) {
		if (callback == null) return;

		callback(target);
	}
	
	#if FLX_DEBUG
	public static function init() {
		FlxG.debugger.addButton(RIGHT, new GraphicSpriteSelector(0, 0), function() {
			FlxG.debugger.visible = false;
			selector = new SpriteSelector(function(s) { selectSprite(s); });
			FlxG.state.add(selector);
		});
	}
	
	public static function selectSprite(sprite:FlxSprite) {
		FlxG.debugger.visible = true;
		FlxG.console.registerObject('x', sprite);
		FlxG.watch.removeExpression('x');
		FlxG.watch.addExpression('x', 'x');
		FlxG.state.remove(selector);
	}
	#end
	
	override public function update(elapsed:Float) {
		var mouse:Pair<Float> = FlxG.mouse.getPosition();

		if (target != null) {
			rect.x = (Std.is(target, FlxLocalSprite) ? cast(target, FlxLocalSprite).globalX : target.x);
			rect.y = (Std.is(target, FlxLocalSprite) ? cast(target, FlxLocalSprite).globalY : target.y);
			checkStillAttachedToTarget(mouse);
		}
		
		if (target == null) {
			tryAcquireNewTarget(mouse);
		}
		
		if (FlxG.mouse.justPressed && target != null) {
			handleClick(target);
		}
		
		super.update(elapsed);
	}
}
