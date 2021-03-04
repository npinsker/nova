package nova.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import nova.input.Focusable;
import nova.input.InputController;
import nova.render.FlxLocalSprite;

/**
 * A debugging tool for showing and changing the values in maps.
 */
enum MapEditorMode {
  SELECTING;
  EDITING_INT;
  EDITING_STRING;
}

class MapEditor extends FlxLocalSprite implements Focusable {
  public var mode:MapEditorMode = SELECTING;

  public var ref:Map<Dynamic, Dynamic>;
  public var keys:Array<Dynamic>;

  public var newIntValue:Int;
  public var newStringValue:String;

  public var texts:Array<LocalWrapper<FlxText>>;
  public var selectedIndex:Int = 0;

  public var abortCallback:Void -> Void;

	public function new(ref:Map<Dynamic, Dynamic>, abortCallback:Void -> Void) {
		super();

    this.ref = ref;
    this.keys = [for (key in ref.keys()) key];
    this.abortCallback = abortCallback;
    texts = [];

    for (key in this.keys) {
      var keyAsStr:String = cast key;
      var valAsStr:String = cast ref.get(key);
      trace(keyAsStr + " / " + valAsStr);
      texts.push(new LocalWrapper<FlxText>(
            new FlxText(0, 0, 0, keyAsStr + ": " + valAsStr, 28)
      ));
      texts[texts.length - 1]._sprite.color = FlxColor.WHITE;
      texts[texts.length - 1].x = 15;
      texts[texts.length - 1].y = 15 + 40 * (texts.length - 1);
      add(texts[texts.length - 1]);
    }

    refresh();
	}

  public function refresh() {
    if (mode == SELECTING) {
      for (i in 0...texts.length) {
        texts[i]._sprite.color = (i == selectedIndex ? FlxColor.RED : FlxColor.WHITE);
      }
    } else if (mode == EDITING_INT || mode == EDITING_STRING) {
      for (i in 0...texts.length) {
        texts[i]._sprite.color = (i == selectedIndex ? FlxColor.BLUE : FlxColor.WHITE);
      }
      var key:Dynamic = this.keys[selectedIndex];
      var keyAsStr:String = cast key;
      var valAsStr:String = cast ref.get(key);
      texts[selectedIndex]._sprite.text = keyAsStr + ": " + valAsStr;
    }
  }

  public function handleInput():Void {
    if (mode == SELECTING) {
      if (InputController.justPressed(UP)) {
        selectedIndex -= 1;
        if (selectedIndex < 0) selectedIndex += texts.length;
        refresh();
      }
      if (InputController.justPressed(DOWN)) {
        selectedIndex += 1;
        if (selectedIndex >= texts.length) selectedIndex -= texts.length;
        refresh();
      }
      if (InputController.justPressed(CONFIRM)) {
        var val = ref.get(keys[selectedIndex]);
        if (Std.is(val, Int)) {
          mode = EDITING_INT;
          newIntValue = cast val;
          refresh();
        } else if (Std.is(val, String)) {
          mode = EDITING_STRING;
          newStringValue = cast val;
          refresh();
        }
      }
      if (InputController.justPressed(CANCEL)) {
        abortCallback();
      }
    } else if (mode == EDITING_INT) {
      if (InputController.justPressed(UP)) {
        newIntValue += 1;
        var castRef:Map<Dynamic, Int> = cast ref;
        castRef.set(keys[selectedIndex], newIntValue);
        refresh();
      } else if (InputController.justPressed(DOWN)) {
        newIntValue -= 1;
        var castRef:Map<Dynamic, Int> = cast ref;
        castRef.set(keys[selectedIndex], newIntValue);
        refresh();
      }
      if (InputController.justPressed(CANCEL) || InputController.justPressed(CONFIRM)) {
        mode = SELECTING;
        refresh();
      }
    } else if (mode == EDITING_STRING) {
      if (FlxG.keys.justPressed.BACKSPACE) {
        newStringValue = newStringValue.substring(0, newStringValue.length - 1);
        ref.set(keys[selectedIndex], newStringValue);
        refresh();
      }
      for (chr in 65...91) {
        if (FlxG.keys.anyJustPressed([chr])) {
          var append:String = String.fromCharCode(FlxG.keys.pressed.SHIFT ? chr - 32 : chr);
          newStringValue = newStringValue + append;
          ref.set(keys[selectedIndex], newStringValue);
          refresh();
        }
      }
      if (InputController.justPressed(CANCEL) || InputController.justPressed(CONFIRM)) {
        mode = SELECTING;
        refresh();
      }
    }
  }
}
