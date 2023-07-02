extends HBTimingPoint

class_name HBIntroSkipMarker

func _init():
	_class_name = "HBIntroSkipMarker" # Workaround for godot#4708
	_inheritance.append("HBTimingPoint")

func get_serialized_type():
	return "IntroSkipMarker"
	
static func can_show_in_editor():
	return true

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemIntroSkipMarker.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item
