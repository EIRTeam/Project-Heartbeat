extends "res://editor/timeline_items/EditorTimelineItemSingleNote.gd"

func _init():
	update_affects_timing_points = true

func get_inspector_properties():
	var props = HBUtils.merge_dict(.get_inspector_properties(),  {
		"duration": "int",
		"number_of_notes": "int"
	})
	return props 

func get_duration():
	return data.duration
