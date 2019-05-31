package nova.pubsub;

/**
 * Not used.
 */
class PubSubFacilitator {
	public static var instance(default, null):PubSubFacilitator = new PubSubFacilitator();
	
	public var subscribers:Map<String, Array<Subscriber>>;

	public function new() {
		subscribers = new Map<String, Array<Subscriber>>();
	}
	
	public function emit(channel:String, data:Dynamic) {
		if (subscribers.exists(channel)) {
			for (s in subscribers.get(channel)) {
				s.read(data);
			}
		}
	}
}
