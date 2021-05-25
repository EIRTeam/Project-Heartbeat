extends Panel

var member: HBServiceMember setget set_member

onready var member_name_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/MemberNameLabel")
onready var avatar_texture_rect = get_node("MarginContainer/HBoxContainer/TextureRect")
onready var rating_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Label2")
onready var score_counter = get_node("MarginContainer/HBoxContainer/VBoxContainer/Label3")
func set_member(val):
	member = val
	member_name_label.text = member.member_name
	avatar_texture_rect.texture = member.avatar

var last_rating setget set_last_rating
var score = 0 setget set_score
func set_last_rating(val):
	last_rating = val
	rating_label.add_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[last_rating]))
	rating_label.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[last_rating])
	rating_label.text = HBJudge.JUDGE_RATINGS.keys()[last_rating]

func set_score(val):
	score = val
	score_counter.score = score
