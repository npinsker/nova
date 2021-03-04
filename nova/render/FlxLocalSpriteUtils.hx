package nova.render;

import flixel.FlxG;

enum AlignSpot {
    TOP;
    LEFT;
    RIGHT;
    BOTTOM;

    TOP_LEFT;
    TOP_CENTER;
    TOP_RIGHT;
    CENTER_LEFT;
    CENTER;
    CENTER_RIGHT;
    BOTTOM_LEFT;
    BOTTOM_CENTER;
    BOTTOM_RIGHT;
}

class FlxLocalSpriteUtils {
	public static function snap(self:FlxLocalSprite, direction:AlignSpot) {
        var width = (self.parent != null ? self.parent.width : FlxG.width);
        var height = (self.parent != null ? self.parent.height : FlxG.height);

        if (direction == TOP) {
            self.y = 0;
            return;
        } else if (direction == LEFT) {
            self.x = 0;
            return;
        } else if (direction == RIGHT) {
            self.x = width - self.width;
            return;
        } else if (direction == BOTTOM) {
            self.y = height - self.height;
            return;
        }

        if (direction == TOP_LEFT || direction == CENTER_LEFT || direction == BOTTOM_LEFT) {
            self.x = 0;
        } else if (direction == TOP_CENTER || direction == CENTER || direction == BOTTOM_CENTER) {
            self.x = (width - self.width) / 2;
        } else {
            self.x = width - self.width;
        }

        if (direction == TOP_LEFT || direction == TOP_CENTER || direction == TOP_RIGHT) {
            self.y = 0;
        } else if (direction == CENTER_LEFT || direction == CENTER || direction == CENTER_RIGHT) {
            self.y = (height - self.height) / 2;
        } else {
            self.y = height - self.height;
        }
    }
}
