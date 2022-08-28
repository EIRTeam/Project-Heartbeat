extends EditorTimelineItem

class_name EditorTimelineItemBPMChange

func _init():
	_class_name = "EditorTimelineItemBPMChange" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItem")
	
	data = HBBPMChange.new()
	update_affects_timing_points = true

func get_editor_size():
	return Vector2(50, rect_size.y)

func get_inspector_properties():
	return HBUtils.merge_dict(.get_inspector_properties(), {
		"bpm": {
			"type": "int",
			"params": {
				"min": 1
			}
		}
	})

func get_editor_description():
	return "Changes the BPM (requires notes to have auto time-out enabled)"
