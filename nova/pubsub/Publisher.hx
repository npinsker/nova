package nova.pubsub;

/**
 * @author Nathan Pinsker
 */
class Publisher<T> {
	public var channel:String;
	public var ref:T;
	
	public function new(channel:String, ref:T) {
		this.channel = channel;
		this.ref = ref;
	}
	
	public function update():Void { }
	
	public function emit(data:Dynamic) {
		PubSubFacilitator.instance.emit(channel, data);
	}
}