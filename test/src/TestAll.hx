package;

import haxe.unit.TestRunner;

class TestAll {
	static function main() {
		var r = new TestRunner();
		
		r.add(new animation.TestDirector());
		
		r.run();
	}
}