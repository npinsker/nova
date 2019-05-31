package nova.input;

import flixel.FlxG;
import flixel.input.FlxSwipe;

enum SimpleSwipe {
	SWIPE_LEFT;
  SWIPE_RIGHT;
  SWIPE_UP;
  SWIPE_DOWN;
  TAP;
}

/**
  * Represents an arbitrary swipe.
  *
  * This doesn't work yet.
  */
class NovaSwipe {
  public static function toSimpleSwipe(swipe:FlxSwipe):SimpleSwipe {
    if (swipe.distance < 40) {
      return TAP;
    }

    if (swipe.angle < -135 || swipe.angle > 135) {
      return SWIPE_DOWN;
    }
    if (swipe.angle < -45) {
      return SWIPE_LEFT;
    }
    if (swipe.angle < 45) {
      return SWIPE_UP;
    }
    return SWIPE_RIGHT;
  }
}
