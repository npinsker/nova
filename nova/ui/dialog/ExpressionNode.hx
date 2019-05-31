package nova.ui.dialog;

import nova.ui.dialog.DialogNodeSequence;

using nova.utils.ArrayUtils;

enum ExpressionNodeType {
	VARIABLE;
	FUNCTION;
	
	ARITHMETIC_NODE;
	
	STRING;
	INTEGER;
	FLOAT;
	
	AND;
	OR;
	NOT;
	EQUALS;
	LESS_THAN;
	GREATER_THAN;
	LESS_THAN_EQUALS;
	GREATER_THAN_EQUALS;
}

/**
 * A node representing a mathematical expression, possibly containg variables.
 */
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
			if (!variableMap.exists(value)) {
				//trace("Variable " + value + " -- not found in variableMap! (defaulting to FALSE)");
				return FALSE;
			}
			if (Std.is(variableMap.get(value), Int)) {
				return new ExpressionNode(INTEGER, variableMap.get(value));
			} else if (Std.is(variableMap.get(value), Float)) {
				return new ExpressionNode(FLOAT, variableMap.get(value));
			} else if (Std.is(variableMap.get(value), String)) {
				return new ExpressionNode(STRING, variableMap.get(value));
			}
			trace("Unknown type for variable " + value + " (value " + variableMap.get(value) + ")");
			return null;
		}
		if (type == FUNCTION) {
			if (!variableMap.exists(value)) {
				trace("Function " + value + " -- not found in variableMap! (defaulting to FALSE)");
				return FALSE;
			}
			var fn = variableMap.get(value);
			var result = fn(leftChild.evaluate(variableMap).value);
			if (Std.is(result, Int)) {
				return new ExpressionNode(INTEGER, cast(result, Int));
			} else if (Std.is(result, Float)) {
				return new ExpressionNode(FLOAT, cast(result, Float));
			} else if (Std.is(result, Bool)) {
				return new ExpressionNode(INTEGER, (cast(result, Bool) ? 1 : 0));
			} else if (Std.is(result, String)) {
				return new ExpressionNode(STRING, cast(result, String));
			}
			trace("Unknown function result for function with name " + value + " (value " + result + ")");
			return null;
		}
		if (type == ARITHMETIC_NODE) {
			if (leftChild == null || rightChild == null) {
				trace("Attempt to evaluate ARITHMETIC_NODE op with a null child!");
				return null;
			}
			var leftResult:ExpressionNode = leftChild.evaluate(variableMap);
			var rightResult:ExpressionNode = rightChild.evaluate(variableMap);
			
			if ((leftResult.type != INTEGER && leftResult.type != FLOAT) ||
			    (rightResult.type != INTEGER && rightResult.type != FLOAT)) {
				trace("Attempt to evaluate ARITHMETIC_NODE op with non-numbers!");
				return null;
			}
			var resultType = (leftResult.type == FLOAT || rightResult.type == FLOAT ? FLOAT : INTEGER);
			
			if (value == '+') {
				return new ExpressionNode(resultType, leftResult.value + rightResult.value);
			} else if (value == '-') {
				return new ExpressionNode(resultType, leftResult.value - rightResult.value);
			} else if (value == '*') {
				return new ExpressionNode(resultType, leftResult.value * rightResult.value);
			} else if (value == '/') {
				var result:Float = leftResult.value / rightResult.value;
				return new ExpressionNode(resultType, (resultType == INTEGER ? Std.int(result) : result));
			}
			trace("Unknown op " + value);
			return null;
		}
		if (type == EQUALS || type == LESS_THAN || type == GREATER_THAN ||
        type == LESS_THAN_EQUALS || type == GREATER_THAN_EQUALS) {
			if (leftChild == null || rightChild == null) {
				trace("Attempt to evaluate comparison op with a null child!");
				return null;
			}
			var leftResult:ExpressionNode = leftChild.evaluate(variableMap);
			var rightResult:ExpressionNode = rightChild.evaluate(variableMap);
			
			if ((leftResult.type != INTEGER && leftResult.type != FLOAT) || (rightResult.type != INTEGER && rightResult.type != FLOAT)) {
				if (leftResult.type != rightResult.type) {
					trace("Warning: Attempt to evaluate type " + type + " on incompatible values " +
							leftResult + " and " + rightResult + ". (Returning FALSE)");
					return FALSE;
				}
			}
			
			if (type == EQUALS) {
				return (leftResult.value == rightResult.value ? TRUE : FALSE);
			}
			if (type == LESS_THAN) {
				return (leftResult.value < rightResult.value ? TRUE : FALSE);
			}
			if (type == LESS_THAN_EQUALS) {
				return (leftResult.value <= rightResult.value ? TRUE : FALSE);
			}
			if (type == GREATER_THAN) {
				return (leftResult.value > rightResult.value ? TRUE : FALSE);
			}
			if (type == GREATER_THAN_EQUALS) {
				return (leftResult.value >= rightResult.value ? TRUE : FALSE);
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
