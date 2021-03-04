package nova.ui.dialog;

import nova.animation.Director;
import openfl.Assets;

import nova.ui.dialog.DialogNodeSequence;
import nova.ui.dialog.ExpressionNode;
import nova.utils.CharUtils;

using nova.animation.Director;
using nova.utils.ArrayUtils;
using StringTools;

enum DialogTokenType {
	INT;
	FLOAT;
	VARIABLE;
    FUNCTION;
	RESERVED;
	STRING;
	ARITHMETIC_OP;
    ARITHMETIC_OP_ASSIGN;
	EQUALS_SIGN;
	DOUBLE_EQUALS_SIGN;
	LESS_THAN_SIGN;
	LESS_THAN_EQUALS_SIGN;
	GREATER_THAN_SIGN;
	GREATER_THAN_EQUALS_SIGN;
    NOT_EQUALS_SIGN;
	OPEN_PARENTHESIS;
	CLOSE_PARENTHESIS;
	COLON;
	COMMA;
	CHOICE;
	DOLLAR_SIGN;
}

class DialogToken {
	public var type:DialogTokenType;
	public var value:Dynamic = null;
	public var index:Int;
	
	public function new(type:DialogTokenType, index:Int, value:Dynamic = null) {
		this.type = type;
		this.index = index;
		this.value = value;
	}
}
 
/**
 * Creates a DialogNodeSequence from an array of strings (effectively lines of code).
 */
class DialogParser {
	private static var RESERVED_STRINGS:Array<String> = [
		"global",
		"label",
		"define",
		"jump",
		"choice_box",
		"clear",
		"if",
        "else",
        "elif",
		"emit",
		"wait",
		"not",
		"or",
		"and",
		"return",
		"debug",
	];
	
