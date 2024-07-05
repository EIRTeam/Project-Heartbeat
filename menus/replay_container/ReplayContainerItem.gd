extends Control

class_name HBReplayContainerItem

var replay_package: HBReplayPackage

signal pressed

@onready var title_label: Label = get_node("%TitleLabel")
@onready var difficulty_label: Label = get_node("%DifficultyLabel")
@onready var time_label: Label = get_node("%TimeLabel")
@onready var user_label: Label = get_node("%UserLabel")
@onready var score_label: Label = get_node("%ScoreLabel")
@onready var percentage_label: Label = get_node("%PercentageLabel")
@onready var play_button: HBHovereableButton = get_node("%PlayButton")

func _ready() -> void:
	play_button.pressed.connect(self.pressed.emit)
	if replay_package:
		title_label.text = replay_package.replay_info.song_title
		difficulty_label.text = replay_package.replay_info.game_info.difficulty
		var tz_bias := Time.get_time_zone_from_system().bias as int
		var date_time_dict := Time.get_datetime_dict_from_unix_time(replay_package.replay_info.game_info.time + tz_bias * 60)
		time_label.text = "{day}/{month}/{year} {hour}:{minute}".format(date_time_dict)
		time_label.text = HBUtils.humanize_time_elapsed_since(replay_package.replay_info.game_info.time)
		var persona_name := replay_package.replay_info.user_persona_name
		var user_id := replay_package.replay_info.user_id
		user_label.text = persona_name if not persona_name.is_empty() else user_id
		score_label.text = HBUtils.thousands_sep(replay_package.replay_info.game_info.result.score)
		percentage_label.text = "%.2f%%" % [replay_package.replay_info.game_info.result.get_percentage() * 100.0]
		
func hover():
	play_button.hover()

func stop_hover():
	play_button.stop_hover()
