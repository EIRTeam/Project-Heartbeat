extends PanelContainer

class_name HBPregameLeaderboardHistoryEntry

@onready var diff_label: Label = get_node("%DiffLabel")
@onready var score_label: Label = get_node("%ScoreLabel")
@onready var rating_rect: TextureRect = get_node("%RatingRect")

@export var diff: int = 0:
	set(val):
		diff = val
		if not is_inside_tree():
			return
		if diff > 0:
			diff_label.text = "+" + str(diff)
		else:
			diff_label.text = ""

var game_info: HBGameInfo:
	set(val):
		game_info = val
		if not is_inside_tree():
			return
		score_label.text = HBUtils.thousands_sep(game_info.result.score)
		rating_rect.texture = HBUtils.get_clear_badge(game_info.result.get_result_rating())

func _ready() -> void:
	diff = diff
	game_info = game_info
	
func _update_style():
	add_theme_stylebox_override("panel", preload("res://styles/ResultRatingStyleEven.tres") if get_index() % 2 == 0 else preload("res://styles/ResultRatingStyleOdd.tres"))

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_update_style()
			get_parent().child_order_changed.connect(self._update_style)
		NOTIFICATION_UNPARENTED:
			get_parent().child_order_changed.disconnect(self._update_style)
		
