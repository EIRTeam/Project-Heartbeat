extends HBSerializable

var timing_window = 256

func _init():
	serializable_fields += ["timing_window"]

func get_serialized_type():
	return "TimingModifierSettings"
