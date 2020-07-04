# Base to all other notes
extends HBTimingPoint

class_name HBBaseNote

signal note_type_changed

enum NOTE_TYPE {
	UP,
	LEFT,
	DOWN,
	RIGHT,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_LEFT_HOLD_PIECE,
	SLIDE_RIGHT_HOLD_PIECE,
	HEART
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

var position: Vector2 = Vector2(960, 540) # Position is in a 1920x1080 area
var time_out: int = 1400 # time from the hit point where the note target starts being visible
var auto_time_out: bool = true # If we should get the time out value from the current BPM
var entry_angle: float = 0.0 # The angle at which the ntoe comes in
var oscillation_amplitude = 500.0
var oscillation_frequency = 2.0
var distance = 1200.0 # The distance the note travels from spawn point to target

export (NOTE_TYPE) var note_type := NOTE_TYPE.RIGHT setget set_note_type

func set_note_type(value):
	note_type = value
	emit_signal("note_type_changed")

# gets the time out or returns automatically generated time_out
func get_time_out(bpm):
	if auto_time_out:
		return int((60.0  / bpm * (1 + 3) * 1000.0))
	else:
		return time_out

# returns the list of graphics for this note
static func get_note_graphic(type, variation):
	var graphics = IconPackLoader.get_graphic(HBUtils.find_key(NOTE_TYPE, type), variation)
	return graphics

func get_inspector_properties():
	return {
		"time": {
			"type": "int"
		},
		"position": {
			"type": "Vector2"
		},
		"distance": {
			"type": "float"
		},
		"auto_time_out": {
			"type": "bool"
		},
		"time_out": {
			"type": "int"
		},
		"oscillation_amplitude": {
			"type": "float"
		},
		"oscillation_frequency": {
			"type": "int"
		},
		"entry_angle": {
			"type": "Angle"
		}
	}

func _init():
	serializable_fields += ["position", "distance", "auto_time_out", "time_out",
	"note_type", "entry_angle", "oscillation_amplitude", "oscillation_frequency"]

func get_score(rating):
	return NOTE_SCORES[rating]

func get_input_actions():
	return HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_type]

# returns true if this is a note that can be automatically judged
func can_be_judged():
	return not note_type in NO_JUDGE_LIST
	
# If the note is automatically freed upon first judgement
func is_auto_freed():
	return true
	
func is_multi_allowed():
	return not note_type == NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE and not note_type == NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
