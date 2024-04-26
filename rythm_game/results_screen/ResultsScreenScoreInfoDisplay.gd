extends MarginContainer

class_name HBResultsScreenScoreInfoDisplay

@onready var rating_label: Label = get_node("%RatingLabel")

@onready var percentage_new_record_label: RichTextLabel = get_node("%PercentageNewRecordLabel")
@onready var new_percentage_label: Label = get_node("%NewPercentageLabel")
@onready var percentage_delta_label: Label = get_node("%PercentageDeltaLabel")

@onready var score_new_record_label: RichTextLabel = get_node("%ScoreNewRecordLabel")
@onready var new_score_label: Label = get_node("%NewScoreLabel")
@onready var score_delta_label: Label = get_node("%ScoreDeltaLabel")

var result_update_queued := false

func _queue_result_update():
	if not result_update_queued:
		result_update_queued = true
		_update_result.call_deferred()

var result: HBResult:
	set(val):
		result = val
		_queue_result_update()
var prev_result: HBResult:
	set(val):
		prev_result = val
		_queue_result_update()

func _update_result():
	if not result:
		rating_label.text = "..."
	else:
		rating_label.text = HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating())
	_update_percentage()
	_update_score()
	
func _update_score():
	score_delta_label.hide()
	score_new_record_label.hide()
	if not result:
		new_score_label.text = "..."
		return
	var new_score := result.score
	
	new_score_label.text = HBUtils.thousands_sep(new_score)
	if prev_result:
		var prev_score := prev_result.score
		score_new_record_label.visible = prev_score < new_score
		score_delta_label.show()
		var sign := "-" if sign(new_score - prev_score) == -1 else "+"
		score_delta_label.text = sign + HBUtils.thousands_sep(abs(new_score-prev_score))
	
func _update_percentage():
	percentage_delta_label.hide()
	percentage_new_record_label.hide()

	if not result:
		new_percentage_label.text = "..."
		return

	var new_percentage := result.get_percentage()
	new_percentage_label.text = "%.2f%%" % [new_percentage*100.0]

	if prev_result:
		var prev_percentage := prev_result.get_percentage()
		percentage_delta_label.show()
		percentage_new_record_label.visible = prev_percentage < new_percentage
		var sign := "-" if sign(new_percentage - prev_percentage) == -1 else "+"
		percentage_delta_label.text = sign + "%.2f%%" % [abs(new_percentage-prev_percentage) * 100.0]
