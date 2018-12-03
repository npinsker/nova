package nova.pubsub;

/**
 * @author Nathan Pinsker
 */
class Subscriber {
	public var read:Dynamic -> Void;
	public var channel:String;
	
	public function new(channel:String, read:Dynamic -> Void) {
		this.channel = channel;
		this.read = read;
		
		var instance = PubSubFacilitator.instance;
		if (!instance.subscribers.exists(channel)) {
			instance.subscribers.set(channel, []);
		}
		instance.subscribers.get(channel).push(this);
	}
	
	public function destroy() {
		PubSubFacilitator.instance.subscribers.get(channel).remove(this);
	}
}