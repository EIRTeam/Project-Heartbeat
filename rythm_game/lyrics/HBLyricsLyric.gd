extends HBTimingPoint

class_name HBLyricsLyric

var value: String = ""

func _init():
	serializable_fields += ["value"]

func get_serialized_type():
	return "Lyric"
	
func get_inspector_properties():
	return HBUtils.merge_dict(.get_inspector_properties(), {
		"value": {
			"type": "String"
		},
	})

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorLyricPhraseTimelineItem.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item
