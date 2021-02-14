extends "res://tools/editor/timeline_items/EditorTimelineItem.gd"

class_name EditorTimelineItemIntroSkip

func _init():
	data = HBBPMChange.new()
	update_affects_timing_points = true
func get_editor_size():
	return Vector2(100, rect_size.y)

func get_editor_description():
	return """Sets the time to skip to when the intro skip feature is used
	This MUST be before the first note, otherwise the default 5000 ms margin is used
	Make sure to change \"Intro Skip Minimum Time\" in the metadata editor too."""
