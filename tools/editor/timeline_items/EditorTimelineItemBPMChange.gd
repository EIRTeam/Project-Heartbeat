extends "res://tools/editor/timeline_items/EditorTimelineItem.gd"

class_name EditorTimelineItemBPMChange

func _init():
	data = HBBPMChange.new()
	update_affects_timing_points = true

func get_inspector_properties():
	return {
		"time": "int",
		"bpm": "int"
	}
