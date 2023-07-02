extends EditorTimelineItem

class_name EditorTimelineItemBPMChange

func _init():
	_class_name = "EditorTimelineItemBPMChange" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItem")
	
	data = HBBPMChange.new()
	update_affects_timing_points = true

func _ready():
	super._ready()
	sync_text()

func get_editor_size():
	return Vector2(50, size.y)

# Allow editing one at a time
func get_inspector_properties():
	return HBUtils.merge_dict(.get_inspector_properties(), {
		"usage": {
			"type": "list",
			"params": {
				"name": "Speed calculation method",
				"values": {
					"Automatic": HBBPMChange.USAGE_TYPES.AUTO_BPM,
					"Fixed": HBBPMChange.USAGE_TYPES.FIXED_BPM,
				},
				"affects_properties": ["bpm", "speed_factor"],
			}
		},
		"bpm": {
			"type": "float",
			"params": {
				"min": 0,
				"suffix": " BPM",
				"condition": "usage == %d" % HBBPMChange.USAGE_TYPES.FIXED_BPM,
			}
		},
		"speed_factor": {
			"type": "float",
			"params": {
				"min": 0,
				"suffix": "%",
				"condition": "usage == %d" % HBBPMChange.USAGE_TYPES.AUTO_BPM,
			}
		},
	})

func get_ph_editor_description():
	return "Changes the note speed (requires notes to have auto time-out enabled)"

func sync_value(property_name: String):
	super.sync_value(property_name)
	
	if property_name in ["usage", "speed_factor", "bpm"]:
		sync_text()

func sync_text():
	var text = ""
	
	if data.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
		text = str(data.speed_factor) + "%"
	else:
		text = str(data.bpm) + " BPM"
	
	# HACK: Resize the label after an idle frame, else we are just getting the old size
	$Label.text = text
	await get_tree().process_frame
	size.x = $Label.size.x
