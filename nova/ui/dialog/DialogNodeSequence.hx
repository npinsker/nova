package nova.ui.dialog;

/**
 * A sequence of dialog syntax nodes along with a pointer to track computation.
 */

using nova.utils.ArrayUtils;

enum SyntaxNodeType {
	DEBUG;
	TEXT;
	CHOICE;
	CHOICE_BOX;
	LABEL;
	VARIABLE_ASSIGN;
	IF;
    ELSE;
    ELSEIF;
	FUNCTION;
	JUMP;
	EMIT;
	GLOBAL;
	RETURN;
	
	EXPRESSION;
}

class DialogSequencePointer {
	public var sequence:DialogNodeSequence;
	public var index:Int;
	
	public function new(sequence:DialogNodeSequence, index:Int) {
		this.sequence = sequence;
		this.index = index;
	}
	
	public function nextInstruction() {
		while (true) {
			index++;
			if (index < sequence.length) {
				return;
			}
			var pt = sequence.parent;
			if (pt == null) {
				sequence = null;
				index = 0;
				return;
			}
			sequence = pt.sequence;
			index = pt.index;
		}
	}
	
	public function get():DialogSyntaxNode {
		if (sequence == null) {
			return null;
		}
		return sequence.sequence[index];
	}
}

class DialogSyntaxNode {
	public var type:SyntaxNodeType;
	public var value:Dynamic;
	public var auxValue:Dynamic;
	public var child:DialogNodeSequence;
	
	public function new(type:SyntaxNodeType, value:Dynamic, ?child:DialogNodeSequence = null) {
		this.type = type;
		this.value = value;
		this.child = child;
    this.auxValue = null;
	}
	
	public static function spaces(num:Int):String {
		var s = "";
		for (i in 0...num) {
			s += " ";
		}
		return s;
	}
	
	public function _printableForm(indent:Int = 0):Array<String> {
		var r:Array<String> = [spaces(indent) + "[" + this.type + ": " + this.value + "]"];
		if (child != null) {
			r.extend(child._printableForm(indent + 4));
		}
		return r;
	}
	
	public function toString():String {
		return _printableForm().join('\n');
	}
}
 
class DialogNodeSequence {
	public var sequence:Array<DialogSyntaxNode>;
	public var parent:DialogSequencePointer = null;
	public function new() {
		sequence = new Array<DialogSyntaxNode>();
	}
	
	public var length(get, null):Int;
	
	public function get_length():Int {
		return sequence.length;
	}
	
	public function toString():String {
		return _printableForm().join('\n');
	}
  
  public function push(node:DialogSyntaxNode):Int {
    return sequence.push(node);
  }
	
	public function _printableForm(indent:Int = 0):Array<String> {
		var r:Array<String> = [];
		for (s in sequence) {
			r.extend(s._printableForm(indent));
		}
		return r;
	}
}
