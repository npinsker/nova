package nova.render;

import flixel.FlxSprite;
import flixel.animation.FlxAnimationController;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.helpers.FlxRange;
import nova.render.FlxLocalSprite.LocalSpriteWrapper;
import nova.utils.Pair;

class NovaParticleManager {
    public static var instance(default, null):NovaParticleManager = new NovaParticleManager();

    public var factories:Map<String, Void -> FlxSprite>;
    public var actives:Map<String, Array<FlxSprite>>;

	private function new() {
        factories = new Map<String, Void -> FlxSprite>();
        actives = new Map<String, Array<FlxSprite>>();
	}

    public static function reserve(key:String):FlxSprite {
        var newParticle:FlxSprite = instance.factories.get(key)();
        if (!instance.actives.exists(key)) {
            instance.actives.set(key, []);
        }
        instance.actives.get(key).push(newParticle);

        newParticle.exists = false;
        return newParticle;
    }

    public static function make(key:String):FlxSprite {
        if (!instance.factories.exists(key)) {
            trace("Error: particle with key " + key + " doesn't exist!");
            return null;
        }
        if (!instance.actives.exists(key)) {
            instance.actives.set(key, []);
        }
        for (i in 0...instance.actives.get(key).length) {
            var active = instance.actives.get(key)[i];
            if (active.last == null) {
                instance.actives.get(key)[i] = instance.factories.get(key)();
                return instance.actives.get(key)[i];
            }

            if (!active.exists) {
                active.exists = true;
                return active;
            }
        }

        var newParticle:FlxSprite = instance.factories.get(key)();
        instance.actives.get(key).push(newParticle);
        return newParticle;
    }
}
