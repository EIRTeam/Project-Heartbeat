extends VBoxContainer

class_name HBRatingResultsDisplay

var ratings_update_queued := false

const ResultRatingScene = preload("res://rythm_game/results_screen/ResultRating.tscn")

var result_rating_scenes: Array[HBResultScreenRating]

func _queue_ratings_update():
	if not ratings_update_queued:
		ratings_update_queued = true
		_update_ratings.call_deferred()

var result: HBResult:
	set(val):
		result = val
		_queue_ratings_update()

func _ready() -> void:
	var values = HBJudge.JUDGE_RATINGS.values()
	for i in range(values.size()-1, -1, -1):
		var rating = values[i]
		var rating_scene: HBResultScreenRating = ResultRatingScene.instantiate()
		rating_scene.odd = i % 2 == 0
		add_child(rating_scene)
		result_rating_scenes.push_back(rating_scene)
		rating_scene.rating = rating

func _update_ratings():
	ratings_update_queued = false
	for rating in range(result_rating_scenes.size()):
		var rating_scene: HBResultScreenRating = result_rating_scenes[rating]
		rating_scene.percentage = 0
		if float(result.total_notes) > 0:
			var results = result.note_ratings[rating]
			if rating == HBJudge.JUDGE_RATINGS.WORST:
				# Add wrong notes
				for r in result.wrong_note_ratings.values():
					results += r
			rating_scene.percentage = results  / float(result.total_notes)
			rating_scene.total_notes = results
