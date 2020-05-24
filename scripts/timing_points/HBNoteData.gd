# Base class for modern-style notes
extends HBBaseNote

class_name HBNoteData

const NOTE_GRAPHICS = {
	NOTE_TYPE.UP: {
		"note": preload("res://graphics/notes/xbox/Y.png"),
		"target": preload("res://graphics/notes/xbox/Y_target.png"),
		"hold_target": preload("res://graphics/notes/xbox/Y_target_hold.png")
	},
	NOTE_TYPE.DOWN: {
		"note": preload("res://graphics/notes/xbox/A.png"),
		"target": preload("res://graphics/notes/xbox/A_target.png"),
		"hold_target": preload("res://graphics/notes/xbox/A_target_hold.png")
	},
	NOTE_TYPE.LEFT: {
		"note": preload("res://graphics/notes/xbox/X.png"),
		"target": preload("res://graphics/notes/xbox/X_target.png"),
		"hold_target": preload("res://graphics/notes/xbox/X_target_hold.png")
	},
	NOTE_TYPE.RIGHT: {
		"note": preload("res://graphics/notes/xbox/B.png"),
		"target": preload("res://graphics/notes/xbox/B_target.png"),
		"hold_target": preload("res://graphics/notes/xbox/B_target_hold.png")
	},
	NOTE_TYPE.SLIDE_RIGHT: {
		"note": preload("res://graphics/notes/Slide_Right.png"),
		"target": preload("res://graphics/notes/Slide_Right_Target.png")
	},
	NOTE_TYPE.SLIDE_LEFT: {
		"note": preload("res://graphics/notes/Slide_Left.png"),
		"target": preload("res://graphics/notes/Slide_Left_Target.png")
	}
}

const NOTE_COLORS = {
	NOTE_TYPE.UP: {
		"color": "eeb136"
	},
	NOTE_TYPE.DOWN: {
		"color": "87d639"
	},
	NOTE_TYPE.LEFT: {
		"color": "4296f3"
	},
	NOTE_TYPE.RIGHT: {
		"color": "e02828"
	},
	NOTE_TYPE.SLIDE_LEFT: {
		"color": "f39e42"
	},
	NOTE_TYPE.SLIDE_RIGHT: {
		"color": "f39e42"
	}
}
var hold = false # If this is a modern-style hold note

func _init():
	serializable_fields += ["hold"]

func get_serialized_type():
	return "Note"
	
# gets the time out or returns automatically generated time_out
func get_time_out(bpm):
	if auto_time_out:
		return int((60.0  / bpm * (1 + 3) * 1000.0))
	else:
		return time_out
	
# Gets the scene that takes care of drawing this note
func get_drawer():
	return load("res://rythm_game/note_drawers/SingleNoteDrawer.tscn")

# returns the list of graphics for this note
static func get_note_graphics(type):
	var graphics = IconPackLoader.get_variations(HBUtils.find_key(NOTE_TYPE, type))
	if graphics == null:
		graphics = NOTE_GRAPHICS[type]
	return graphics
	
# unused...
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

# if true this note is a slide note hold piece
func is_slide_hold_piece():
	return note_type == NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE or note_type == NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE

# returns true if this is a note that can be automatically judged
func can_be_judged():
	return not note_type in NO_JUDGE_LIST
