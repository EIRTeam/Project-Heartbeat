extends HBBaseNote

class_name HBRushNote

var end_time: int

func _init() -> void:
	super._init()
	_class_name = "HBRushNote" # Workaround for godot#4708
	_inheritance.append("HBBaseNote")
	serializable_fields += [
		"end_time"
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
	return HBUtils.merge_dict(super.get_inspector_properties(), {
		"end_time": {
			"type": "int",
			"params": {
				"suffix": "ms",
			}
		}
	})

func calculate_capped_hit_count() -> int:
	var duration_ms := end_time - time
	return duration_ms / 64

func get_duration():
	return end_time - time
