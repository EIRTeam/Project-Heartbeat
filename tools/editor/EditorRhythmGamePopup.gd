extends Control

const LOG_NAME = "EditorRhythmGamePopup"

@onready var rhythm_game = HBRhythmGame.new()
@onready var quit_button = get_node("HBoxContainer/QuitButton")
@onready var restart_button = get_node("HBoxContainer/RestartButton")
@onready var rhythm_game_ui = get_node("RhythmGame")
@onready var stats_label = get_node("ExtraUI/HBoxContainer/StatsLabel")
@onready var video_player = get_node("%VideoStreamPlayer")
@onready var video_player_panel = get_node("%VideoPlayerPanel")
@onready var background_texture = get_node("%BackgroundTextureRect")
@onready var visualizer = get_node("%Visualizer")
@onready var autoplay_checkbox: CheckBox = get_node("%AutoplayCheckbox")
signal quit

var playback_speed := 1.0
var pitch_shift_effect: ShinobuPitchShiftEffect = Shinobu.instantiate_pitch_shift()

var _last_time = 0.0

var stats_latency_sum = 0
var stats_passed_notes = 0
var stats_total_notes = 0
var stats_diffs = []
var last_notes = []

var selected_variant := -1

func _init():
	name = "EditorRhythmGamePopup"

func play_song_from_position(song: HBSong, chart: HBChart, difficulty: String, time: float, enable_bg: bool, enable_video: bool):
	var volume = db_to_linear(SongDataCache.get_song_volume_offset(song) * song.volume)
	rhythm_game.audio_playback.volume = volume
	if rhythm_game.voice_audio_playback:
		rhythm_game.voice_audio_playback.volume = volume
	
	rhythm_game.timing_changes = song.timing_changes
	rhythm_game.set_chart(chart)
	
	rhythm_game.seek(time * 1000.0)
	
	rhythm_game.set_process_input(true)
	rhythm_game.seek_new(time * 1000.0, true)
	rhythm_game.game_input_manager.set_process_input(true)
	set_process_unhandled_input(true)
	
	reset_stats()
	_last_time = time
	
	# Set metadata
	get_tree().call_group(HBRhythmGameUI.DIFFICULTY_LABEL_GROUP, "set_difficulty", difficulty)
	get_tree().call_group(HBRhythmGameUI.SONG_TITLE_GROUP, "set_song", song, [], selected_variant)
	get_tree().call_group(HBRhythmGameUI.DIFFICULTY_LABEL_GROUP, "set_modifiers_name_list", ["Test Play"])
	
	get_tree().call_group(HBRhythmGameUI.SKIP_INTRO_INDICATOR_GROUP, "hide")
	
	# Calculate intro skip
	if song.allows_intro_skip and not rhythm_game.disable_intro_skip:
		if rhythm_game.earliest_note_time / 1000.0 > song.intro_skip_min_time:
			get_tree().call_group(HBRhythmGameUI.SKIP_INTRO_INDICATOR_GROUP, "appear")
		else:
			Log.log(self, "Disabling intro skip")
	
	# Set lyrics
	rhythm_game_ui.lyrics_view.set_phrases(song.lyrics)
	
	# Load bg
	background_texture.visible = enable_bg
	var bg_path = song.get_song_background_image_res_path()
	var image = HBUtils.image_from_fs(bg_path)
	
	var image_texture = ImageTexture.create_from_image(image) #,HBGame.platform_settings.texture_mode
	background_texture.texture = image_texture
	
	# Load video
	video_player_panel.hide()
	video_player.hide()
	
	if enable_video and song.has_video_enabled():
		var stream = song.get_video_stream(selected_variant)
		if stream:
			video_player_panel.show()
			video_player.show()
			background_texture.hide()
			
			video_player.stream = stream
			
			video_player.stream_position = time
			video_player.offset = -song.get_video_offset(selected_variant) / 1000.0
			
			if visualizer and UserSettings.user_settings.visualizer_enabled:
				visualizer.visible = UserSettings.user_settings.use_visualizer_with_video
			
			video_player.play()
		else:
			Log.log(self, "Video Stream failed to load")
	
	rhythm_game.start()
	
	show()
	set_game_size()

func set_audio(song: HBSong, audio: ShinobuSoundSource, voice: ShinobuSoundSource, variant := -1):
	if rhythm_game.audio_playback:
		rhythm_game.audio_playback.queue_free()
	
	if rhythm_game.voice_audio_playback:
		rhythm_game.voice_audio_playback.queue_free()
		rhythm_game.voice_audio_playback = null
	
	rhythm_game.audio_playback = ShinobuGodotSoundPlaybackOffset.new(audio.instantiate(HBGame.music_group))
	rhythm_game.audio_playback.offset = song.get_variant_data(variant).variant_offset
	add_child(rhythm_game.audio_playback)
	
	if voice:
		rhythm_game.voice_audio_playback = ShinobuGodotSoundPlaybackOffset.new(voice.instantiate(HBGame.music_group))
		rhythm_game.voice_audio_playback.offset = song.get_variant_data(variant).variant_offset
		add_child(rhythm_game.voice_audio_playback)
	
	selected_variant = variant

