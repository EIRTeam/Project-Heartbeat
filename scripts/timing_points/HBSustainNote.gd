# Base class for modern-style notes
extends HBBaseNote

class_name HBSustainNote

var end_time = 1000

func _init():
	super._init()
	_class_name = "HBSustainNote" # Workaround for godot#4708
	_inheritance.append("HBBaseNote")
	
	serializable_fields += ["end_time"]

func get_serialized_type():
	return "SustainNote"
	
# Gets the scene that takes care of drawing this note
func get_drawer_new():
	return preload("res://rythm_game/note_drawers/new/SustainNoteDrawer.tscn")

static func can_show_in_editor():
	return false

# returns the scene that takes care of drawing the note in the timeline
func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemSustainNote.tscn")
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

func is_auto_freed():
	return false

func get_duration():
	return end_time - time
