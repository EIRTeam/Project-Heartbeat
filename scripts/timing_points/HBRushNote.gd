extends HBBaseNote

class_name HBRushNote

var end_time: int
var auto_rush_hit_cap := true
var custom_rush_hit_cap := 32

func _init() -> void:
	super._init()
	_class_name = "HBRushNote" # Workaround for godot#4708
	_inheritance.append("HBBaseNote")
	serializable_fields += [
		"end_time",
		"auto_rush_hit_cap",
		"custom_rush_hit_cap"
	]

func get_serialized_type():
	return "RushNote"

func get_drawer_new():
	return preload("res://rythm_game/note_drawers/new/RushNoteDrawer.tscn")

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item

func get_inspector_properties():
	var props := super.get_inspector_properties() as Dictionary
	props.merge({
		"auto_rush_hit_cap": {
			"type": "bool",
			"params": {
				"affects_properties": ["custom_rush_hit_cap"],
			}
		},
		"custom_rush_hit_cap": {
			"type": "int",
			"params": {
				"min": 1,
				"suffix": " hits",
				"condition": "auto_rush_hit_cap == false",
			}
		},
		"end_time": {
			"type": "int",
			"params": {
				"suffix": "ms",
			}
		}
	})
	return props

func calculate_capped_hit_count() -> int:
	if not auto_rush_hit_cap:
		return custom_rush_hit_cap
	var duration_ms := end_time - time
	return duration_ms / 64

func get_duration():
	return end_time - time
