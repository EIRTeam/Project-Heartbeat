extends MarginContainer

class_name HBResultsScreenScoreInfoDisplay

@onready var rating_label: Label = get_node("%RatingLabel")
@onready var rating_badge_texture_rect: TextureRect = get_node("%RatingTextureRect")

@onready var percentage_new_record_label: RichTextLabel = get_node("%PercentageNewRecordLabel")
@onready var new_percentage_label: Label = get_node("%NewPercentageLabel")
@onready var percentage_delta_label: RichTextLabel = get_node("%PercentageDeltaLabel")

@onready var score_new_record_label: RichTextLabel = get_node("%ScoreNewRecordLabel")
@onready var new_score_label: Label = get_node("%NewScoreLabel")
@onready var score_delta_label: RichTextLabel = get_node("%ScoreDeltaLabel")

const DELTA_NEGATIVE_COLOR = Color("#57a9ff")
const DELTA_POSITIVE_COLOR = Color("#57ff59")

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
		var result_rating := result.get_result_rating()
		rating_label.text = HBUtils.find_key(HBResult.RESULT_RATING, result_rating)
		rating_badge_texture_rect.texture = HBUtils.get_clear_badge(result_rating)
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
		score_delta_label.clear()
		score_delta_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		var new_text := tr("Best: {score_best}", &"Used in the results screen info display")
		new_text = new_text.format({
			"score_best": HBUtils.thousands_sep(max(new_score, prev_score)) + " ("
		})
		score_delta_label.add_text(new_text)
		var color := DELTA_NEGATIVE_COLOR if sign == "-" else DELTA_POSITIVE_COLOR
		score_delta_label.push_color(color)
		score_delta_label.add_text(sign + HBUtils.thousands_sep(abs(new_score-prev_score)))
		score_delta_label.pop()
		score_delta_label.add_text(")")
		score_delta_label.pop()
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
		var color := DELTA_NEGATIVE_COLOR if sign == "-" else DELTA_POSITIVE_COLOR
		percentage_delta_label.clear()
		percentage_delta_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		var new_text := tr("Best: {percentage_best}", &"Used in the results screen info display")
		new_text = new_text.format({
			"percentage_best": "%.2f%%" % [max(new_percentage, prev_percentage) * 100.0] + " ("
		})
		percentage_delta_label.add_text(new_text)
		percentage_delta_label.push_color(color)
		percentage_delta_label.add_text(sign + "%.2f%%" % [abs(new_percentage-prev_percentage) * 100.0])
		percentage_delta_label.pop()
		percentage_delta_label.add_text(")")
		percentage_delta_label.pop()
