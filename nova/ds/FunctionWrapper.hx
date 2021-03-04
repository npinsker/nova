package nova.ds;

class FunctionWrapper implements RealValuedFunction {
  public var fn:Float -> Float;

  public function new(fn:Float -> Float) {
    this.fn = fn;
  }

  public function getValueAt(point:Float):Float {
    return this.fn(point);
  }
}
