extends HBRhythmGameUIBase

onready var rating_label: Label = get_node("RatingLabel")
onready var game_layer_node = get_node("GameLayer")
onready var top_ui = get_node("Control/HBoxContainer")
onready var score_counter = get_node("Control/HBoxContainer/HBoxContainer/Label")
onready var author_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongAuthor")
onready var song_name_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongName")
onready var difficulty_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer2/DifficultyLabel")
onready var clear_bar = get_node("Control/ClearBar")
onready var hold_indicator = get_node("UnderNotesUI/Control/HoldIndicator")
onready var progress_indicator = get_node("Control/HBoxContainer/TimeTextureProgress")
onready var circle_margin_container = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer")
onready var circle_text_rect = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/CircleImage")
onready var circle_text_rect_margin_container = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer")
onready var latency_display = get_node("Control/LatencyDisplay/Panel")
onready var latency_display_container = get_node("Control/LatencyDisplay")
onready var slide_hold_score_text = get_node("AboveNotesUI/Control/SlideHoldScoreText")
onready var modifiers_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer2/ModifierLabel")
onready var multi_hint = get_node("UnderNotesUI/Control/MultiHint")
onready var intro_skip_control = get_node("UnderNotesUI/Control/SkipIntroIndicator")
onready var intro_skip_ff_animation_player = get_node("UnderNotesUI/Control/Label/IntroSkipFastForwardAnimationPlayer")
onready var lyrics_view = get_node("Lyrics/Control/LyricsView")
onready var under_notes_node = get_node("UnderNotesUI")
onready var health_progress = get_node("Control/HBoxContainer/TimeTextureProgress/HealthTextureProgress")
onready var health_progress_green = get_node("Control/HBoxContainer/TimeTextureProgress/HealthTextureProgressGreen")
onready var health_progress_red = get_node("Control/HBoxContainer/TimeTextureProgress/HealthTextureProgressRed")
onready var intro_skip_tween := Tween.new()
onready var health_tween := Tween.new()

onready var game_over_turn_off_node: Control = get_node("CanvasLayer2/GameOverTurnOff")
onready var game_over_turn_off_top: Control = get_node("CanvasLayer2/GameOverTurnOff/GameOverTurnOffTop")
onready var game_over_turn_off_bottom: Control = get_node("CanvasLayer2/GameOverTurnOff/GameOverTurnOffBottom")

onready var game_over_message_node: Control = get_node("CanvasLayer2/GameOverMessage")

var drawing_layer_nodes = {}

const LOG_NAME = "HeartbeatRhythmGameUI"

var start_time = 0.0
var end_time = 0.0

var game setget set_game

signal tv_off_animation_finished

onready var tv_animation_tween := Tween.new()
onready var game_over_message_tween := Tween.new()

func set_game(new_game):
	game = new_game
	slide_hold_score_text._game = game
	game.connect("time_changed", self, "_on_game_time_changed")
	latency_display.set_judge(game.judge)
func get_notes_node() -> Node2D:
	return get_drawing_layer_node("Notes")
	
func get_lyrics_view():
	return lyrics_view
	
func _on_game_time_changed(time: float):
	progress_indicator.value = time * 1000.0
	lyrics_view._on_game_time_changed(int(time*1000.0))
func _ready():
	intro_skip_control.rect_position.x = -100000
	rating_label.hide()
	connect("resized", self, "_on_size_changed")
	call_deferred("_on_size_changed")
	
	add_drawing_layer("Laser")
	add_drawing_layer("Trails")
	add_drawing_layer("StarParticles")
	add_drawing_layer("HitParticles")
	add_drawing_layer("AppearParticles")
	add_drawing_layer("SlideChainPieces")
	add_drawing_layer("Notes")
	latency_display_container.visible = UserSettings.user_settings.show_latency
	
	add_child(intro_skip_tween)
	health_progress_red.hide()
	
	add_child(health_tween)
	
	game_over_turn_off_node.hide()
	add_child(tv_animation_tween)
	
	tv_animation_tween.connect("tween_all_completed", self, "emit_signal", ["tv_off_animation_finished"])
	add_child(game_over_message_tween)
	game_over_message_node.hide()

func add_drawing_layer(layer_name: String):
	var layer_node = Node2D.new()
	layer_node.name = "LAYER_" + layer_name
	game_layer_node.add_child(layer_node)
	drawing_layer_nodes[layer_name] = layer_node
	
func get_drawing_layer_node(layer_name: String) -> Node2D:
	return drawing_layer_nodes[layer_name]
	
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
	if rating_label.rect_global_position.y > top_ui.rect_global_position.y + top_ui.rect_size.y:
		rating_label.rect_position.y -= 64
	else:
		rating_label.rect_position.y += 64
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
	if game:
		$UnderNotesUI/Control.set_deferred("rect_size", game.size)
		$AboveNotesUI/Control.set_deferred("rect_size", game.size)
		$Lyrics/Control.set_deferred("rect_size", game.size)
func _on_reset():
	clear_bar.value = 0.0
	clear_bar.potential_score = 0.0
	score_counter.score = 0
	rating_label.hide()
	latency_display.reset()
func _on_chart_set(chart: HBChart):
	clear_bar.max_value = chart.get_max_score()
	_update_clear_bar_value()
