extends TabbedContainerTab

class_name HBResultsScreenResultTab

@onready var rating_results_container: HBRatingResultsDisplay = get_node("%RatingResultsContainer")
@onready var score_info_display: HBResultsScreenScoreInfoDisplay = get_node("%ScoreInfoDisplay")
@onready var experience_info_container: HBResultsScreenExperienceInfoDisplay = get_node("%ExperienceInfoContainer")
@onready var note_hit_totals_container: HBResultsScreenNoteHitTotalsDisplay = get_node("%NoteHitTotalsContainer")

var _result_update_queued := false
func _queue_result_update():
	if not _result_update_queued:
		_result_update_queued = true
		_update_result.call_deferred()

var result: HBResult:
	set(val):
		result = val
		_queue_result_update()
var prev_result: HBResult:
	set(val):
		prev_result = val
		_queue_result_update()

var experience_gain: HBBackend.LeaderboardScoreUploadedResult.ExperienceGainBreakdown:
	set(val):
		experience_gain = val
		_queue_result_update()

func _update_result():
	_result_update_queued = false
	rating_results_container.result = result
	score_info_display.result = result
	experience_info_container.game_result = result
	note_hit_totals_container.result = result
	if not experience_gain:
		experience_info_container.hide()
	else:
		experience_info_container.show()
		experience_info_container.experience_gain_info = experience_gain
	
	if prev_result:
		score_info_display.prev_result = prev_result