func _ready():
	quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	restart_button.connect("pressed", Callable(self, "_on_restart_button_pressed"))
	rhythm_game.connect("note_judged", Callable(self, "_on_note_judged"))
	
	connect("resized", Callable(self, "set_game_size"))
	
	add_child(rhythm_game)
	
	rhythm_game.set_game_ui(rhythm_game_ui)
	rhythm_game.set_game_input_manager(HeartbeatInputManager.new())
	
	rhythm_game_ui.hide_intro_skip()
	rhythm_game.health_system_enabled = false
	
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.set_process_input(false)
	set_process_unhandled_input(false)
	autoplay_checkbox.connect("toggled", Callable(self, "_on_autoplay_toggled"))

func _on_autoplay_toggled(autoplay: bool):
	rhythm_game.game_mode = HBRhythmGame.GAME_MODE.AUTOPLAY if autoplay else HBRhythmGame.GAME_MODE.NORMAL

func _unhandled_input(event):
	if event.is_action_pressed("contextual_option"):
		_on_restart_button_pressed()
	
func _on_restart_button_pressed():
	rhythm_game.seek_new(_last_time * 1000.0, true)
	rhythm_game.start()
	
	video_player.set_stream_position(_last_time)
	
	call_deferred("reset_stats")

func _on_quit_button_pressed():
	rhythm_game.set_process_input(false)
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.pause_game()
	
	set_process_unhandled_input(false)
	
	hide()
	emit_signal("quit")

func set_game_size():
	rhythm_game.size = size
	
	if is_instance_valid(visualizer):
		visualizer.size = size
	
	background_texture.size = size
	
	video_player_panel.size = size
	rescale_video_player()

func rescale_video_player():
	var video_texture = video_player.get_video_texture()
	
	if video_texture:
		var video_size = video_texture.get_size()
		var video_ar = video_size.x / video_size.y
		
		var new_size_x = size.y * video_ar
		if new_size_x <= size.x:
			# side black bars (or none)
			video_player.size = Vector2(new_size_x, size.y)
		else:
			# bottom and top black bars
			video_player.size = Vector2(size.x, size.x / video_ar)
		
		# Center that shit
		video_player.position.x = (size.x - video_player.size.x) / 2.0
		video_player.position.y = (size.y - video_player.size.y) / 2.0

func reset_stats():
	stats_latency_sum = 0
	stats_passed_notes = 0
	stats_total_notes = 0
	stats_diffs = []
	last_notes = []
	update_stats_label()


func update_stats_label():
	var passed_percentage = 0.0
	var avg_latency = 0.0
	
	for i in range(last_notes.size()-1, -1, -1):
		var n_time = last_notes[i]
		if n_time < (rhythm_game.time_msec) - 1000:
			last_notes.remove_at(i)
	
	if stats_total_notes > 0 :
		passed_percentage = stats_passed_notes / float(stats_total_notes) * 100.0
	
	avg_latency = 0.0
	if stats_passed_notes:
		avg_latency = stats_latency_sum / float(stats_passed_notes)
	
	var section = rhythm_game.get_section_at_time(rhythm_game.time_msec)
	var current_speed = rhythm_game.get_note_speed_at_time(rhythm_game.time_msec)
	var current_bpm = 0.0
	var current_time_sig = "4/4"
	for timing_change in rhythm_game.timing_changes:
		if timing_change.time > rhythm_game.time_msec:
			break
		
		current_bpm = timing_change.bpm
		current_time_sig = "%d/%d" % [timing_change.time_signature.numerator, timing_change.time_signature.denominator]
	
	stats_label.text = "Game info:\n"
	stats_label.text += ('"%s"\n' % section.name) if section else ""
	stats_label.text += "BPM: %.*f\n" % [0 if round(current_bpm) == current_bpm else 2, current_bpm]
	stats_label.text += "Time sig: %s\n" % current_time_sig
	stats_label.text += "Note speed: %.*fBPM\n" % [0 if round(current_speed) == current_speed else 2, current_speed]
	stats_label.text += "NPS: %d\n" % last_notes.size()
	
	stats_label.text += "\nAccuracy:\n"
	stats_label.text += "Notes hit: %d/%d (%.2f %%)\n" % [stats_passed_notes, stats_total_notes, passed_percentage]
	stats_label.text += "Avg. latency: %.0f ms\n" % avg_latency


func _on_note_judged(judgement_info):
	var judgement = judgement_info.judgement
	var target_time = judgement_info.target_time
	stats_total_notes += 1
	last_notes.append(target_time)
	if judgement >= HBJudge.JUDGE_RATINGS.FINE and not judgement_info.wrong:
		stats_passed_notes += 1
		stats_latency_sum += judgement_info.time-judgement_info.target_time
	update_stats_label()

func set_velocity(value: float, correction: bool):
	playback_speed = value
	
	rhythm_game.audio_playback.set_pitch_scale(playback_speed)
	if rhythm_game.voice_audio_playback:
		rhythm_game.voice_audio_playback.set_pitch_scale(playback_speed)
	
	if correction:
		pitch_shift_effect.pitch_scale = 1.0 / playback_speed
	else:
		pitch_shift_effect.pitch_scale = 1.0
	
	if not is_equal_approx(pitch_shift_effect.pitch_scale, 1.0):
		add_pitch_effect()
	else:
		remove_pitch_effect()
	
func add_pitch_effect():
	HBGame.spectrum_analyzer.connect_to_effect(pitch_shift_effect)
	pitch_shift_effect.connect_to_endpoint()
func remove_pitch_effect():
	HBGame.spectrum_analyzer.connect_to_endpoint()
