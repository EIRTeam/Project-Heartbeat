extends HBRhythmGameUIBase

class_name HBRhythmGameUI

@onready var rating_label: Label = get_node("RatingLabel")
@onready var wrong_rating_cross: TextureRect = get_node("RatingLabel/WrongRatingCross")
@onready var game_layer_node = get_node("%GameLayer")
@onready var slide_hold_score_text = get_node("AboveNotesUI/Control/SlideHoldScoreText")
@onready var intro_skip_ff_animation_player = get_node("UnderNotesUI/Control/Label/IntroSkipFastForwardAnimationPlayer")
@onready var lyrics_view = get_node("Lyrics/Control/LyricsView")
@onready var under_notes_node = get_node("UnderNotesUI")
@onready var aspect_ratio_container: AspectRatioContainer = get_node("AspectRatioContainer")

@onready var game_over_turn_off_node: Control = get_node("CanvasLayer2/GameOverTurnOff")
@onready var game_over_turn_off_top: Control = get_node("CanvasLayer2/GameOverTurnOff/GameOverTurnOffTop")
@onready var game_over_turn_off_bottom: Control = get_node("CanvasLayer2/GameOverTurnOff/GameOverTurnOffBottom")

@onready var game_over_message_node: Control = get_node("CanvasLayer2/GameOverMessage")
@onready var under_notes_user_ui_node = get_node("UnderNotesUI/Control/UserUI")
@onready var over_notes_user_ui_node = get_node("UserUI")

const SCORE_COUNTER_GROUP = "score_counter"
const CLEAR_BAR_GROUP = "clear_bar"
const LATENCY_DISPLAY_GROUP = "accuracy_display"
const DIFFICULTY_LABEL_GROUP = "song_difficulty"
const HOLD_INDICATOR_GROUP = "hold_indicator"
const SONG_PROGRESS_INDICATOR_GROUP = "song_progress"
const SONG_TITLE_GROUP = "song_title"
const MULTI_HINT_GROUP = "multi_hint"
const HEALTH_DISPLAY_GROUP = "health_display"

const SKIP_INTRO_INDICATOR_GROUP = "skip_intro_indicator"

var drawing_layer_nodes = {}

const LOG_NAME = "HeartbeatRhythmGameUI"

var start_time = 0.0
var end_time = 0.0

var game : set = set_game

#warning-ignore:unused_signal
signal tv_off_animation_finished

@onready var tv_animation_tween := Threen.new()
@onready var game_over_message_tween := Threen.new()

var skin_override: HBUISkin

func set_game(new_game):
	game = new_game
	slide_hold_score_text._game = game
	game.connect("time_changed", Callable(self, "_on_game_time_changed"))
	get_tree().call_group(LATENCY_DISPLAY_GROUP, "set_judge", game.judge)
func get_notes_node() -> Node2D:
	return get_drawing_layer_node("Notes")
	
func get_lyrics_view():
	return lyrics_view
	
func _on_game_time_changed(time: float):
	get_tree().set_group(SONG_PROGRESS_INDICATOR_GROUP, "value", time * 1000.0)
	lyrics_view._on_game_time_changed(int(time*1000.0))

func create_components():
	var skin := ResourcePackLoader.current_skin as HBUISkin
	if skin_override:
		if skin_override.has_screen("gameplay"):
			skin = skin_override
	if not skin.has_screen("gameplay"):
		skin = ResourcePackLoader.fallback_skin
	var cache := skin.resources.get_cache() as HBSkinResourcesCache
	var layered_components := skin.get_components("gameplay", cache)
	for node in layered_components.get("UnderNotes", []):
		under_notes_user_ui_node.add_child(node)
	for node in layered_components.get("OverNotes"):
		over_notes_user_ui_node.add_child(node)
	
func _ready():
	create_components()
	get_tree().set_group(SKIP_INTRO_INDICATOR_GROUP, "position:x", -100000)
	rating_label.hide()
	connect("resized", Callable(self, "_on_size_changed"))
	call_deferred("_on_size_changed")
	
	add_drawing_layer("Laser")
	add_drawing_layer("Trails")
	add_drawing_layer("StarParticles")
	add_drawing_layer("HitParticles")
	add_drawing_layer("AppearParticles")
	add_drawing_layer("SlideChainPieces")
	add_drawing_layer("Notes")
	
	game_over_turn_off_node.hide()
	add_child(tv_animation_tween)
	
	tv_animation_tween.connect("tween_all_completed", Callable(self, "emit_signal").bind("tv_off_animation_finished"))
	tv_animation_tween.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_over_message_tween)
	game_over_message_tween.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_message_node.hide()

	get_tree().set_group(LATENCY_DISPLAY_GROUP, "visible", UserSettings.user_settings.show_latency)
	_on_hide_multi_hint()
