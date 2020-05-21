# Base class for modern-style notes
extends HBTimingPoint

class_name HBNoteData

enum NOTE_TYPE {
	UP,
	LEFT,
	DOWN,
	RIGHT,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_LEFT_HOLD_PIECE,
	SLIDE_RIGHT_HOLD_PIECE
}

# List of notes that should NEVER EVER be considered multinotes
const NO_MULTI_LIST = [
	NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
	NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
]

# List of notes that do not accept input by themselves, instead it's handled 
# somewhere else
const NO_INPUT_LIST = [
	NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
	NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
]

# List of notes that should not be automatically judged
const NO_JUDGE_LIST = [
	NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
	NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
]

# Judge ratings mapped to their scores
const NOTE_SCORES = {
	HBJudge.JUDGE_RATINGS.COOL: 1000,
	HBJudge.JUDGE_RATINGS.FINE: 800,
	HBJudge.JUDGE_RATINGS.SAFE: 500,
	HBJudge.JUDGE_RATINGS.SAD: 100,
	HBJudge.JUDGE_RATINGS.WORST: 0
}
export (NOTE_TYPE) var note_type := NOTE_TYPE.RIGHT setget set_note_type

signal note_type_changed

func set_note_type(value):
	note_type = value
	emit_signal("note_type_changed")

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
var position: Vector2 = Vector2(960, 540) # Position is in a 1920x1080 area
var time_out: int = 1400 # time from the hit point where the note target starts being visible
var auto_time_out: bool = true # If we should get the time out value from the current BPM
var entry_angle: float = 0.0 # The angle at which the ntoe comes in
var oscillation_amplitude = 500.0
var oscillation_frequency = 2.0
var distance = 1200.0 # The distance the note travels from spawn point to target
var hold = false # If this is a modern-style hold note

func _init():
	serializable_fields += ["position", "distance", "auto_time_out", "time_out", "note_type", "entry_angle", "oscillation_amplitude", "oscillation_frequency", "hold"]

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
	return load("res://rythm_game/SingleNoteDrawer.tscn")

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
