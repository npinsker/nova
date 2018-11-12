package nova.pubsub;

/**
 * @author Nathan Pinsker
 */
class Publisher<T> {
	private var object:T;
	private var updateFn:T -> Publisher<T> -> Void;
	private var subscribers:Array<Subscriber<T>>;
	public function new(object:T, updateFn:T -> Publisher<T> -> Void) {
		this.object = object;
		this.updateFn = updateFn;
		this.subscribers = new Array<Subscriber<T>>();
	}
	
	public function add(subscriber:Subscriber<T>) {
		subscribers.push(subscriber);
	}
	
	public function remove(subscriber:Subscriber<T>) {
		subscribers.remove(subscriber);
	}
	
	public function update() {
		for (subscriber in subscribers) {
			subscriber.message = null;
		}
		updateFn(this.object, this);
	}
	
	public function emit(msg:Dynamic) {
		for (subscriber in subscribers) {
			subscriber.message = msg;
		}
	}
}