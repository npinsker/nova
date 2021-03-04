package nova.tile;

import flixel.math.FlxRect;
import nova.utils.Pair;

interface CollisionSet {
  public function getOverlappingObjects(rect:FlxRect):Array<CollisionShape>;
  
  //public function getOverlappingObjectsPoint(point:Pair<Float>):Array<CollisionShape>;
}