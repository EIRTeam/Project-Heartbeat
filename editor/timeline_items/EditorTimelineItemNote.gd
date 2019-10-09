extends "res://editor/timeline_items/EditorTimelineItem.gd"

class_name EditorTimelineItemNote

func _init():
	data = HBNoteData.new()

func get_inspector_properties():
	return {
		"time": "int",
		"position": "Vector2",
		"time_out": "int",
		"entry_angle": "Angle"
	}
