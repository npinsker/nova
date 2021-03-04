package nova.trigger;

import nova.animation.Director;
import nova.ui.dialog.DialogParser;
import nova.ui.dialog.ExpressionNode;
import nova.utils.Pair;
import flixel.util.typeLimit.OneOfTwo;

using StringTools;

class TriggerEffect {
  public var type:String;
  public var params:Dynamic;

  public function new(type:String, params:Dynamic) {
    this.type = type;
    this.params = params;
  }
}

class TriggerNode {
    public var children:Array<OneOfTwo<TriggerNode, TriggerEffect>>;

    public function new() {
        children = [];
    }
}

class Trigger {
  public var name:String;
  public var conditions:Array<ExpressionNode>;
  public var effects:TriggerNode;

  public function new() {
    this.conditions = new Array<ExpressionNode>();
    this.effects = new TriggerNode();
  }
}
