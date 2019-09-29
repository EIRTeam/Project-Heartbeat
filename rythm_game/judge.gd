extends Node
# frames at 60 fps
const TARGET_WINDOW = 7.0

enum JUDGE_RATINGS {
	WORST
	SAD,
	SAFE,
	FINE,
	COOL
}
# Timing withing the frame window seen when going into it, not away
const DIFF_BASED_TIMING = [
	JUDGE_RATINGS.SAD,
	JUDGE_RATINGS.SAFE,
	JUDGE_RATINGS.SAFE,
	JUDGE_RATINGS.FINE,
	JUDGE_RATINGS.FINE,
	JUDGE_RATINGS.FINE,
	JUDGE_RATINGS.COOL,
]

func _ready():
	pass

func judge_note (input: float, target_note_timing: float):
	var adjusted_diff =  (input - target_note_timing) * 60.0
	if abs(adjusted_diff) < TARGET_WINDOW:
		if sign(adjusted_diff) == -1:
			var val = ceil(adjusted_diff)
			return DIFF_BASED_TIMING[val+TARGET_WINDOW-1]
		else:
			var val = floor(adjusted_diff)
			return DIFF_BASED_TIMING[TARGET_WINDOW-val-1]
	elif adjusted_diff >= TARGET_WINDOW:
		return JUDGE_RATINGS.WORST
