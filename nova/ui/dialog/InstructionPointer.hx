package nova.ui.dialog;

import nova.ui.dialog.DialogNodeSequence.DialogSequencePointer;
import nova.ui.dialog.DialogNodeSequence.DialogSyntaxNode;

using nova.utils.ArrayUtils;

/**
 * A DialogSequencePointer plus contextual information, such as variables and callbacks.
 */
class InstructionPointer extends DialogSequencePointer {
  // You can only jump to labels within the same message.
  public var labelMap:Map<String, DialogSequencePointer>;
  public var localVariables:Map<String, Dynamic>;
  public var globalVariables:Map<String, Dynamic>;
  public var emitCallback:String -> Void;
  public function new(sequence:DialogNodeSequence,
                      index:Int,
                      labelMap:Map<String, DialogSequencePointer>,
                      ?localVariables:Map<String, Dynamic>,
                      ?globalVariables:Map<String, Dynamic>,
                      ?emitCallback:String -> Void) {
    super(sequence, index);
    this.labelMap = labelMap;
    this.localVariables = localVariables;
    this.globalVariables = globalVariables;
    this.emitCallback = emitCallback;
    if (this.localVariables == null) this.localVariables = new Map<String, Dynamic>();
    if (this.globalVariables == null) this.globalVariables = new Map<String, Dynamic>();
  }

  public function getVariable(name:String):Dynamic {
      if (this.localVariables.exists(name)) {
          return this.localVariables.get(name);
      }
      if (this.globalVariables.exists(name)) {
          return this.globalVariables.get(name);
      }
      return null;
  }
  
  public function step(bypassText:Bool = false) {
		while (true) {
			var node:DialogSyntaxNode = get();
			if (node == null || node.type == CHOICE_BOX || node.type == RETURN) {
				return;
			} else if ((node.type == TEXT || node.type == FUNCTION) && !bypassText) {
        // Currently, FUNCTION is just WAIT, so we can safely skip it if desired
        return;
      } else if (node.type == JUMP) {
				var label:String = node.value;
				if (labelMap.exists(label)) {
					this.index = labelMap.get(label).index;
          this.sequence = labelMap.get(label).sequence;
				} else if (label == 'end') {
					this.sequence = null;
					return;
				} else {
					trace("Label " + label + " doesn't exist!");
				}
			} else if (node.type == IF) {
				var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in globalVariables.keys()) {
					mergedVariables.set(k, globalVariables.get(k));
				}
				for (k in localVariables.keys()) {
					if (!globalVariables.exists(k)) {
						mergedVariables.set(k, localVariables.get(k));
					}
				}
				var exp:ExpressionNode = node.value.evaluate(mergedVariables);
				if (exp.type == INTEGER) {
          if (exp.value > 0) {
            this.sequence = node.child;
            this.index = -1;
          } else if (node.auxValue != null) {
            var ptr:DialogSequencePointer = node.auxValue;
            this.sequence = ptr.sequence;
            this.index = ptr.index;
          }
				}
			} else if (node.type == VARIABLE_ASSIGN) {
        var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in globalVariables.keys()) {
					mergedVariables.set(k, globalVariables.get(k));
				}
				for (k in localVariables.keys()) {
					if (!globalVariables.exists(k)) {
						mergedVariables.set(k, localVariables.get(k));
					}
				}
				var exp:ExpressionNode = node.value.value.evaluate(mergedVariables);

				if (globalVariables.exists(node.value.name)) {
                    trace("setting " + node.value.name + " to " + exp.value);
					globalVariables.set(node.value.name, exp.value);
				} else {
					localVariables.set(node.value.name, exp.value);
				}
			} else if (node.type == GLOBAL) {
        if (!globalVariables.exists(node.value)) {
          globalVariables.set(node.value, null);
        }
			} else if (node.type == EMIT) {
				if (emitCallback == null) {
          trace("emit called with emitCallback not set!");
        } else {
          emitCallback(node.value);
        }
			} else if (node.type == DEBUG) {
				var mergedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
				for (k in globalVariables.keys()) {
					mergedVariables.set(k, globalVariables.get(k));
				}
				for (k in localVariables.keys()) {
					if (globalVariables.exists(k)) {
						mergedVariables.set(k, globalVariables.get(k));
					}
				}
				trace('DEBUG [line ${node.value.line}]: ${node.value.name} = ' + mergedVariables.get(node.value.name));
			}
      nextInstruction();
		}
  }
}
