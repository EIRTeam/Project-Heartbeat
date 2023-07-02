extends HBNoteData

class_name HBDurationNoteData

var duration = 3000

func _init():
	super._init()
	serializable_fields += ["duration"]

func get_duration():
	return duration

func get_serialized_type():
	return "DurationNote"
