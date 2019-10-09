extends Node
const WINDOW_PER_TARGET = 16

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
	JUDGE_RATINGS.SAD,
	JUDGE_RATINGS.SAFE,
	JUDGE_RATINGS.SAFE,
	JUDGE_RATINGS.FINE,
	JUDGE_RATINGS.FINE,
	JUDGE_RATINGS.COOL,
]
# miliseconds from target where a value will be given
const RATING_WINDOWS = {
	128: JUDGE_RATINGS.SAD,
	96: JUDGE_RATINGS.SAFE,
	30: JUDGE_RATINGS.FINE,
	20: JUDGE_RATINGS.COOL
}

const RATING_TO_TEXT_MAP = {
	JUDGE_RATINGS.WORST: "WORST",
	JUDGE_RATINGS.SAD: "SAD",
	JUDGE_RATINGS.SAFE: "SAFE",
	JUDGE_RATINGS.FINE: "FINE",
	JUDGE_RATINGS.COOL: "COOL"
}
func judge_note (input: float, target_note_timing: float):
	var diff =  (input - target_note_timing)*1000
	var closest = 128
	
	if diff < -get_target_window_msec():
		return
	
	for rating_window in RATING_WINDOWS:
		if not rating_window < abs(diff):
			closest = rating_window
			
	if diff >= get_target_window_msec():
		return JUDGE_RATINGS.WORST
			
	print("DIFF", diff, closest)
	return RATING_WINDOWS[closest]

func get_target_window_msec():
	return RATING_WINDOWS.keys()[0]

func get_target_window_sec():
	return get_target_window_msec()/1000
