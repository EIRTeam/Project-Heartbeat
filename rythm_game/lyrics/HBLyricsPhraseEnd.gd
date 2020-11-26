extends HBTimingPoint

class_name HBLyricsPhraseEnd

func get_serialized_type():
	return "PhraseEnd"

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorLyricPhraseTimelineItem.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item
