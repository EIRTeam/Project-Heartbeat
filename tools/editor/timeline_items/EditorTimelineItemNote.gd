extends "res://tools/editor/timeline_items/EditorTimelineItem.gd"

class_name EditorTimelineItemNote

func _init():
	data = HBNoteData.new()

func get_inspector_properties():
	return {
		"time": {
			"type": "int"
		},
		"position": {
			"type": "Vector2"
		},
		"distance": {
			"type": "float"
		},
		"auto_time_out": {
			"type": "bool"
		},
		"time_out": {
			"type": "int"
		},
		"hold": {
			"type": "bool" 
		},
		"oscillation_amplitude": {
			"type": "float"
		},
		"oscillation_frequency": {
			"type": "int"
		},
		"entry_angle": {
			"type": "Angle"
		}
	}
