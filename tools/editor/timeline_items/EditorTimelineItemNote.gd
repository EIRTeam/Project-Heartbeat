extends "res://tools/editor/timeline_items/EditorTimelineItem.gd"

class_name EditorTimelineItemNote

func _init():
	data = HBNoteData.new()

func get_inspector_properties():
	return {
		"time": "int",
		"position": "Vector2",
		"distance": "float",
		"auto_time_out": "bool",
		"time_out": "int",
		"oscillation_amplitude": "float",
		"oscillation_frequency": "int",
		"entry_angle": "Angle",
	}
