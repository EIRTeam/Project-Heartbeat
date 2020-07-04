extends HBRhythmGameUIBase

onready var rating_label: Label = get_node("RatingLabel")
onready var notes_node = get_node("Notes")
onready var score_counter = get_node("Control/HBoxContainer/HBoxContainer/Label")
onready var author_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongAuthor")
onready var song_name_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongName")
onready var difficulty_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer2/DifficultyLabel")
onready var clear_bar = get_node("Control/ClearBar")
onready var hold_indicator = get_node("UnderNotesUI/Control/HoldIndicator")
onready var heart_power_indicator = get_node("Control/HBoxContainer/HeartPowerTextureProgress")
onready var circle_margin_container = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer")
onready var circle_text_rect = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/CircleImage")
onready var circle_text_rect_margin_container = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer")
onready var latency_display = get_node("Control/LatencyDisplay")
onready var slide_hold_score_text = get_node("AboveNotesUI/Control/SlideHoldScoreText")
onready var modifiers_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer2/ModifierLabel")
onready var multi_hint = get_node("UnderNotesUI/Control/MultiHint")
onready var intro_skip_info_animation_player = get_node("UnderNotesUI/Control/SkipContainer/AnimationPlayer")
onready var intro_skip_ff_animation_player = get_node("UnderNotesUI/Control/Label/IntroSkipFastForwardAnimationPlayer")

const LOG_NAME = "HeartbeatRhythmGameUI"

var game setget set_game

func set_game(new_game):
	game = new_game
	slide_hold_score_text._game = game

func _ready():
	rating_label.hide()
	$UnderNotesUI/Control/SkipContainer/Panel/HBoxContainer/TextureRect.texture = IconPackLoader.get_graphic("LEFT", "note")
	$UnderNotesUI/Control/SkipContainer/Panel/HBoxContainer/TextureRect2.texture = IconPackLoader.get_graphic("UP", "note")
	connect("resized", self, "_on_size_changed")
	call_deferred("_on_size_changed")
func _on_note_judged(judgement_info):
	latency_display._on_note_judged(judgement_info)
	rating_label.show_rating()
	rating_label.get_node("AnimationPlayer").play("rating_appear")
	if not judgement_info.wrong:
		rating_label.add_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[judgement_info.judgement]))
		rating_label.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[judgement_info.judgement])
		rating_label.text = HBJudge.JUDGE_RATINGS.keys()[judgement_info.judgement]
	else:
		rating_label.add_color_override("font_color", Color(game.WRONG_COLOR))
		rating_label.add_color_override("font_outline_modulate", game.WRONG_COLOR)
		rating_label.text = HBJudge.RATING_TO_WRONG_TEXT_MAP[judgement_info.judgement]
	if game.current_combo > 1:
		rating_label.text += " " + str(game.current_combo)
	rating_label.rect_position = game.remap_coords(judgement_info.avg_pos) - rating_label.rect_size / 2
	rating_label.rect_position.y -= 64
	if not game.previewing:
		rating_label.show()
	else:
		rating_label.hide()
func _on_size_changed():
	var hbox_container2 = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer")
	if circle_text_rect.texture:
		var image = circle_text_rect.texture.get_data() as Image
		var ratio = image.get_width() / image.get_height()
		var new_size = Vector2(hbox_container2.rect_size.y * ratio, hbox_container2.rect_size.y)
		new_size.x = clamp(new_size.x, 0, 250)
		circle_text_rect_margin_container.rect_min_size = new_size
	$Viewport.size = self.rect_size
	if game:
		$UnderNotesUI/Control.rect_size = game.size
		$AboveNotesUI/Control.rect_size = game.size
func _on_reset():
	clear_bar.value = 0.0
	score_counter.score = 0
	rating_label.hide()
func _on_chart_set(chart: HBChart):
	clear_bar.max_value = chart.get_max_score()
func _on_song_set(song: HBSong, difficulty: String, assets = null, modifiers = []):
	if not assets:
		var circle_logo_path = song.get_song_circle_logo_image_res_path()
		if circle_logo_path:
			circle_text_rect.show()
			var image = HBUtils.image_from_fs(circle_logo_path)
			var it = ImageTexture.new()
			it.create_from_image(image, Texture.FLAGS_DEFAULT)
			circle_text_rect.texture = it
			_on_size_changed()
		else:
			circle_margin_container.hide()
			
	song_name_label.text = song.get_visible_title()
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	difficulty_label.text = "[%s]" % difficulty
		
	var modifiers_string = PoolStringArray()

	for modifier in modifiers:
		var modifier_instance = modifier
		modifier_instance._init_plugin()
		modifier_instance._pre_game(song, game)
		modifiers_string.append(modifier_instance.get_modifier_list_name())
	if modifiers.size() > 0:
		modifiers_label.text = " - " + modifiers_string.join(" + ")
	else:
		modifiers_label.text = ""
	if song.allows_intro_skip and not game.disable_intro_skip:
		if game.earliest_note_time / 1000.0 > song.intro_skip_min_time:
			intro_skip_info_animation_player.play("appear")
		else:
			Log.log(self, "Disabling intro skip")

func _on_intro_skipped(time):
	intro_skip_info_animation_player.play("disappear")
	intro_skip_ff_animation_player.play("animate")

func _on_hold_released():
	# When you release a hold it disappears instantly
	hold_indicator.disappear()

func get_notes_node() -> Node2D:
	return notes_node
	
func _on_max_hold():
	hold_indicator.show_max_combo(game.MAX_HOLD)

func _on_hold_score_changed(new_score: float):
	hold_indicator.current_score = new_score
	
func _on_show_slide_hold_score(point: Vector2, score: float, show_max: bool):
	slide_hold_score_text.show_at_point(point, score, show_max)
	
func _on_show_multi_hint(new_closest_multi_notes):
	multi_hint.show_notes(new_closest_multi_notes)
	
func _on_hide_multi_hint():
	multi_hint.hide()
	
func _on_end_intro_skip_period():
	intro_skip_info_animation_player.play("disappear")

func _on_score_added(score):
	score_counter.score = game.result.score
	clear_bar.value = game.result.get_capped_score()
	
func _on_hold_started(holds):
	hold_indicator.current_holds = holds
	hold_indicator.appear()

func _unhandled_input(event):
	$Viewport.unhandled_input(event)

func _on_toggle_ui():
	$UnderNotesUI/Control.hide()
	$AboveNotesUI/Control.hide()
	$Control.hide()
