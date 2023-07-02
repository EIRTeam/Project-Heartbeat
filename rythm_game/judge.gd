class_name HBJudge
enum JUDGE_RATINGS {
	WORST,
	SAD,
	SAFE,
	FINE,
	COOL
}
# miliseconds from target where a value will be given
const RATING_WINDOWS = {
	128: JUDGE_RATINGS.SAD,
	96: JUDGE_RATINGS.SAFE,
	64: JUDGE_RATINGS.FINE,
	32: JUDGE_RATINGS.COOL
}
const RATING_TO_COLOR = {
	JUDGE_RATINGS.COOL: "#ffd022",
	JUDGE_RATINGS.FINE: "#4ebeff",
	JUDGE_RATINGS.SAFE: "#00a13c",
	JUDGE_RATINGS.SAD: "#57a9ff",
	JUDGE_RATINGS.WORST: "#e470ff"
}
const RATING_TO_TEXT_MAP = {
	JUDGE_RATINGS.WORST: "WORST/WRONG",
	JUDGE_RATINGS.SAD: "SAD",
	JUDGE_RATINGS.SAFE: "SAFE",
	JUDGE_RATINGS.FINE: "FINE",
	JUDGE_RATINGS.COOL: "COOL"
}
const RATING_TO_WRONG_TEXT_MAP = {
	JUDGE_RATINGS.WORST: "WORST",
	JUDGE_RATINGS.SAD: "sAd",
	JUDGE_RATINGS.SAFE: "sAfE",
	JUDGE_RATINGS.FINE: "fInE",
	JUDGE_RATINGS.COOL: "CoOl"
}

var timing_window_scale = 1.0

func judge_note(hit_time_msec: int, target_note_time: int) -> int:
	var diff =  hit_time_msec - target_note_time
	var closest = 128 * timing_window_scale
	
	if diff < -get_target_window_msec():
		return -1
	
	for i in range(RATING_WINDOWS.size()-1, -1, -1):
		var rating_window = int(RATING_WINDOWS.keys()[i] * timing_window_scale)
		if rating_window >= abs(diff):
			closest = RATING_WINDOWS.keys()[i]
			break
	if diff >= get_target_window_msec():
		return JUDGE_RATINGS.WORST
	return RATING_WINDOWS[closest]

func get_target_window_msec():
	return int(RATING_WINDOWS.keys()[0] * timing_window_scale)

func get_window_for_rating(rating):
	return int(HBUtils.find_key(RATING_WINDOWS, rating) * timing_window_scale)
func get_target_window_sec():
	return get_target_window_msec()/1000
