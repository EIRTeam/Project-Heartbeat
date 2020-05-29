extends "res://tools/editor/timeline_items/EditorTimelineItem.gd"

class_name EditorTimelineItemNote

func _init():
	data = HBNoteData.new()

func get_inspector_properties():
	return
