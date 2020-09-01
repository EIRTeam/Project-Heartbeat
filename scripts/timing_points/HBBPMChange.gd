# Timing point that denotes a change in BPM (bpm is used for calculating automatic time_out)
# keep in mind BPM changes apply to notes that end after the bpm change, this means that if
# the note appears earlier due to the time_out property it will still be affected by the BPM
# change
extends HBTimingPoint

class_name HBBPMChange

var bpm = 180.0

func _init():
	serializable_fields += ["bpm"]

func get_serialized_type():
	return "BpmChange"
	
static func can_show_in_editor():
	return true

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemBPMChange.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item