func add_drawing_layer(layer_name: String):
	var layer_node = Node2D.new()
	layer_node.name = "LAYER_" + layer_name
	game_layer_node.add_child(layer_node)
	drawing_layer_nodes[layer_name] = layer_node
	
func get_drawing_layer_node(layer_name: String) -> Node2D:
	return drawing_layer_nodes[layer_name]
	
func _on_note_judged(judgement_info):
	get_tree().call_group(LATENCY_DISPLAY_GROUP, "_on_note_judged", judgement_info)
	
	if not is_ui_visible():
		return
	
	rating_label.show_rating()
	rating_label.get_node("AnimationPlayer").play("rating_appear")
	if not judgement_info.wrong:
		rating_label.add_theme_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[judgement_info.judgement]))
		rating_label.add_theme_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[judgement_info.judgement])
		rating_label.text = HBJudge.JUDGE_RATINGS.keys()[judgement_info.judgement]
	else:
		rating_label.add_theme_color_override("font_color", Color(game.WRONG_COLOR))
		rating_label.add_theme_color_override("font_outline_modulate", game.WRONG_COLOR)
		rating_label.text = HBJudge.RATING_TO_WRONG_TEXT_MAP[judgement_info.judgement]
	if game.current_combo > 1:
		rating_label.text += " " + str(game.current_combo)
	rating_label.position = game.remap_coords(judgement_info.avg_pos) - rating_label.size / 2
	if rating_label.global_position.y > ResourcePackLoader.current_skin.rating_label_top_margin:
		rating_label.position.y -= 64
	else:
		rating_label.position.y += 64
	rating_label.update_minimum_size()
	wrong_rating_cross.position = Vector2.ZERO
	if judgement_info.wrong:
		wrong_rating_cross.show()
		var min_size_x := rating_label.get_minimum_size().x
		wrong_rating_cross.position = rating_label.size * 0.5 - Vector2(0, wrong_rating_cross.size.y) * 0.5
		wrong_rating_cross.position.x += min_size_x * 0.5
		# Add some separation...
		wrong_rating_cross.position.x += 5
	else:
		wrong_rating_cross.hide()
	if not game.previewing:
		rating_label.show()
	else:
		rating_label.hide()
func _on_size_changed():
	if game:
		$UnderNotesUI/Control.set_deferred("size", game.size)
		$AboveNotesUI/Control.set_deferred("size", game.size)
		$Lyrics/Control.set_deferred("size", game.size)
		
func _on_reset():
	reset_score_counter()
	get_tree().set_group(CLEAR_BAR_GROUP, "value", 0.0)
	get_tree().set_group(CLEAR_BAR_GROUP, "potential_score", 0.0)
	get_tree().call_group(LATENCY_DISPLAY_GROUP, "reset")
	get_tree().call_group(HOLD_INDICATOR_GROUP, "disappear")
	_show_intro_skip(game.current_song)
	
	rating_label.hide()
	
func reset_score_counter():
	get_tree().set_group(SCORE_COUNTER_GROUP, "score", 0.0)
	
func _on_chart_set(chart: HBChart):
	get_tree().set_group(CLEAR_BAR_GROUP, "max_value", chart.get_max_score())
	_update_clear_bar_value()
	
func _show_intro_skip(song: HBSong):
	if song.allows_intro_skip and not game.disable_intro_skip:
		if game.earliest_note_time / 1000.0 > song.intro_skip_min_time:
			get_tree().call_group(SKIP_INTRO_INDICATOR_GROUP, "appear")
	
func _on_song_set(song: HBSong, difficulty: String, assets = null, modifiers = []):
	get_tree().set_group(SONG_PROGRESS_INDICATOR_GROUP, "min_value", song.start_time)
	get_tree().call_group(HOLD_INDICATOR_GROUP, "disappear")
		
	if song.end_time > 0:
		get_tree().set_group(SONG_PROGRESS_INDICATOR_GROUP, "max_value", song.end_time)
	else:
		get_tree().set_group(SONG_PROGRESS_INDICATOR_GROUP, "max_value", game.audio_playback.get_length_msec())

	get_tree().call_group(DIFFICULTY_LABEL_GROUP, "set_difficulty", difficulty)
	
	get_tree().call_group(SONG_TITLE_GROUP, "set_song", song, assets, game.current_variant)
		
	var modifiers_string = PackedStringArray()

	for modifier in modifiers:
		var modifier_instance = modifier
		modifier_instance._init_plugin()
		modifier_instance._pre_game(song, game)
		modifiers_string.append(modifier_instance.get_modifier_list_name())
	get_tree().call_group(DIFFICULTY_LABEL_GROUP, "set_modifiers_name_list", modifiers_string)
	get_tree().call_group(SKIP_INTRO_INDICATOR_GROUP, "hide")
	_show_intro_skip(song)
	lyrics_view.set_phrases(song.lyrics)

