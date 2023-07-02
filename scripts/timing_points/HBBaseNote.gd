# Base to all other notes
extends HBTimingPoint

class_name HBBaseNote

signal note_type_changed
# warning-ignore:unused_signal
signal hold_toggled
#warning-ignore:unused_signal
signal parameter_changed(parameter_name)

enum NOTE_TYPE {
	UP,
	LEFT,
	DOWN,
	RIGHT,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_CHAIN_PIECE_LEFT,
	SLIDE_CHAIN_PIECE_RIGHT,
	HEART
}

# List of notes that should NEVER EVER be considered multinotes
const NO_MULTI_LIST = [
	NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
	NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
]

# List of notes that do not accept input by themselves, instead it's handled 
# somewhere else
const NO_INPUT_LIST = [
	NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
	NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
]

# List of notes that should not be automatically judged
const NO_JUDGE_LIST = [
	NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
	NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
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
var entry_angle: float = 0.0 # The angle at which the note comes in
var oscillation_amplitude: float = 500.0
var oscillation_frequency: int = 2
var distance: float = 1200.0 # The distance the note travels from spawn point to target

var pos_modified: bool = false # whether or not the user has modified the note's position on the editor

@export var note_type: NOTE_TYPE = NOTE_TYPE.RIGHT: set = set_note_type

func set_note_type(value):
	note_type = value
	emit_signal("note_type_changed")

# gets the time out or returns automatically generated time_out
func get_time_out(bpm) -> int:
	if auto_time_out:
		if bpm == 0:
			return 9223372036854775807
		
		return int((60.0  / bpm * (1 + 3) * 1000.0))
	else:
		return time_out

# returns the list of graphics for this note
static func get_note_graphic(type, variant):
	var graphics = ResourcePackLoader.get_graphic("%s_%s.png" % [HBGame.NOTE_TYPE_TO_STRING_MAP[type], variant])
	return graphics

func get_inspector_properties():
	return {
		"time": {
			"type": "int",
			"params": {
				"suffix": "ms",
			}
		},
		"position": {
			"type": "Vector2",
			"params": {
				"suffix": "px",
			}
		},
		"distance": {
			"type": "float",
			"params": {
				"suffix": "px",
			}
		},
		"auto_time_out": {
			"type": "bool",
			"params": {
				"affects_properties": ["time_out"],
			}
		},
		"time_out": {
			"type": "int",
			"params": {
				"suffix": "ms",
				"condition": "auto_time_out == false",
			}
		},
		"oscillation_amplitude": {
			"type": "float",
			"params": {
				"min": -INF,
				"max": INF,
				"show_toggle_negative_button": true
			}
		},
		"oscillation_frequency": {
			"type": "float",
			"params": {
				"min": -INF,
				"max": INF,
				"show_toggle_negative_button": true
			}
		},
		"entry_angle": {
			"type": "Angle"
		}
	}

func _init():
	super._init()
	_class_name = "HBBaseNote" # Workaround for godot#4708
	_inheritance.append("HBTimingPoint")
	
	serializable_fields += ["position", "pos_modified", "distance", "auto_time_out", "time_out",
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
	return not note_type == NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT and not note_type == NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
