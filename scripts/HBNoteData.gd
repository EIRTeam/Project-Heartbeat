extends HBTimingPoint

class_name HBNoteData

enum NOTE_TYPE {
	UP,
	LEFT,
	DOWN,
	RIGHT,
	SLIDE_LEFT,
	SLIDE_RIGHT
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
var position: Vector2 = Vector2(960, 540) # Position goes from 0 to 1, in a 16:9 play area
var time_out: int = 1400 # time where the note target starts being visible
var auto_time_out: bool = true # If we should get the time out value from BPM change events
var entry_angle: float = 0.0
var oscillation_amplitude = 500.0
var oscillation_frequency = 2.0
var distance = 1200.0
func _init():
	serializable_fields += ["position", "distance", "auto_time_out", "time_out", "note_type", "entry_angle", "oscillation_amplitude", "oscillation_frequency"]

func get_serialized_type():
	return "Note"
	
func get_time_out(bpm):
	if auto_time_out:
		return int((60.0  / bpm * (1 + 3) * 1000.0))
	else:
		return time_out
	
func get_drawer():
	return load("res://rythm_game/SingleNoteDrawer.tscn")

static func get_note_graphics(type):
	var graphics = IconPackLoader.get_variations(HBUtils.find_key(NOTE_TYPE, type))
	if graphics == null:
		graphics = NOTE_GRAPHICS[type]
	return graphics
	
static func can_show_in_editor():
	return false
	
func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item
