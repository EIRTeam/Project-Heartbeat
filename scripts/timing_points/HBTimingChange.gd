extends HBTimingPoint

class_name HBTimingChange

var bpm := 120.0
var time_signature := {
	"numerator": 4,
	"denominator": 4,
}

func _init():
	_class_name = "HBTimingChange" # Workaround for godot#4708
	_inheritance.append("HBTimingPoint")
	
	serializable_fields += ["bpm", "time_signature"]

func get_serialized_type():
	return "TimingChange"

static func can_show_in_editor():
	return true

func get_inspector_properties():
	return HBUtils.merge_dict(super.get_inspector_properties(), {
		"bpm": {
			"type": "float",
			"params": {
				"min": 0.01,
				"suffix": " BPM",
			}
		},
		"time_signature": {
			"type": "time_signature",
		},
	})

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimingChangeTimelineItem.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item
