extends HBTimingPoint

class_name HBLyricsPhrase

var lyrics = []
var end_time: int = 0

func _init():
	serializable_fields += ["lyrics", "end_time", "time"]

func get_serialized_type():
	return "Phrase"

func get_min_time() -> int:
	return time

func get_max_time() -> int:
	return end_time

func get_inspector_properties():
	return HBUtils.merge_dict(super.get_inspector_properties(), {
		"end_time": {
			"type": "int"
		},
	})
func get_phrase_string() -> String:
	var r = ""
	for lyric in lyrics:
		r += lyric.value
	return r

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorLyricPhraseTimelineItem.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item
