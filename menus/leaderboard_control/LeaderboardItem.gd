@tool
extends Panel
class_name HBLeaderboardItemNew

const style_even = preload("res://styles/ResultRatingStyleOdd.tres")
var odd = false
var entry : HBLeadearboardEntry
@onready var percentage_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/ValueLabel3/PercentageLabel")
@onready var username_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/UserName")
@onready var user_avatar_texture_rect = get_node("MarginContainer/HBoxContainer/UserAvatar")
@onready var rank_label = get_node("MarginContainer/HBoxContainer/Rank")

var items = []
var starting_position = 1

func _ready():
	set_values()

func set_values():
	if not odd:
		add_theme_stylebox_override("panel", style_even)
	percentage_label.text = "%s (%.2f" % [HBUtils.thousands_sep(entry.score), entry.percentage*100]
	percentage_label.text += "%)"
	username_label.text = entry.member.member_name
	rank_label.text = str(entry.rank)
	user_avatar_texture_rect.texture = entry.member.avatar
	if not entry.member.is_connected("persona_state_change", Callable(self, "_persona_state_change")):
		entry.member.connect("persona_state_change", Callable(self, "_persona_state_change"))
	
func _persona_state_change(flags):
	set_values()
