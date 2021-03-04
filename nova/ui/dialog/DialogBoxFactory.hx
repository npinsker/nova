package nova.ui.dialog;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import nova.ui.dialog.DialogNodeSequence;
import nova.utils.StructureUtils;
import openfl.Assets;
import openfl.display.BitmapData;

/**
 * A convenience method for quickly creating DialogBox instances with common configurations.
 */
class DialogBoxFactory {
	public var options:Dynamic;
	public var defaultGlobalStore:Map<String, Dynamic>;
	
	/**
	 * Initializes a DialogBoxFactory that can create DialogBox instances with the supplied options.
	 * 
	 * @param	options	The configuration options for the dialog box.
	 * Options recognizes the following configuration options:
	 * 
	 * `advanceIndicator`: A graphic representing that the dialog box can be advanced.
	 * Appears at the bottom-right corner.
	 * 
	 * `advanceLength`: The number of frames that the advancing action will take.
	 * If `advanceStyle` is TYPEWRITER, this is the number of frames for the text to be typed out.
	 * If `advanceStyle` is SCROLL, this is the number of frames that the scrolling animation will take.
	 * 
	 * `advanceSound`: The sound to play upon advancing the dialog box.
	 * 
	 * `advanceStyle`: The animation style used to render the text. Can be NONE (no animation),
	 * TYPEWRITER (dialog will appear letter-by-letter), or SCROLL (dialog will move upwards).
	 * 
	 * `background`: The background image for the dialog box.
	 * 
	 * `speakerBackground`: The background image used when displaying the speaker's name.
	 * 
	 * `speakerSprite`: The image containing portraits of all speakers. (All speakers must
	 * be contained within this single image.)
	 * 
	 * `speakerSpriteMap`: Maps speaker names to (x, y) coordinates of `speakerSprite`.
	 * 
	 * `textFormat`: Formatting information about the text to be used.
	 */
	public function new(options:Dynamic) {
		this.options = options;
		this.defaultGlobalStore = new Map<String, Dynamic>();
		
		if (!Reflect.hasField(this.options, 'globalVariables')) {
			this.options.globalVariables = this.defaultGlobalStore;
		}
	}
	
	public function create(messages:OneOfTwo<DialogNodeSequence, Array<String>>, overrideOptions:Dynamic = null):DialogBox {
		var merged:Dynamic = StructureUtils.merge(options, overrideOptions);
		if (Std.is(messages, Array)) {
			messages = DialogParser.parseLines(messages);
		}
		return new DialogBox(messages, merged);
	}
	
	public function createControlled(overrideOptions:Dynamic = null):ControlledDialogBox {
		var merged:Dynamic = StructureUtils.merge(options, overrideOptions);
		return new ControlledDialogBox(merged);
	}
}
