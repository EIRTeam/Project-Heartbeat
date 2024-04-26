extends HBPanelContainerBlurEX

class_name HBResultsScreenExperienceInfoDisplay

var info_update_queued := false

@onready var experience_info_container: Control = get_node("%ExperienceInfoContainer")
@onready var experience_gain_label: Label = get_node("%ExperienceGainLabel")
@onready var experience_breakdown_label: Label = get_node("%ExperienceBreakdownLabel")
@onready var to_next_level_label: Label = get_node("%ToNextLevelLabel")

func _queue_info_update():
	if not info_update_queued:
		info_update_queued = true
		_update_info.call_deferred()

var experience_gain_info: HBBackend.LeaderboardScoreUploadedResult.ExperienceGainBreakdown:
	set(val):
		experience_gain_info = val
		_queue_info_update()
var game_result: HBResult:
	set(val):
		game_result = val
		_queue_info_update()

func _update_info():
	info_update_queued = false
	
	if experience_gain_info:
		experience_gain_label.text = tr("Gained {experience_gain}!", &"Results screen experience gain label")
		var rating_text := HBUtils.find_key(HBResult.RESULT_RATING, game_result.get_result_rating()) as String
		experience_breakdown_label.text = rating_text.capitalize() + " " + str(experience_gain_info.rating_experience_gain) + tr("xp", &"shorthand for experience")
		if experience_gain_info.first_time:
			var first_clear_str := tr("First clear {first_clear_exp}xp", &"Results screen first clear")
			first_clear_str = first_clear_str.format({
					"first_clear_exp": experience_gain_info.first_time_experience_gain
				})
			experience_breakdown_label.text = first_clear_str + "+" + experience_breakdown_label.text
		experience_gain_label.text = tr("Gained {experience_gain}xp!", &"Results screen experience gain label").format({"experience_gain": experience_gain_info.get_total_experience_gain()})
		var total_exp := HBUtils.get_experience_to_next_level(HBBackend.user_info.level)
		var exp_to_next_level: int = total_exp - HBBackend.user_info.experience + experience_gain_info.get_total_experience_gain()
		to_next_level_label.text = tr("Next level: {exp_to_next_level}xp left", &"Results screen experience to next level").format({"exp_to_next_level": exp_to_next_level})
