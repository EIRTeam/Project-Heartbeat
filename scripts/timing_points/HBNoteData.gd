# Base class for modern-style notes
extends HBBaseNote

var drawer = load("res://rythm_game/note_drawers/SingleNoteDrawer.tscn")

class_name HBNoteData

var hold = false # If this is a modern-style hold note

func _init():
	serializable_fields += ["hold"]

func get_serialized_type():
	return "Note"
	
# Gets the scene that takes care of drawing this note
func get_drawer():
	return drawer

static func can_show_in_editor():
	return false

# returns the scene that takes care of drawing the note in the timeline
func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item

# if true this note is a slide note
func is_slide_note():
	return note_type == NOTE_TYPE.SLIDE_LEFT or note_type == NOTE_TYPE.SLIDE_RIGHT

func get_inspector_properties():
	return HBUtils.merge_dict(.get_inspector_properties(), 	{"hold": {
			"type": "bool" 
		}})

# if true this note is a slide note hold piece
func is_slide_hold_piece():
	return note_type == NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE or note_type == NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