func _on_song_set(song: HBSong, difficulty: String, assets = null, modifiers = []):
	progress_indicator.min_value = song.start_time
	if song.end_time > 0:
		progress_indicator.max_value = song.end_time
	else:
		progress_indicator.max_value = game.audio_playback.get_length_msec()
	circle_margin_container.hide()
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
	else:
		if "circle_logo" in assets:
			if assets.circle_logo:
				circle_margin_container.show()
				circle_text_rect.texture = assets.circle_logo
				_on_size_changed()
	song_name_label.text = song.get_visible_title(game.current_variant)
	author_label.visible = !song.hide_artist_name
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
			intro_skip_tween.reset_all()
			intro_skip_tween.interpolate_property(intro_skip_control, "rect_position:x", -intro_skip_control.rect_size.x, 0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			intro_skip_tween.start()
			
		else:
			Log.log(self, "Disabling intro skip")
	lyrics_view.set_phrases(song.lyrics)

func _on_intro_skipped(time):
	intro_skip_tween.reset_all()
	intro_skip_tween.interpolate_property(intro_skip_control, "rect_position:x", 0, -intro_skip_control.rect_size.x, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	intro_skip_tween.start()

	intro_skip_ff_animation_player.play("animate")

func _on_hold_released():
	# When you release a hold it disappears instantly
	_update_clear_bar_value()

func _on_hold_released_early():
	# When you release a hold it disappears instantly
	hold_indicator.disappear()
	_update_clear_bar_value()
func _on_max_hold():
	hold_indicator.show_max_combo(game.MAX_HOLD)

func _on_hold_score_changed(new_score: float):
	hold_indicator.current_score = new_score
	_update_clear_bar_value()
	
func _on_show_slide_hold_score(point: Vector2, score: float, show_max: bool):
	slide_hold_score_text.show_at_point(point, score, show_max)
	
func _on_show_multi_hint(new_closest_multi_notes):
	multi_hint.show_notes(new_closest_multi_notes)
	
func _on_hide_multi_hint():
	multi_hint.hide()
	
func _on_end_intro_skip_period():
	intro_skip_tween.reset_all()
	intro_skip_tween.interpolate_property(intro_skip_control, "rect_position:x", 0, -intro_skip_control.rect_size.x, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	intro_skip_tween.start()

func _update_clear_bar_value():
	if disable_score_processing:
		return
	# HACK HACK HACHKs everyhwere
	var res = game.result.clone()
	var res_potential = game.get_potential_result().clone()
	
	if game.held_notes.size() > 0:
		res.hold_bonus += game.accumulated_hold_score + game.current_hold_score
		res.score += game.accumulated_hold_score + game.current_hold_score
		
		res_potential.hold_bonus += game.accumulated_hold_score + game.current_hold_score
		res_potential.score += game.accumulated_hold_score + game.current_hold_score
	
	clear_bar.value = res.get_capped_score()
	clear_bar.potential_score = res_potential.get_capped_score()

func _on_score_added(score):
	if not disable_score_processing:
		score_counter.score = game.result.score
		_update_clear_bar_value()
	
func _on_hold_started(holds):
	hold_indicator.current_holds = holds
	hold_indicator.appear()

func _input(event):
	if event.is_action_pressed("hide_ui") and event.control and not event.shift and not game.editing:
		_on_toggle_ui()
		get_tree().set_input_as_handled()

func _set_ui_visible(ui_visible):
	$UnderNotesUI/Control.visible = ui_visible
	$AboveNotesUI/Control.visible = ui_visible
	$Control.visible = ui_visible
func _on_toggle_ui():
	$UnderNotesUI/Control.visible = !$UnderNotesUI/Control.visible
	$AboveNotesUI/Control.visible = !$UnderNotesUI/Control.visible
	$Control.visible = !$Control.visible

func is_ui_visible():
	return $Control.visible

func play_game_over():
	game_over_message_node.show()
	ShinobuGodot.fire_and_forget_sound(HBGame.GAME_OVER_SFX, "sfx")
	game_over_message_node.rect_pivot_offset = game_over_message_node.rect_size * 0.5
	game_over_message_node.rect_scale.x = 0.0
	game_over_message_tween.interpolate_property(game_over_message_node, "rect_scale:x", 0.0, 1.0, 0.5, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	game_over_message_tween.start()
	

func set_health(health_value: float, animated := false, old_health := -1):
	if old_health == health_value:
		return
	health_tween.remove_all()
	if not health_progress_red.visible:
		health_progress_red.value = old_health
	health_progress_red.hide()
	health_progress_green.hide()
	if animated:
		if old_health != -1:
			if old_health < health_value:
				health_progress_green.show()
				health_progress_green.value = health_value
				health_tween.interpolate_property(health_progress, "value", health_progress.value, health_value, 0.2, 0, 2, 0.5)
			if health_value < old_health:
				health_progress_red.show()
				health_progress.value = health_value
				health_tween.interpolate_property(health_progress_red, "value", health_progress_red.value, health_value, 0.2, 0, 2, 0.5)
		else:
				health_tween.interpolate_property(health_progress, "value", health_progress.value, health_value, 0.2)
		health_tween.start()
	else:
		health_progress.value = health_value

func play_tv_off_animation():
	game_over_turn_off_top.rect_position.y = -game_over_turn_off_top.rect_size.y / 2.0
	game_over_turn_off_bottom.rect_position.y = game_over_turn_off_bottom.rect_size.y / 2.0
	game_over_turn_off_node.show()
	tv_animation_tween.interpolate_property(game_over_turn_off_top, "rect_position:y", game_over_turn_off_top.rect_position.y, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tv_animation_tween.interpolate_property(game_over_turn_off_bottom, "rect_position:y", game_over_turn_off_bottom.rect_position.y, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tv_animation_tween.start()
