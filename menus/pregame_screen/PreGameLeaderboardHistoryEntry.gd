extends PanelContainer

class_name HBPregameLeaderboardHistoryEntry

@onready var diff_label: Label = get_node("%DiffLabel")
@onready var score_label: Label = get_node("%ScoreLabel")
@onready var rating_rect: TextureRect = get_node("%RatingRect")
@onready var open_score_in_browser_button: Button = get_node("%OpenScoreInBrowserButton")
@onready var buttons_container: HBSimpleMenu = get_node("%ButtonContainer")

@export var diff: int = 0:
	set(val):
		diff = val
		if not is_inside_tree():
			return
		if diff > 0:
			diff_label.text = "+" + str(diff)
		else:
			diff_label.text = ""

var score_id: int

var game_info: HBGameInfo:
	set(val):
		game_info = val
		if not is_inside_tree() or not game_info:
			return
		score_label.text = HBUtils.thousands_sep(game_info.result.score)
		rating_rect.texture = HBUtils.get_clear_badge(game_info.result.get_result_rating())

func _ready() -> void:
	diff = diff
	game_info = game_info
	open_score_in_browser_button.pressed.connect(self._open_score_in_browser)
	focus_mode = FOCUS_ALL
	focus_entered.connect(buttons_container._on_focus_entered)
	focus_exited.connect(buttons_container._on_focus_exited)
	
func _gui_input(event):
	buttons_container._gui_input(event)

func _open_score_in_browser():
	OS.shell_open("https://ph.eirteam.moe/score/%d" % [score_id])

func _update_style():
	add_theme_stylebox_override("panel", preload("res://styles/ResultRatingStyleEven.tres") if get_index() % 2 == 0 else preload("res://styles/ResultRatingStyleOdd.tres"))

func set_left(ctrl: NodePath):
	buttons_container.focus_neighbor_left = ctrl

func set_next(ctrl: NodePath):
	buttons_container.focus_neighbor_bottom = ctrl
	
func set_prev(ctrl: NodePath):
	buttons_container.focus_neighbor_top = ctrl

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_update_style()
			get_parent().child_order_changed.connect(self._update_style)
		NOTIFICATION_UNPARENTED:
			get_parent().child_order_changed.disconnect(self._update_style)
		
