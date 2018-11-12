package nova.pubsub;

/**
 * ...
 * @author Nathan Pinsker
 */
class PubSubFacilitator {
	public static var instance(default, null):PubSubFacilitator = new PubSubFacilitator();
	
	public var publishers
	public var subscribers:Array<Subscriber>;

	public function new() {
		
	}
	
	public function update() {
		
	}
}