func _on_intro_skipped(time):
	get_tree().call_group(SKIP_INTRO_INDICATOR_GROUP, "disappear")

	intro_skip_ff_animation_player.play("animate")

func hide_intro_skip():
	get_tree().call_group(SKIP_INTRO_INDICATOR_GROUP, "hide")

func _on_hold_released():
	# When you release a hold it disappears instantly
	_update_clear_bar_value()

func _on_hold_released_early():
	# When you release a hold it disappears instantly
	get_tree().call_group(HOLD_INDICATOR_GROUP, "disappear")
	_update_clear_bar_value()
func _on_max_hold():
	get_tree().call_group(HOLD_INDICATOR_GROUP, "show_max_combo", game.MAX_HOLD)

func _on_hold_score_changed(new_score: float):
	get_tree().set_group(HOLD_INDICATOR_GROUP, "current_score", new_score)
	_update_clear_bar_value()
	
func _on_show_slide_hold_score(point: Vector2, score: float, show_max: bool):
	slide_hold_score_text.show_at_point(point, score, show_max)
	
func _on_show_multi_hint(new_closest_multi_notes):
	get_tree().call_group(MULTI_HINT_GROUP, "show_notes", new_closest_multi_notes)
	
func _on_hide_multi_hint():
	get_tree().call_group(MULTI_HINT_GROUP, "hide")
	
func _on_end_intro_skip_period():
	get_tree().call_group(SKIP_INTRO_INDICATOR_GROUP, "disappear")


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
	
	get_tree().set_group(CLEAR_BAR_GROUP, "value", res.get_capped_score())
	get_tree().set_group(CLEAR_BAR_GROUP, "potential_score", res_potential.get_capped_score())

func _on_score_added(score):
	if not disable_score_processing:
		get_tree().set_group(SCORE_COUNTER_GROUP, "score", game.result.score)
		_update_clear_bar_value()
	
func _on_hold_started(holds):
	get_tree().set_group(HOLD_INDICATOR_GROUP, "current_holds", holds)
	get_tree().call_group(HOLD_INDICATOR_GROUP, "appear")

func _input(event):
	if event.is_action_pressed("hide_ui") and event.is_command_or_control_pressed() and not event.shift_pressed and not game.editing:
		_on_toggle_ui()
		get_viewport().set_input_as_handled()

func _set_ui_visible(ui_visible):
	$UnderNotesUI/Control.visible = ui_visible
	$AboveNotesUI/Control.visible = ui_visible
	$UserUI.visible = ui_visible
func _on_toggle_ui():
	$UnderNotesUI/Control.visible = !$UnderNotesUI/Control.visible
	$AboveNotesUI/Control.visible = !$UnderNotesUI/Control.visible
	$UserUI.visible = !$UserUI.visible

func is_ui_visible():
	return $UserUI.visible

func play_game_over():
	game_over_message_node.show()
	HBGame.fire_and_forget_sound(HBGame.game_over_sfx, HBGame.sfx_group)
	game_over_message_node.pivot_offset = game_over_message_node.size * 0.5
	game_over_message_node.scale.x = 0.0
	game_over_message_tween.interpolate_property(game_over_message_node, "scale:x", 0.0, 1.0, 0.5, Threen.TRANS_BOUNCE, Threen.EASE_IN)
	game_over_message_tween.start()
	

func set_health(health_value: float, animated := false, old_health := -1):
	get_tree().call_group(HEALTH_DISPLAY_GROUP, "set_health", health_value, animated, old_health)

func play_tv_off_animation():
	game_over_turn_off_top.position.y = -game_over_turn_off_top.size.y / 2.0
	game_over_turn_off_bottom.position.y = game_over_turn_off_bottom.size.y / 2.0
	game_over_turn_off_node.show()
	tv_animation_tween.interpolate_property(game_over_turn_off_top, "position:y", game_over_turn_off_top.position.y, 0, 0.3, Threen.TRANS_LINEAR, Threen.EASE_IN)
	tv_animation_tween.interpolate_property(game_over_turn_off_bottom, "position:y", game_over_turn_off_bottom.position.y, 0, 0.3, Threen.TRANS_LINEAR, Threen.EASE_IN)
	tv_animation_tween.start()
