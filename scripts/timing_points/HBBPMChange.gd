# Timing point that denotes a change in BPM (bpm is used for calculating automatic time_out)
# keep in mind BPM changes apply to notes that end after the bpm change, this means that if
# the note appears earlier due to the time_out property it will still be affected by the BPM
# change
extends HBTimingPoint

class_name HBBPMChange

enum USAGE_TYPES {
	FIXED_BPM,
	AUTO_BPM
}

var bpm := 180.0
var speed_factor := 100.0
var usage = USAGE_TYPES.AUTO_BPM

func _init():
	serializable_fields += ["bpm", "usage", "speed_factor"]

func get_serialized_type():
	return "BpmChange"
	
static func can_show_in_editor():
	return true

func get_inspector_properties():
	return HBUtils.merge_dict(.get_inspector_properties(), {
		"bpm": {
			"type": "float",
			"params": {
				"min": 0,
				"suffix": " BPM",
			}
		},
	})

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemBPMChange.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item
