package nova.render;
import nova.utils.Pair;

typedef Transition = {
	@:optional var frames:Int;
	@:optional var frameRate:Int;
	@:optional var move:Pair<Float>;
};

typedef TransitionData = {
	@:optional var show:Transition;
	@:optional var hide:Transition;
}
