extends Panel
class_name HBLeaderboardItem

const style_even = preload("res://styles/ResultRatingStyleEven.tres")

var odd = false
var entry : HBBackend.BackendLeaderboardEntry
@onready var percentage_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/PercentageLabel")
@onready var username_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/UserName")
@onready var user_avatar_texture_rect = get_node("MarginContainer/HBoxContainer/UserAvatar")
@onready var rank_label = get_node("MarginContainer/HBoxContainer/Rank")

func _ready():
	set_values()

func set_values():
	if get_index() % 2 != 0:
		add_theme_stylebox_override("panel", style_even)
	percentage_label.text = "%s (%.2f" % [HBUtils.thousands_sep(entry.game_info.result.score), entry.game_info.result.get_percentage()*100]
	percentage_label.text += "%)"
	username_label.text = entry.user.member_name
	rank_label.text = str(entry.rank)
	user_avatar_texture_rect.texture = entry.user.get_avatar()
	if not entry.user.is_connected("persona_state_change", Callable(self, "_persona_state_change")):
		entry.user.persona_state_change.connect(self._persona_state_change)
	
func _persona_state_change():
	set_values()
