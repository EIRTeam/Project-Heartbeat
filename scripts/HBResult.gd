# A score result for a played song (usually comes inside a HBGameInfo)
extends HBSerializable

class_name HBResult
const MAX_SCORE_FROM_HOLD_BONUS = 0.075
const MAX_SCORE_FROM_SLIDE_BONUS = 0.075
# Total score (includes hold_bonus and slide_bonus)
var score = 0
# Score from holds
var hold_bonus = 0
# Score from chain slides
var slide_bonus = 0
var max_combo = 0
var total_notes = 0
var notes_hit = 0
var max_score = 1
var failed = false # if user failed, currently unused
var used_cheats = false # if user used autoplay

var _percentage_graph = []
var _combo_break_points = []
var _song_end_time = -1.0

var note_ratings = {
	HBJudge.JUDGE_RATINGS.WORST: 0,
	HBJudge.JUDGE_RATINGS.SAD: 0,
	HBJudge.JUDGE_RATINGS.SAFE: 0,
	HBJudge.JUDGE_RATINGS.FINE: 0,
	HBJudge.JUDGE_RATINGS.COOL: 0
}
# Wrong notes are notes that are hit on time but with the wrong button
var wrong_note_ratings = {
	HBJudge.JUDGE_RATINGS.WORST: 0,
	HBJudge.JUDGE_RATINGS.SAD: 0,
	HBJudge.JUDGE_RATINGS.SAFE: 0,
	HBJudge.JUDGE_RATINGS.FINE: 0,
	HBJudge.JUDGE_RATINGS.COOL: 0
}

func _init():
	serializable_fields += ["score", "max_combo", "total_notes", "notes_hit", "note_ratings",
	"wrong_note_ratings", "failed", "max_score",
	"hold_bonus", "slide_bonus", "used_cheats"]

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

func get_percentage() -> float:
	return get_capped_score()/max_score
# Capped score is the score with the capped hold and slide bonuses
# used for computing percentage
func get_capped_score():
	var base_score = score - hold_bonus - slide_bonus
	var capped_hold_bonus = clamp(hold_bonus, 0, MAX_SCORE_FROM_HOLD_BONUS*max_score)
	var capped_slide_bonus = clamp(slide_bonus, 0, MAX_SCORE_FROM_SLIDE_BONUS*max_score)
	return base_score + capped_hold_bonus + capped_slide_bonus
func get_result_rating() -> int:
	if failed:
		return RESULT_RATING.FAIL
	
	# All ratings except perfect and fail are score based
	
	var failure = note_ratings[HBJudge.JUDGE_RATINGS.SAD]
	failure += note_ratings[HBJudge.JUDGE_RATINGS.SAFE]
	failure += note_ratings[HBJudge.JUDGE_RATINGS.WORST]
	for r in wrong_note_ratings:
		failure += wrong_note_ratings[r]
	if failure <= 0:
		return RESULT_RATING.PERFECT

	var final_score_ratio = get_percentage()
	if final_score_ratio >= 0.95:
		return RESULT_RATING.EXCELLENT
	elif final_score_ratio >= 0.90:
		return RESULT_RATING.GREAT
	elif final_score_ratio >= 0.75:
		return RESULT_RATING.STANDARD
	else:
		return RESULT_RATING.CHEAP
