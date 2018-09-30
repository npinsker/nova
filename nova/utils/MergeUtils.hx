package nova.utils;

class MergeUtils {
	public static function merge(struct1:Dynamic, struct2:Dynamic):Dynamic {
		var merged:Dynamic = {};
		if (struct2 != null) {
			for (field in Reflect.fields(struct2)) {
				Reflect.setField(merged, field, Reflect.field(struct2, field));
			}
		}
		if (struct1 != null) {
			for (field in Reflect.fields(struct1)) {
				if (!Reflect.hasField(merged, field)) {
					Reflect.setField(merged, field, Reflect.field(struct1, field));
				}
			}
		}
		return merged;
	}
}