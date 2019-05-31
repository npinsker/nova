package nova.ds;

/**
 * A splay tree.
 * 
 * Currently does not work.
 */

class Node {
	public var value:Int;
	
	public var parent:Node;
	public var left:Node;
	public var right:Node;
	
	public function new(value:Int) {
		this.value = value;
		
		parent = null;
		left = null;
		right = null;
	}
}

class SplayTree {
	public var root:Node = null;
	
	public static function rotateRight(pivot:Node):Node {
		var l:Node = pivot.left;
		pivot.left = l.right;
		l.parent = pivot.parent;
		pivot.parent = l;
		l.right = pivot;
		return l;
	}
	
	public static function rotateLeft(pivot:Node):Node {
		var r:Node = pivot.right;
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
				lastNode.value = value;
				root = lastNode;
			} else {
				var newNode:Node = new Node(value);
				root.left = newNode;
				newNode.parent = root;
			}
		}
	}
}