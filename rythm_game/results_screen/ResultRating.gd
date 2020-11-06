tool
extends Panel

export (HBJudge.JUDGE_RATINGS) var rating setget set_rating
var total_notes setget set_total_notes
var percentage setget set_percentage

onready var total_label = get_node("MarginContainer/HBoxContainer/ValueLabel3/TotalLabel") 
onready var rating_label = get_node("MarginContainer/HBoxContainer/RatingLabel")
onready var percentage_label = get_node("MarginContainer/HBoxContainer/ValueLabel3/PercentageLabel")

const style_even = preload("res://styles/ResultRatingStyleEven.tres")
var odd = false

func set_total_notes(val):
	total_notes = val
	total_label.text = str(val)

func _ready():
	if not odd:
		add_stylebox_override("panel", style_even)
func set_percentage(val):
	percentage = val
	percentage_label.text = " (%.2f %%)" % (val*100.0)
func set_rating(val):
	rating = val
	rating_label.add_color_override("font_color", HBJudge.RATING_TO_COLOR[val])
	rating_label.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[val])
	rating_label.text = HBJudge.RATING_TO_TEXT_MAP[val]
	
