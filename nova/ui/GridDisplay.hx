package nova.ui;

using nova.animation.Director;

import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo;
import nova.input.Focusable;
import nova.render.FlxLocalSprite;
import nova.utils.BitmapDataUtils;
import nova.utils.Pair;
import nova.input.InputController;
import openfl.Assets;
import openfl.display.BitmapData;

using nova.utils.StructureUtils;

class GridDisplay extends FlxLocalSprite implements Focusable {
	public static inline var DEFAULT_TEXT_PADDING_X:Int = 6;
	public static inline var DEFAULT_TEXT_PADDING_Y:Int = 5;
	public static inline var DIRECTOR_DIALOG_TRANSITION_STR:String = '__dialogTransition';
	
	public static inline var NUM_COLUMNS:Int = 4;
	public static inline var MIN_ROWS:Int = 4;
	
	public var grid:Array<Array<GridDisplayBox>>;
	public var inventory:Array<Dynamic>;
	public var columns:Int;
	public var fixedFocus:Array<Int>;
	public var X_MULT:Int = 16700;
	public var options:Dynamic;
	
	public var focus:Pair<Int> = [0, 0];
	
	public function new(spriteSheet:BitmapData, inventory:Array<Dynamic>, options:Dynamic) {
		super();
		grid = new Array<Array<GridDisplayBox>>();
		this.inventory = inventory.copy();
		this.columns = (Reflect.hasField(options, 'columns') ? options.columns : NUM_COLUMNS);
		this.fixedFocus = new Array<Int>();
		this.options = options;
	}
	
	public var selected(get, null):GridDisplayBox;
	@:noCompletion
	public function get_selected():GridDisplayBox {
		return grid[focus.y][focus.x];
	}
	
	public var selectedCoords(get, null):Pair<Int>;
	@:noCompletion
	public function get_selectedCoords():Pair<Int> {
		return [focus.x, focus.y];
	}
	
	public function focusTo(newLoc:Pair<Int>) {
		if (focus.y >= 0 && focus.x >= 0 && fixedFocus.indexOf(X_MULT * focus.x + focus.y) == -1) {
			grid[focus.y][focus.x].loseFocus();
		}
		focus = [newLoc.x, newLoc.y];
		if (focus.y >= 0 && focus.x >= 0 && fixedFocus.indexOf(X_MULT * focus.x + focus.y) == -1) {
			grid[focus.y][focus.x].focus();
		}
	}
	
	public function addFixedFocus(loc:Pair<Int>) {
		fixedFocus.push(X_MULT * loc.x + loc.y);
		if (loc.x != focus.x || loc.y != focus.y) {
			grid[loc.x][loc.y].focus();
		}
	}
	
	public function removeFixedFocus(loc:Pair<Int>) {
		fixedFocus.remove(X_MULT * loc.x + loc.y);
		if (loc.x != focus.x || loc.y != focus.y) {
			grid[loc.y][loc.x].loseFocus();
		}
	}
	
	public function getGridSpriteSelected():FlxLocalSprite {
		return grid[focus.y][focus.x];
	}
	
	public function getItemSelected():Dynamic {
		var idx = NUM_COLUMNS * focus.y + focus.x;
		if (idx >= inventory.length) {
			return null;
		}
		return inventory[idx];
	}
	
	public function handleInput() {
		if (InputController.justPressed(Button.LEFT)) {
			if (focus.x > 0) {
				focusTo([focus.x - 1, focus.y]);
        if (Reflect.hasField(options, 'changeSelectionCallback')) {
          options.changeSelectionCallback([focus.x, focus.y]);
        }
			}
		}
		if (InputController.justPressed(Button.RIGHT)) {
			if (focus.x < grid[focus.y].length - 1) {
				focusTo([focus.x + 1, focus.y]);
        if (Reflect.hasField(options, 'changeSelectionCallback')) {
          options.changeSelectionCallback([focus.x, focus.y]);
        }
			}
		}
		if (InputController.justPressed(Button.UP)) {
			if (focus.y > 0) {
				focusTo([focus.x, focus.y - 1]);
        if (Reflect.hasField(options, 'changeSelectionCallback')) {
          options.changeSelectionCallback([focus.x, focus.y]);
        }
			}
		}
		if (InputController.justPressed(Button.DOWN)) {
			if (focus.y < grid.length - 1) {
				focusTo([focus.x, focus.y + 1]);
        if (Reflect.hasField(options, 'changeSelectionCallback')) {
          options.changeSelectionCallback([focus.x, focus.y]);
        }
			}
		}
	}
}