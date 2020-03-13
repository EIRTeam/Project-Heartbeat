tool
extends Panel
class_name HBLeaderboardItem

const style_even = preload("res://styles/ResultRatingStyleEven.tres")
var odd = false
var entry : HBLeadearboardEntry
onready var percentage_label = get_node("MarginContainer/HBoxContainer/ValueLabel3/PercentageLabel")
onready var username_label = get_node("MarginContainer/HBoxContainer/UserName")
onready var user_avatar_texture_rect = get_node("MarginContainer/HBoxContainer/UserAvatar")
onready var rank_label = get_node("MarginContainer/HBoxContainer/Rank")
var show_percentage =  true
var show_avatar = true
func _ready():
	set_values()

func set_values():
	if not odd:
		add_stylebox_override("panel", style_even)
	if show_percentage:
		percentage_label.text = "%s (%.2f" % [HBUtils.thousands_sep(entry.score), entry.percentage*100]
		percentage_label.text += "%)"
	else:
		percentage_label.text = "%s" % [HBUtils.thousands_sep(entry.score)]
	username_label.text = entry.member.member_name
	rank_label.text = str(entry.rank)
	if show_avatar:
		user_avatar_texture_rect.texture = entry.member.avatar
	else:
		user_avatar_texture_rect.hide()
