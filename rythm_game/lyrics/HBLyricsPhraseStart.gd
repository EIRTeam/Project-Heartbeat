extends HBTimingPoint

class_name HBLyricsPhraseStart

func _init():
	_class_name = "HBLyricsPhraseStart" # Workaround for godot#4708
	_inheritance.append("HBTimingPoint")

func get_serialized_type():
	return "PhraseStart"

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorLyricPhraseTimelineItem.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item
