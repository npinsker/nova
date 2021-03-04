package nova.ui.dialog;

import nova.render.FlxLocalSprite;
import nova.ui.dialog.DialogBox;

class DialogChoiceBox extends FlxLocalSprite {
  public var abortChoice:String = null;

  public function new() {
    super();
  }

  public function setPositionFromDB(db:DialogBox) { }
  public function selectOption():String {
    return "null";
  }
	public function handleInput():Void { }
}
