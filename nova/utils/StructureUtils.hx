package nova.utils;

class StructureUtils {
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
	
	public static function clone(struct:Dynamic):Dynamic {
		if (struct == null) {
			return null;
		}
		
		var newStruct:Dynamic = {};
		for (field in Reflect.fields(struct)) {
			Reflect.setField(newStruct, field, Reflect.field(struct, field));
		}
		return newStruct;
	}
	
	public static function prop(struct:Dynamic, prop:String):Dynamic {
		// TODO: support dots in property names: a.b.[Mr. Very Important Pup]
		var splitProp = prop.split('.');
		var index = 0;
		var point = struct;
		while (index < splitProp.length) {
			if (Reflect.hasField(point, splitProp[index])) {
				point = Reflect.field(point, splitProp[index]);
				index += 1;
			} else {
				return null;
			}
		}
		return point;
	}
}