	public static function isAlphabetic(c:Int) {
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code);
	}
	
	public static function isValidVariableChar(c:Int) {
		return c == '_'.code || isAlphabetic(c);
	}
	
	public static function indexOfTokenType(arr:Array<DialogToken>, types:Array<DialogTokenType>, ?start:Int = 0):Int {
		var i = start;
		
		while (i < arr.length) {
			if (types.indexOf(arr[i].type) != -1) {
				return i;
			}
			++i;
		}
		return -1;
	}
	
	public static function parseLine(text:String):Array<DialogToken> {
		var builtTokens:Array<DialogToken> = new Array<DialogToken>();
		
		var i = 0;
		while (i < text.length) {
			if (CharUtils.isDigit(text.charCodeAt(i)) ||
				(i < text.length - 1 && text.charAt(i) == '-' && CharUtils.isDigit(text.charCodeAt(i+1)))) {
				var anchorI:Int = i;
				if (text.charAt(i) == '-') {
				  ++i;
				}
				var periodCount:Int = 0;
				while (i < text.length && ((text.charCodeAt(i) >= '0'.code && text.charCodeAt(i) <= '9'.code) || text.charCodeAt(i) == '.'.code)) {
					++i;
					if (text.charCodeAt(i) == '.'.code) {
						periodCount += 1;
					}
				}
				var textStr:String = text.substr(anchorI, i - anchorI);
				if (periodCount == 0) {
					builtTokens.push(new DialogToken(INT, i, Std.parseInt(textStr)));
				} else if (periodCount == 1) {
					builtTokens.push(new DialogToken(FLOAT, i, Std.parseFloat(textStr)));
				} else {
					trace("Error: Too many periods for string " + textStr);
				}
			} else if (text.charAt(i) == '\"' || text.charAt(i) == '\'') {
				var pt = i + 1;
				var next = text.indexOf(text.charAt(i), pt);
				while (next != -1 && text.charAt(next - 1) == '\\') {
					pt = next + 1;
					next = text.indexOf(text.charAt(i), pt);
				}
				if (next != -1) {
					builtTokens.push(new DialogToken(STRING, i, text.substr(i + 1, next - (i + 1)).replace('\\', '')));
					i = next + 1;
				} else {
					trace("Error: unterminated string: [" + text + "]!");
					return null;
				}
			} else if (text.charAt(i) == '(') {
				builtTokens.push(new DialogToken(OPEN_PARENTHESIS, i));
				++i;
			} else if (text.charAt(i) == ')') {
				builtTokens.push(new DialogToken(CLOSE_PARENTHESIS, i));
				++i;
			} else if (['+', '-', '*', '/'].indexOf(text.charAt(i)) != -1) {
        if (text.charAt(i) == '*' && builtTokens.length == 0) {
          builtTokens.push(new DialogToken(RESERVED, i, 'choice_abort'));
        } else if (text.charAt(i + 1) == '=') {
          builtTokens.push(new DialogToken(ARITHMETIC_OP_ASSIGN, i, text.substr(i, 2)));
          i += 2;
        } else {
          builtTokens.push(new DialogToken(ARITHMETIC_OP, i, text.charAt(i)));
          ++i;
        }
			} else if (text.charAt(i) == ':') {
				builtTokens.push(new DialogToken(COLON, i));
				++i;
			} else if (text.charAt(i) == ',') {
				builtTokens.push(new DialogToken(COMMA, i));
				++i;
			} else if (text.charAt(i) == '>') {
				if (builtTokens.length == 0) {
					builtTokens.push(new DialogToken(RESERVED, i, 'choice'));
					++i;
				} else {
					if (text.charAt(i + 1) == '=') {
						builtTokens.push(new DialogToken(GREATER_THAN_EQUALS_SIGN, i, null));
						i += 2;
					} else {
						builtTokens.push(new DialogToken(GREATER_THAN_SIGN, i, null));
						++i;
					}
				}
			} else if (text.charAt(i) == '<') {
				if (i < text.length - 1 && text.charAt(i + 1) == '=') {
          builtTokens.push(new DialogToken(LESS_THAN_EQUALS_SIGN, i, null));
          i += 2;
        } else {
          builtTokens.push(new DialogToken(LESS_THAN_SIGN, i, null));
          ++i;
        }
      } else if (text.charAt(i) == '#') {
				break;
			} else if (text.charAt(i) == '$') {
				builtTokens.push(new DialogToken(DOLLAR_SIGN, i));
				++i;
			} else if (text.charAt(i) == '=') {
				if (i < text.length - 1 && text.charAt(i + 1) == '=') {
					builtTokens.push(new DialogToken(DOUBLE_EQUALS_SIGN, i));
					i += 2;
				} else {
					builtTokens.push(new DialogToken(EQUALS_SIGN, i));
					++i;
				}
			} else if (text.charAt(i) == '!' && i < text.length - 1 && text.charAt(i + 1) == '=') {
                builtTokens.push(new DialogToken(NOT_EQUALS_SIGN, i));
                i += 2;
            } else if (isValidVariableChar(text.charCodeAt(i))) {
				var anchorI:Int = i;
				while (i < text.length && isValidVariableChar(text.charCodeAt(i))) {
					++i;
				}
				var resultString = text.substr(anchorI, i - anchorI);
				if (RESERVED_STRINGS.indexOf(resultString) != -1) {
					builtTokens.push(new DialogToken(RESERVED, anchorI, resultString));
				} else {
					if (resultString.toLowerCase() == 'true') {
						builtTokens.push(new DialogToken(INT, anchorI, 1));
					} else if (resultString.toLowerCase() == 'false') {
						builtTokens.push(new DialogToken(INT, anchorI, 0));
					} else {
						builtTokens.push(new DialogToken(VARIABLE, anchorI, resultString));
					}
				}
			} else {
				++i;
			}
		}

        
		return builtTokens;
	}

	public static function parseFile(path:String):DialogNodeSequence {
		var text:Array<String> = Assets.getText(path).split('\n')
			.filter(function(s:String) { return s.trim() != ''; });
		return parseLines(text);
	}
	
	public static function parseLines(text:Array<String>):DialogNodeSequence {
		var characters:Map<String, Dynamic> = new Map<String, Dynamic>();
		var builtText:Array<Dynamic> = new Array<Dynamic>();

		var rootSequence:DialogNodeSequence = new DialogNodeSequence();
		var callStack:Array<DialogNodeSequence> = [rootSequence];
		var parseType:Array<String> = ['normal'];
		var indentStack:Array<Int> = [0];
		
		for (i in 0...text.length) {
			var line:String = text[i];
			var tokens:Array<DialogToken> = parseLine(line);
			if (tokens.length == 0) {
				continue;
			}
			
			var indentation = 0;
			while (indentation < line.length && (line.charAt(indentation) == ' ' || line.charAt(indentation) == '\t')) {
				indentation++;
			}
			if (indentation > indentStack.last()) {
				if (callStack.length > indentStack.length) {
					indentStack.push(indentation);
				} else {
					trace("Improper indentation at line " + i + ": " + line + ". (Expected indent " + indentStack.last() + ".)");
				}
			}
			while (indentation < indentStack.last()) {
				indentStack.pop();
				callStack.pop();
			}
			
			if (tokens[0].type == RESERVED) {
				if (tokens[0].value == 'define') {
					var shortName = indexOfTokenType(tokens, [VARIABLE]);
					var tk = indexOfTokenType(tokens, [OPEN_PARENTHESIS]);
					
					characters[tokens[shortName].value] = tokens[tk + 1].value;
				} if (tokens[0].value == 'global') {
					var i = 1;
					if ([VARIABLE, STRING].indexOf(tokens[i].type) == -1) {
						trace('Line ' + i + ': unknown token ' + tokens[i].value + ' after "global". Should be a variable.');
					}
					callStack.last().sequence.push(new DialogSyntaxNode(GLOBAL, tokens[i].value));
					while (i < tokens.length - 1) {
						if (tokens[i + 1].type == COMMA && [VARIABLE, STRING].indexOf(tokens[i + 2].type) != -1) {
							i += 2;
							callStack.last().sequence.push(new DialogSyntaxNode(GLOBAL, tokens[i].value));
						} else {
							trace('Line ' + i + ': unknown token ' + tokens[i].value + '. Should be a comma-separated list of variables.');
						}
					}
				} else if (tokens[0].value == 'label') {
					var newNode = new DialogSyntaxNode(LABEL, tokens[1].value);
					callStack.last().sequence.push(newNode);
				} else if (tokens[0].value == 'return') {
					var labelName:String = (tokens.length > 2 ? line.substring(tokens[1].index) : tokens[1].value);
					callStack.last().sequence.push(new DialogSyntaxNode(RETURN, labelName));
				} else if (tokens[0].value == 'debug') {
					var newNode = new DialogSyntaxNode(DEBUG, {line: i + 1, name: tokens[1].value});
					callStack.last().sequence.push(newNode);
				} else if (tokens[0].value == 'jump') {
					var labelName:String = (tokens.length > 2 ? line.substring(tokens[1].index) : tokens[1].value);
					callStack.last().sequence.push(new DialogSyntaxNode(JUMP, labelName));
				} else if (tokens[0].value == 'emit') {
					var labelName:String = (tokens.length > 2 ? line.substring(tokens[1].index) : tokens[1].value);
					callStack.last().sequence.push(new DialogSyntaxNode(EMIT, labelName));
				} else if (tokens[0].value == 'wait') {
					var s1 = indexOfTokenType(tokens, [FLOAT], 1);
					var tokenValue:Float = tokens[s1].value;
					callStack.last().sequence.push(new DialogSyntaxNode(FUNCTION, function(k:DialogBox) {
            var couldSkip:Bool = k.skip;
						k.skip = false;
						k.canAdvance = false;
						Director.wait(k, Std.int(60 * tokenValue)).call(function(s) {
							cast(s, DialogBox).skip = couldSkip;
							cast(s, DialogBox).canAdvance = true;
							cast(s, DialogBox).advanceAndRender();
						});
					}));
				} else if (tokens[0].value == 'choice') {
					var s1 = indexOfTokenType(tokens, [STRING]);
					var s3 = indexOfTokenType(tokens, [STRING, VARIABLE], s1 + 1);
					if (s3 == -1) {
						trace("Error: Could not parse choice on line " + (i + 1) + ": " + line);
					}
					var newNode = new DialogSyntaxNode(CHOICE, {text: tokens[s1].value, tag: tokens[s3].value, type: 'choice'});
					callStack.last().sequence.push(newNode);
				} else if (tokens[0].value == 'choice_abort') {
					var s3 = indexOfTokenType(tokens, [STRING, VARIABLE]);
					if (s3 == -1) {
						trace("Error: Could not parse choice on line " + (i + 1) + ": " + line);
					}
					var newNode = new DialogSyntaxNode(CHOICE, {text: '*', tag: tokens[s3].value, type: 'choice_abort'});
          callStack.last().sequence.push(newNode);
                } else if (tokens[0].value == 'choice_box') {
					var newNode = new DialogSyntaxNode(CHOICE_BOX, null, new DialogNodeSequence());
					newNode.child.parent = new DialogSequencePointer(callStack.last(), callStack.last().length);
					callStack.last().sequence.push(newNode);
					callStack.push(newNode.child);
				} else if (tokens[0].value == 'if') {
					var newNode = new DialogSyntaxNode(IF, null, new DialogNodeSequence());
					
					if (tokens[tokens.length - 1].type != COLON) {
						trace('[Warning] Statement on line ' + (i + 1) + ' should end in a colon. (' + line + ')');
						newNode.value = parseExpression(tokens.slice(1, tokens.length));
					} else {
						newNode.value = parseExpression(tokens.slice(1, tokens.length - 1));
					}
					newNode.child.parent = new DialogSequencePointer(callStack.last(), callStack.last().length);
					callStack.last().sequence.push(newNode);
					callStack.push(newNode.child);
				} else if (tokens[0].value == 'elif' || (tokens[0].value == 'else' && tokens[1].value == 'if')) {
                    var startPosition = (tokens[0].value == 'elif' ? 1 : 2);
                    var endPosition = tokens.length;
                    if (tokens[tokens.length - 1].type != COLON) {
                        trace('[Warning] Statement on line ' + (i + 1) + ' should end in a colon. (' + line + ')');
                    } else {
                        endPosition -= 1;
                    }
                    var expr = parseExpression(tokens.slice(startPosition, endPosition));

                    var ifNode:DialogSyntaxNode = callStack.last().sequence.last();
                    if (ifNode.type != IF && ifNode.type != ELSEIF) {
                        trace('Error: "else" on line ${i+1} does not match any "if" or "elif"!');
                    }

					var newNode = new DialogSyntaxNode(IF, null, new DialogNodeSequence());
                    newNode.value = expr;
                    var continuePointer = new DialogSequencePointer(callStack.last(), callStack.last().length);
					newNode.child.parent = continuePointer;
                    var _p = callStack.last().sequence.length - 1;
                    while (_p >= 0 && (callStack.last().sequence[_p].type == ELSEIF || callStack.last().sequence[_p].type == IF)) {
                        callStack.last().sequence[_p].child.parent = continuePointer;
                        _p -= 1;
                        if (_p < 0 || callStack.last().sequence[_p].type == IF) break;
                    }
					callStack.last().sequence.push(newNode);
					callStack.push(newNode.child);
                } else if (tokens[0].value == 'else') {
                    var newNode = new DialogSyntaxNode(ELSE, null, new DialogNodeSequence());
                    var ifNode:DialogSyntaxNode = callStack.last().sequence.last();
                    if (ifNode.type != IF && ifNode.type != ELSEIF) {
                        trace('Error: "else" on line ${i+1} does not match any "if" or "elif"!');
                    }
                    ifNode.auxValue = new DialogSequencePointer(newNode.child, -1);
                    var continuePointer = new DialogSequencePointer(callStack.last(), callStack.last().length);
                    newNode.child.parent = continuePointer;
                    var _p = callStack.last().sequence.length - 1;
                    while (_p >= 0 && (callStack.last().sequence[_p].type == ELSEIF || callStack.last().sequence[_p].type == IF)) {
                        callStack.last().sequence[_p].child.parent = continuePointer;
                        _p -= 1;
                        if (_p < 0 || callStack.last().sequence[_p].type == IF) break;
                    }
                    ifNode.child.parent = newNode.child.parent;
                    callStack.last().sequence.push(newNode);
                    callStack.push(newNode.child);
                }
			} else if (tokens[0].type == VARIABLE) {
                if (tokens.length < 1) {
                  trace('Error: line ${i+1} has variable ${tokens[0].value} without assignment!');
                }
				if (tokens[1].type == EQUALS_SIGN) {
					var newNode = new DialogSyntaxNode(VARIABLE_ASSIGN, {name: tokens[0].value,
                                                               value: parseExpression(tokens.slice(2, tokens.length))});
					callStack.last().sequence.push(newNode);
				} else {
					var speaker = tokens[0].value;
					if (characters.exists(speaker)) {
						speaker = characters.get(speaker);
					}
					var nextToken = indexOfTokenType(tokens, [INT, STRING], 1);
					if (nextToken == -1) {
						trace('[Warning] No value found for variable ' + tokens[0].value + '. (' + line + ')');
					}
					callStack.last().sequence.push(new DialogSyntaxNode(TEXT, {text: tokens[nextToken].value, speaker: speaker}));
				}
			} else if (tokens[0].type == STRING) {
				if (tokens.length > 1 && tokens[1].type == STRING) {
					callStack.last().sequence.push(new DialogSyntaxNode(TEXT, {text: tokens[1].value, speaker: tokens[0].value}));
				} else {
					callStack.last().sequence.push(new DialogSyntaxNode(TEXT, {text: tokens[0].value}));
				}
			}
		}
		return rootSequence;
	}
	
	public static function parseExpression(tokens:Array<DialogToken>):ExpressionNode {
		if (tokens.length == 1) {
			if (tokens[0].type == STRING || tokens[0].type == INT || tokens[0].type == FLOAT) {
				return new ExpressionNode((tokens[0].type == STRING ? STRING : (tokens[0].type == INT ? INTEGER : FLOAT)), tokens[0].value);
			} else if (tokens[0].type == VARIABLE) {
				return new ExpressionNode(VARIABLE, tokens[0].value);
			} else {
				trace("Can't parse single token with type " + tokens[0].type + "!");
				return null;
			}
		}
		if (tokens[0].type == OPEN_PARENTHESIS && tokens[tokens.length - 1].type == CLOSE_PARENTHESIS) {
			tokens = tokens.slice(1, tokens.length - 1);
		}
		var outsideIndices = findOutsideTokenIndices(tokens);
		for (index in outsideIndices) {
			var tok:DialogToken = tokens[index];
			// clean this up
			if (tok.type == RESERVED && (tok.value == 'and' || tok.value == 'or')) {
				var root = new ExpressionNode((tok.value == 'and' ? AND : OR), null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			}
		}
		for (index in outsideIndices) {
			var tok:DialogToken = tokens[index];
			if (tok.type == DOUBLE_EQUALS_SIGN) {
				var root = new ExpressionNode(EQUALS, null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			} else if (tok.type == LESS_THAN_SIGN) {
				var root = new ExpressionNode(LESS_THAN, null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			} else if (tok.type == LESS_THAN_EQUALS_SIGN) {
				var root = new ExpressionNode(LESS_THAN_EQUALS, null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			} else if (tok.type == GREATER_THAN_SIGN) {
				var root = new ExpressionNode(GREATER_THAN, null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			} else if (tok.type == ARITHMETIC_OP) {
				var root = new ExpressionNode(ARITHMETIC_NODE, tok.value);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			} else if (tok.type == GREATER_THAN_EQUALS_SIGN) {
				var root = new ExpressionNode(GREATER_THAN_EQUALS, null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
				return root;
			} else if (tok.type == NOT_EQUALS_SIGN) {
                var root = new ExpressionNode(NOT_EQUALS, null);
				root.leftChild = parseExpression(tokens.slice(0, index));
				root.rightChild = parseExpression(tokens.slice(index + 1, tokens.length));
                return root;
            }
		}
		if (tokens[0].type == RESERVED && tokens[0].value == 'not') {
			var root = new ExpressionNode(NOT, null);
			root.leftChild = parseExpression(tokens.slice(1, tokens.length));
		}
		if (tokens[0].type == VARIABLE && tokens[1].type == OPEN_PARENTHESIS) {
            var i = 2;
            var tokenArray = new Array<DialogToken>();
            while (true) {
                if (tokens[i].type == VARIABLE) {
                    tokenArray.push(tokens[i]);
                }
                if (tokens[i].type == CLOSE_PARENTHESIS || tokens[i+1].type == CLOSE_PARENTHESIS) {
                    break;
                }
                i += 2;
            }
            var arg:Dynamic = (tokenArray.length > 1 ? tokenArray : tokenArray.length == 1 ? tokenArray[0] : null);
            return new ExpressionNode(FUNCTION, {name: tokens[0].value, args: arg});
		}
        trace("Can't parse expression " + tokens);
		return null;
	}
	
	static function findOutsideTokenIndices(tokens:Array<DialogToken>):Array<Int> {
		var pCount = 0;
		var r:Array<Int> = [];
		for (i in 0...tokens.length) {
			if (tokens[i].type == OPEN_PARENTHESIS) {
				++pCount;
			} else if (tokens[i].type == CLOSE_PARENTHESIS) {
				--pCount;
			} else if (pCount == 0) {
				r.push(i);
			}
		}
		
		return r;
	}
}
