extends HBSerializable

class_name HBResult

var score = 0
var max_combo = 0
var total_notes = 0
var notes_hit = 0
var song_id = ""
var difficulty = ""
var failed = false
var note_ratings = {
	HBJudge.JUDGE_RATINGS.WORST: 0,
	HBJudge.JUDGE_RATINGS.SAD: 0,
	HBJudge.JUDGE_RATINGS.SAFE: 0,
	HBJudge.JUDGE_RATINGS.FINE: 0,
	HBJudge.JUDGE_RATINGS.COOL: 0
}

func _init():
	serializable_fields += ["score", "max_combo", "total_notes", "notes_hit", "note_ratings", "song_id", "difficulty", "failed"]

func get_serialized_type():
	return "Result"

enum RESULT_RATING {
	FAIL,
	CHEAP,
	STANDARD,
	GREAT,
	EXCELLENT,
	PERFECT
}

func get_result_rating():
	var failure = note_ratings[HBJudge.JUDGE_RATINGS.SAD]
	failure += note_ratings[HBJudge.JUDGE_RATINGS.SAFE]
	failure += note_ratings[HBJudge.JUDGE_RATINGS.WORST]
	if failure <= 0:
		return RESULT_RATING.PERFECT
		
	var pass_results = note_ratings[HBJudge.JUDGE_RATINGS.FINE] + note_ratings[HBJudge.JUDGE_RATINGS.COOL]
	pass_results = float(pass_results / float(total_notes))
	if failed:
		return RESULT_RATING.FAIL
	if pass_results >= 0.97:
		return RESULT_RATING.EXCELLENT
	elif pass_results >= 0.94:
		return RESULT_RATING.GREAT
	elif pass_results >= 0.85:
		return RESULT_RATING.STANDARD
	else:
		return RESULT_RATING.CHEAP
