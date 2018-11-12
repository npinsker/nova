package nova.pubsub;

/**
 * @author Nathan Pinsker
 */
class Subscriber<T> {
	public var message:Dynamic;
	
	public function subscribe(publisher:Publisher<T>) {
		publisher.add(this);
	}
	
	public function read():Dynamic {
		return message;
	}
	
	public function update() { }
}