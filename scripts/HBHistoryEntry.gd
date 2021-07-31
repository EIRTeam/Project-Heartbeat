extends HBSerializable

class_name HBHistoryEntry

var highest_score_info: HBGameInfo = HBGameInfo.new()
var highest_score: int = 0
var highest_rating: int = HBResult.RESULT_RATING.CHEAP
var highest_percentage: float = 0.0

func _init():
	serializable_fields += [
		"highest_score_info",
		"highest_score",
		"highest_percentage",
		"highest_rating"
	]

func get_serialized_type() -> String:
	return "HBHistoryEntry"

func is_result_better(result: HBResult):
	return result.score > highest_score or \
		result.get_result_rating() > highest_rating or \
		result.get_percentage() > highest_percentage

func update(game_info: HBGameInfo):
	if game_info.result.score > highest_score_info.result.score:
		highest_score_info = game_info.clone()
		highest_score = game_info.result.score
	highest_percentage = max(highest_percentage, game_info.result.get_percentage())
	highest_rating = max(highest_rating, game_info.result.get_result_rating())
