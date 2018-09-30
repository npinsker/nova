package;

/**
 * ...
 * @author Nathan Pinsker
 */

class Node {
	var value:Int;
	
	var parent:Node;
	var left:Node;
	var right:Node;
	
	public function new(value:Int) {
		self.value = value;
		
		parent = null;
		left = null;
		right = null;
	}
}

class SplayTree {
	public var root:Node = null;
	
	public static function rotateRight(pivot:Node):Node {
		Node l = pivot.left;
		pivot.left = l.right;
		l.parent = pivot.parent;
		pivot.parent = l;
		l.right = pivot;
		return l;
	}
	
	public static function rotateLeft(pivot:Node):Node {
		Node r = pivot.right;
		pivot.right = r.left;
		r.parent = pivot.parent;
		pivot.parent = r;
		r.left = pivot;
		return r;
	}
	
	public function new(?values:Array<Int>) {
		var lastNode:Node = null;
		for (value in values) {
			if (lastNode == null) {
				lastNode = value;
				root = lastNode;
			} else {
				var newNode:Node = new Node(value);
				root.left = newNode;
				newNode.parent = root;
			}
		}
	}
}