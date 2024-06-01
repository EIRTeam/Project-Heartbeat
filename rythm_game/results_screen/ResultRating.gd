@tool
extends PanelContainer

class_name HBResultScreenRating

@export var rating: HBJudge.JUDGE_RATINGS : set = set_rating
var total_notes : set = set_total_notes
var percentage: float : set = set_percentage

@onready var total_label = get_node("MarginContainer/HBoxContainer/ValueLabel3/TotalLabel") 
@onready var rating_rect: TextureRect = get_node("%RatingRect")
@onready var percentage_label = get_node("MarginContainer/HBoxContainer/ValueLabel3/PercentageLabel")

const style_even = preload("res://styles/ResultRatingStyleEven.tres")
const style_odd = preload("res://styles/ResultRatingStyleOdd.tres")
var odd = false

func set_total_notes(val):
	total_notes = val
	total_label.text = str(val)

func _ready():
	if odd:
		add_theme_stylebox_override("panel", style_odd)
	else:
		add_theme_stylebox_override("panel", style_even)
func set_percentage(val):
	percentage = val
	percentage_label.text = " (%.2f %%)" % (val*100.0)
	queue_redraw()
func set_rating(val):
	rating = val
	var k := HBJudge.JUDGE_RATINGS.find_key(val)
	rating_rect.texture = ResourcePackLoader.get_graphic(k.to_lower() + ".png")

const RATING_TO_COLOR = {
	HBJudge.JUDGE_RATINGS.COOL: Color("#ffd022"),
	HBJudge.JUDGE_RATINGS.FINE: Color("#4ebeff"),
	HBJudge.JUDGE_RATINGS.SAFE: Color("#00a13c"),
	HBJudge.JUDGE_RATINGS.SAD: Color("#57a9ff"),
	HBJudge.JUDGE_RATINGS.WORST: Color("#e470ff")
}

func get_rating_color() -> Color:
	return RATING_TO_COLOR[rating]

func _draw() -> void:
	var col := get_rating_color()
	col.a = 0.5
	draw_rect(Rect2(Vector2.ZERO, size * Vector2(percentage, 1.0)), col, true)
