# Base class for modern-style notes
extends HBBaseNote

class_name HBNoteData

var hold = false: set = set_hold

func _init():
	super._init()
	_class_name = "HBNoteData" # Workaround for godot#4708
	_inheritance.append("HBBaseNote")
	
	serializable_fields += ["hold"]

func get_serialized_type():
	return "Note"
	
func get_drawer_new():
	if not is_slide_note():
		return load("res://rythm_game/note_drawers/new/SingleNoteDrawer.tscn")
	else:
		return load("res://rythm_game/note_drawers/new/SlideNoteDrawer.tscn")

static func can_show_in_editor():
	return false

# returns the scene that takes care of drawing the note in the timeline
func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item

# if true this note is a slide note
func is_slide_note():
	return note_type == NOTE_TYPE.SLIDE_LEFT or note_type == NOTE_TYPE.SLIDE_RIGHT

# if true this note is a slide note hold piece
func is_slide_hold_piece():
	return note_type == NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT or note_type == NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT

# return the corresponding hold piece type for a given slider
func get_chain_type():
	return NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT if note_type == NOTE_TYPE.SLIDE_LEFT else NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT

func get_inspector_properties():
	if self.is_slide_hold_piece():
		return super.get_inspector_properties()
	else:
		return HBUtils.merge_dict(
			super.get_inspector_properties(), 
			{
				"hold": {
					"type": "bool" 
				}
			}
		)

# If the note is automatically freed upon first judgement
func is_auto_freed():
	return not is_slide_note()

func set_hold(val):
	hold = val
	emit_signal("hold_toggled")
