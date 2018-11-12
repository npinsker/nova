package nova.ui.dialog;

import nova.ui.dialog.DialogNodeSequence;
/**
 * ...
 * @author Nathan Pinsker
 */

using nova.utils.ArrayUtils;

enum ExpressionNodeType {
	VARIABLE;
	EQUALS;
	
	ARITHMETIC;
	
	STRING;
	INTEGER;
	
	AND;
	OR;
	NOT;
}

class ExpressionNode {
	public var type:ExpressionNodeType;
	public var value:Dynamic;
	
	public var leftChild:ExpressionNode = null;
	public var rightChild:ExpressionNode = null;
	
	public static var FALSE:ExpressionNode = new ExpressionNode(INTEGER, 0);
	public static var TRUE:ExpressionNode = new ExpressionNode(INTEGER, 1);
	
	public function new(type:ExpressionNodeType, value:Dynamic) {
		this.type = type;
		this.value = value;
	}
	
	public function evaluate(variableMap:Map<String, Dynamic>):ExpressionNode {
		if (type == STRING || type == INTEGER) {
			return this;
		}
		if (type == VARIABLE) {
			if (variableMap.exists(value)) {
				if (Std.is(variableMap.get(value), Int)) {
					return new ExpressionNode(INTEGER, variableMap.get(value));
				} else if (Std.is(variableMap.get(value), String)) {
					return new ExpressionNode(STRING, variableMap.get(value));
				} else {
					trace("Unknown type for variable " + value + " (value " + variableMap.get(value) + ")");
					return null;
				}
			} else {
				//trace("Variable " + value + " -- not found in variableMap! (defaulting to FALSE)");
				return FALSE;
			}
		}
		if (type == ARITHMETIC) {
			if (leftChild == null || rightChild == null) {
				trace("Attempt to evaluate ARITHMETIC op with a null child!");
				return null;
			}
			var leftResult:ExpressionNode = leftChild.evaluate(variableMap);
			var rightResult:ExpressionNode = rightChild.evaluate(variableMap);
			
			if (leftResult.type != INTEGER || rightResult.type != INTEGER) {
				trace("Attempt to evaluate ARITHMETIC op with a non-integer!");
				return null;
			}
			
			if (value == '+') {
				return new ExpressionNode(INTEGER, leftResult.value + rightResult.value);
			} else if (value == '-') {
				return new ExpressionNode(INTEGER, leftResult.value - rightResult.value);
			} else if (value == '*') {
				return new ExpressionNode(INTEGER, leftResult.value * rightResult.value);
			} else if (value == '/') {
				return new ExpressionNode(INTEGER, Std.int(leftResult.value / rightResult.value));
			}
			trace("Unknown op " + value);
			return null;
		}
		if (type == EQUALS) {
			if (leftChild == null || rightChild == null) {
				trace("Attempt to evaluate ARITHMETIC op with a null child!");
				return null;
			}
			var leftResult:ExpressionNode = leftChild.evaluate(variableMap);
			var rightResult:ExpressionNode = rightChild.evaluate(variableMap);
			
			if (leftResult.type != rightResult.type || leftResult.value != rightResult.value) {
				return FALSE;
			}
			return TRUE;
		}
		if (type == AND || type == OR) {
			if (leftChild == null || rightChild == null) {
				trace("Attempt to evaluate AND op with a null child!");
				return null;
			}
			var leftResult:ExpressionNode = leftChild.evaluate(variableMap);
			var rightResult:ExpressionNode = rightChild.evaluate(variableMap);
			if (leftResult.type != INTEGER || rightResult.type != INTEGER) {
				trace('Attempt to evaluate ' + type + ' op with types ' + leftResult.type + " and " + rightResult.type + "!");
				return null;
			}
			if (type == AND) {
				if (leftResult.value > 0 && rightResult.value > 0) {
					return TRUE;
				}
				return FALSE;
			} else {
				if (leftResult.value > 0 || rightResult.value > 0) {
					return TRUE;
				}
				return FALSE;
			}
		}
		if (type == NOT) {
			if (leftChild == null) {
				trace("Attempt to evaluate NOT op with a null child!");
				return null;
			}
			var result:ExpressionNode = leftChild.evaluate(variableMap);
			
			if (result.type != INTEGER) {
				trace("Attempt to evaluate NOT op with type " + result.type + "!");
				return null;
			}
			if (result.value > 0) {
				return FALSE;
			}
			return TRUE;
		}
		return null;
	}
	
	public function toString():String {
		return _printableForm().join('\n');
	}
	
	public function _printableForm(indent:Int = 0):Array<String> {
		var r:Array<String> = [];
		r.push(DialogSyntaxNode.spaces(indent) + "> " + this.type + ": " + this.value);
		if (leftChild != null) {
			r.extend(leftChild._printableForm(indent + 4));
		}
		if (rightChild != null) {
			r.extend(rightChild._printableForm(indent + 4));
		}
		return r;
	}
}