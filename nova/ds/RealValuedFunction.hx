package nova.ds;

/**
 * A function that maps real values to real values.
 * 
 * Usually used to map [0, 1] to [0, 1], for use in tweens.
 */
interface RealValuedFunction {
  public function getValueAt(point:Float):Float;
}
