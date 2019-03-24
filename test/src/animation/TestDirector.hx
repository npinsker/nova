package animation;

import flixel.FlxSprite;
import haxe.unit.TestCase;

import nova.animation.Director;
import nova.utils.GeomUtils;

using nova.animation.Director;

class TestDirector extends TestCase {
  public function testChainedMoveBy() {
    var sp:FlxSprite = new FlxSprite();
	
	Director.moveBy(sp, [20, 0], 2).moveBy([0, 20], 2).moveBy([20, 0], 2);
	
	assertTrue(GeomUtils.approx([0, 0], sp.getPosition()));
	
	Director.update();
	assertTrue(GeomUtils.approx([10, 0], sp.getPosition()));
	
	Director.update();
	assertTrue(GeomUtils.approx([20, 0], sp.getPosition()));

	Director.update();
	assertTrue(GeomUtils.approx([20, 10], sp.getPosition()));
	
	Director.update();
	assertTrue(GeomUtils.approx([20, 20], sp.getPosition()));
	
	Director.update();
	assertTrue(GeomUtils.approx([30, 20], sp.getPosition()));
	
	Director.update();
	assertTrue(GeomUtils.approx([40, 20], sp.getPosition()));
  }
  
  public function testSingleArgumentWait() {
    var done:Bool = false;
	
	Director.wait(2).call(function(x) {
		done = true;
	});
	
	assertFalse(done);
	Director.update();
	assertFalse(done);
	Director.update();
	assertTrue(done);
  }
}