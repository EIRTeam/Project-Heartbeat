tool
extends HBoxContainer

export (HBJudge.JUDGE_RATINGS) var rating setget set_rating
var total_notes setget set_total_notes
var percentage setget set_percentage

onready var total_label = get_node("HBoxContainer/ValueLabel3/TotalLabel") 
onready var percentage_label = get_node("HBoxContainer/ValueLabel3/PercentageLabel")
func set_total_notes(val):
	total_notes = val
	$ValueLabel3/TotalLabel.text = str(val) + "/"

func set_percentage(val):
	percentage = val
	$ValueLabel3/PercentageLabel.text = "%.2f" % (val*100.0)
	$ValueLabel3/PercentageLabel.text += " %"
func set_rating(val):
	rating = val
	$RatingLabel.add_color_override("font_color", HBJudge.RATING_TO_COLOR[val])
	$RatingLabel.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[val])
	$RatingLabel.text = HBJudge.RATING_TO_TEXT_MAP[val]
	
