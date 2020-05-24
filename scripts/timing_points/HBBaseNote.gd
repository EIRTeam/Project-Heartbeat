# Base to all other notes

extends HBTimingPoint

class_name HBBaseNote

enum NOTE_TYPE {
	UP,
	LEFT,
	DOWN,
	RIGHT,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_LEFT_HOLD_PIECE,
	SLIDE_RIGHT_HOLD_PIECE,
#	HEART
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

signal note_type_changed

func _init():
	serializable_fields += ["position", "distance", "auto_time_out", "time_out", "note_type", "entry_angle", "oscillation_amplitude", "oscillation_frequency"]


