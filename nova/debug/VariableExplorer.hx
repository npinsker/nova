package nova.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.system.debug.Window;
import flixel.system.debug.FlxDebugger.GraphicConsole;
import openfl.display.Sprite;

import nova.render.FlxLocalSprite;

import flixel.system.debug.console.Console;

/**
 * A debugging tool for exploring the values of variables.
 *
 * Does not currently work.
 */
class VariableExplorer extends Sprite {
	public var window:Window = new Window('Variable Explorer', new GraphicConsole(0, 0));

	public var selection:FlxSprite;

	public function new() {
		super();
		
		addChild(window);
		
		window.resize(FlxG.width, FlxG.height / 3);
		window.reposition(0, FlxG.height - FlxG.height / 3);
		
		window.bound();
	}
	
	public function renderSelection() {
		if (!Std.is(selection, FlxLocalSprite)) {
			//console.setText(selection.toString());
			return;
		}
		var ls:FlxLocalSprite = cast(selection, FlxLocalSprite);
		//console.setText(treeAsText(ls).join('\n'));
	}
	
	public function treeAsText(root:FlxLocalSprite, limit:Int = 3):Array<String> {
		var r:Array<String> = [];
		r.push(root.toString());
		
		if (limit > 0) {
			for (child in root.children) {
				r = r.concat(indentLines(treeAsText(child, limit - 1)));
			}
		}
		return r;
	}
	
	public static function indentLines(lines:Array<String>, spaces:Int = 2) {
		var indentStr:String = [for (i in 0...spaces) ' '].join('');
		return lines.map(function(s) { return indentStr + s; });
	}
}
