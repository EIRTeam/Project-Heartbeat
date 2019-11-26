extends HBSerializable

class_name HBResult

var score = 0
var max_combo = 0
var total_notes = 0
var notes_hit = 0
var song_id = ""
var difficulty = ""
var note_ratings = {
	HBJudge.JUDGE_RATINGS.WORST: 0,
	HBJudge.JUDGE_RATINGS.SAD: 0,
	HBJudge.JUDGE_RATINGS.SAFE: 0,
	HBJudge.JUDGE_RATINGS.FINE: 0,
	HBJudge.JUDGE_RATINGS.COOL: 0
}

func _init():
	serializable_fields += ["score", "max_combo", "total_notes", "notes_hit", "note_ratings", "song_id", "difficulty"]

func get_serialized_type():
	return "Result"
