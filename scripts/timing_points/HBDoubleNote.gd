# Base class for modern-style notes
extends HBBaseNote

class_name HBDoubleNote

func _init():
	super._init()
	_class_name = "HBDoubleNote" # Workaround for godot#4708
	_inheritance.append("HBBaseNote")

func get_serialized_type():
	return "DoubleNote"
	
static func can_show_in_editor():
	return false

# returns the scene that takes care of drawing the note in the timeline
func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item

func get_drawer_new():
	return load("res://rythm_game/note_drawers/new/DoubleNoteDrawer.tscn")
