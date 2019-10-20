extends HBDurationNoteData

class_name HBHoldNoteData

func _init():
	._init()
	
func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemHoldNote.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item

func get_drawer():
	return load("res://rythm_game/HoldNoteDrawer.tscn")

func get_serialized_type():
	return "HoldNote"
