package nova;

import flixel.FlxSprite;

class StaticFX extends FlxSprite {
	private var duration:Float;
	
    public function new(?X:Float=0, ?Y:Float=0, ?duration:Float) {
        super(X, Y);
		this.duration = duration;
    }
	public override function update(elapsed:Float):Void {
		this.duration -= elapsed;
		if (this.duration <= 0) {
			this.destroy();
		}
	}
}