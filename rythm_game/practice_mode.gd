extends "res://rythm_game/rhythm_game_controller.gd"

@onready var ingame_stats_label = get_node("PracticeModeUIIngame/HBoxContainer/Label")
@onready var quit_confirmation = get_node("QuitConfirmation")
@onready var song_settings_editor = get_node("SettingsGUI/VBoxContainer/MarginContainer/PerSongSettingsEditor")

@onready var practice_seek_gui = get_node("SeekGUI")
@onready var practice_section_seek_gui = get_node("SectionSeekGUI")
@onready var practice_settings_gui = get_node("SettingsGUI")
@onready var practice_speed_gui = get_node("SpeedControlGUI")

@onready var seek_progress_bar = get_node("SeekGUI/VBoxContainer/VBoxContainer/ProgressBar")
@onready var section_seek_progress_bar = get_node("SectionSeekGUI/VBoxContainer/VBoxContainer/ProgressBar")

@onready var seek_progess_bar_waypoint = get_node("SeekGUI/VBoxContainer/VBoxContainer/ProgressBar/ProgresBarWaypoint")
@onready var section_seek_progess_bar_waypoint = get_node("SectionSeekGUI/VBoxContainer/VBoxContainer/ProgressBar/ProgresBarWaypoint")

@onready var seek_time_label = get_node("SeekGUI/VBoxContainer/VBoxContainer/Label")
@onready var section_seek_time_label = get_node("SectionSeekGUI/VBoxContainer/VBoxContainer/Label")

@onready var section_label = get_node("SectionSeekGUI/VBoxContainer/VBoxContainer/Label2")
@onready var speed_label = get_node("SpeedControlGUI/VBoxContainer/VBoxContainer/Label")


var stats_passed_notes = 0
var stats_total_notes = 0
var stats_diffs = []
var notes_in_second = []
var latency_data = []
var stats_judgements = {
	HBJudge.JUDGE_RATINGS.COOL: 0,
	HBJudge.JUDGE_RATINGS.FINE: 0,
	HBJudge.JUDGE_RATINGS.SAFE: 0,
	HBJudge.JUDGE_RATINGS.SAD: 0,
	HBJudge.JUDGE_RATINGS.WORST: 0
}

var section := 0
var waypoint := 0.0

var playback_speed := 1.0

enum PRACTICE_GUI {
	SEEK,
	SECTION_SEEK,
	OPTIONS,
	SPEED,
}
var practice_gui_mode := 0: set = _set_mode

var pitch_shift_effect := Shinobu.instantiate_pitch_shift()

var pre_pause_game_mode: int = HBRhythmGame.GAME_MODE.NORMAL

func _ready():
	super._ready()
	game.connect("note_judged", Callable(self, "_on_note_judged"))
	quit_confirmation.connect("accept", Callable(Diagnostics.gamepad_visualizer, "hide"))
	quit_confirmation.connect("accept", Callable(self, "_on_PauseMenu_quit"))
	quit_confirmation.connect("accept", Callable(song_settings_editor, "toggle_input"))
	quit_confirmation.connect("cancel", Callable(song_settings_editor, "toggle_input"))
	update_stats_label()
	practice_seek_gui.hide()
	game.disable_ending = true
	game.health_system_enabled = false
	Diagnostics.gamepad_visualizer.show()
	song_settings_editor.connect("back", Callable(self, "pause"))

func set_song(song: HBSong, difficulty: String, modifiers = [], force_caching_off=false, assets=null):
	super.set_song(song, difficulty, modifiers, true, assets)
	fade_in_tween.remove_all()
	_fade_in_done()
	disable_intro_skip = true
	pause_disabled = true
	pause_menu_disabled = true
	disable_restart()
	video_player.play()
	video_player.paused = false
	game._process(0)
	video_player.set_stream_position(game.time_msec / 1000.0)
	practice_seek_gui.hide()
	update_stats_label()
	
	waypoint = 0.0
	section = 0

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		pause()

func pause():
	game.pause_game()
	get_tree().paused = !get_tree().paused
	
	practice_seek_gui.visible = get_tree().paused
	practice_section_seek_gui.visible = get_tree().paused
	practice_settings_gui.visible = get_tree().paused
	practice_speed_gui.visible = get_tree().paused
	
	game.toggle_ui()
	set_process(true)
	update_progress_bar()
	quit_confirmation.hide()
	quit_confirmation.release_focus()
	
	if get_tree().paused:
		pre_pause_game_mode = game.game_mode
		game.game_mode = HBRhythmGame.GAME_MODE.EDITOR_SEEK
		last_pause_time = game.time_msec
		game.editing = true
		video_player.paused = true
		update_time_label()
		update_progress_bar()
		
		_set_mode_impl(practice_gui_mode, true)
	else:
		video_player.paused = false
		game.game_mode = pre_pause_game_mode
		reset_stats()
		game.editing = false
		game.start()
		game.set_process(true)
		game._process(0)
		video_player.paused = false
		video_player.set_stream_position(game.time_msec / 1000.0)


func _process(delta):
	game.result.used_cheats = true
	
	if get_tree().paused and not quit_confirmation.visible:
		if Input.is_action_just_pressed("practice_last_mode"):
			_set_mode(practice_gui_mode - 1)
		if Input.is_action_just_pressed("practice_next_mode"):
			_set_mode(practice_gui_mode + 1)
		
		if Input.is_action_just_pressed("contextual_option"):
			song_settings_editor.toggle_input()
			quit_confirmation.popup_centered_ratio(0.35)
		
		if practice_gui_mode == PRACTICE_GUI.SEEK:
			if Input.is_action_pressed("gui_left") or Input.is_action_pressed("gui_right"):
				var dir = Input.get_action_strength("gui_right") - Input.get_action_strength("gui_left")
				go_to_time(game.time_msec + dir * delta * 10000.0)
				update_progress_bar()
				update_time_label()
				
				section_label.text = "No section"
		elif practice_gui_mode == PRACTICE_GUI.SECTION_SEEK:
			var new_section = section
			if Input.is_action_just_pressed("gui_left"):
				new_section -= 1
			if Input.is_action_just_pressed("gui_right"):
				new_section += 1
			
			new_section = clamp(new_section, 0, game.current_song.sections.size() - 1)
			
			if new_section != section:
				set_waypoint(game.current_song.sections[new_section].time)
				
				go_to_time(waypoint)
				update_progress_bar()
				update_time_label()
				
				section = new_section
				update_section()
		elif practice_gui_mode == PRACTICE_GUI.OPTIONS:
			if Input.is_action_just_pressed("practice_apply_latency"):
				var old_offset = UserSettings.user_settings.per_song_settings[game.current_song.id].lag_compensation
				
				var avg_latency = 0.0
				if latency_data:
					for note_i in range(min(latency_data.size(), 40)):
						avg_latency += latency_data[note_i]
					avg_latency /= min(latency_data.size(), 40)
				
				latency_data = []
				update_stats_label()
				
				UserSettings.user_settings.per_song_settings[game.current_song.id].set("lag_compensation", old_offset + int(avg_latency))
				UserSettings.save_user_settings()
				song_settings_editor.current_song = game.current_song
		elif practice_gui_mode == PRACTICE_GUI.SPEED:
			var new_speed := playback_speed
			
			if Input.is_action_just_pressed("gui_left"):
				new_speed -= 0.1
			if Input.is_action_just_pressed("gui_right"):
				new_speed += 0.1
			
			new_speed = clamp(new_speed, 0.1, 2.0)
			
			if new_speed != playback_speed:
				set_velocity(new_speed)
	
	if not get_tree().paused or practice_gui_mode == PRACTICE_GUI.SEEK:
		if Input.is_action_just_pressed("practice_set_waypoint"):
			set_waypoint(game.time_msec)
	
	if not get_tree().paused or practice_gui_mode in [PRACTICE_GUI.SEEK, PRACTICE_GUI.SECTION_SEEK]:
		if Input.is_action_just_pressed("practice_go_to_waypoint"):
			go_to_time(waypoint)
			reset_stats()

func _set_mode(new_mode: int):
	_set_mode_impl(new_mode)
func _set_mode_impl(new_mode: int, update := false):
	new_mode += PRACTICE_GUI.size()
	new_mode = new_mode % PRACTICE_GUI.size()
	
	if new_mode != practice_gui_mode or update:
		if new_mode == PRACTICE_GUI.SEEK:
			practice_seek_gui.show()
		else:
			practice_seek_gui.hide()
		
		if new_mode == PRACTICE_GUI.SECTION_SEEK:
			if game.current_song.sections:
				section = 0
				for _section in game.current_song.sections:
					if _section.time <= game.time_msec:
						section += 1
				
				update_section()
				practice_section_seek_gui.show()
			else:
				# Lets pray to the recursion gods that this doesnt implode
				_set_mode(new_mode + (new_mode - practice_gui_mode))
				return
		else:
			practice_section_seek_gui.hide()
		
		if new_mode == PRACTICE_GUI.OPTIONS:
			practice_settings_gui.show()
			song_settings_editor.current_song = game.current_song
			song_settings_editor.show_editor()
		else:
			practice_settings_gui.hide()
		
		if new_mode == PRACTICE_GUI.SPEED:
			practice_speed_gui.show()
		else:
			practice_speed_gui.hide()
	
	practice_gui_mode = new_mode

func set_waypoint(time: int):
	waypoint = time
	seek_progess_bar_waypoint.show()
	section_seek_progess_bar_waypoint.show()
	update_progress_bar_waypoint()
	
	section_label.text = "No section"

func update_section():
	if game.current_song.sections:
		var new_section = game.current_song.sections[section]
		section_label.text = new_section.name
		update_stats_label()

func update_time_label():
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time
	var end_time = game.audio_playback.get_length_msec()
	if song.end_time > 0:
		end_time = song.end_time
	var current_duration = game.audio_playback.get_length_msec()
	current_duration -= start_time
	current_duration -= game.audio_playback.get_length_msec() - end_time
	var time_str = HBUtils.format_time(game.time_msec - start_time, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
	var song_length_str = HBUtils.format_time(current_duration, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
	
	seek_time_label.text = "%s/%s" % [time_str, song_length_str]
	section_seek_time_label.text = "%s/%s" % [time_str, song_length_str]

func go_to_time(time: float):
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var end_time = game.audio_playback.get_length_msec()
	if song.end_time > 0:
		end_time = song.end_time
	time = clamp(time, song.start_time, end_time)
	video_player.play()
	if not get_tree().paused:
		game.editing = false
		game.seek_new(time, true)
		game.start()
		game.set_process(true)
		game._process(0)
		video_player.paused = false
	else:
		game.seek_new(time, true)
		game.time_msec = time
		game._process(0)
		update_progress_bar()
		video_player.paused = true
		video_player.set_stream_position(game.time_msec / 1000.0)
	video_player.set_stream_position(game.time_msec / 1000.0)

func reset_stats():
	stats_passed_notes = 0
	stats_total_notes = 0
	for judgement in stats_judgements:
		stats_judgements[judgement] = 0
	
	stats_diffs = []
	notes_in_second = []
	latency_data = []
	
	game.result = HBResult.new()
	game._potential_result = HBResult.new()
	game.game_ui.reset_score_counter()
	game.current_combo = 0
	game.game_ui._update_clear_bar_value()
	update_stats_label()

func update_progress_bar():
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time
	var end_time = game.audio_playback.get_length_msec()
	if song.end_time > 0:
		end_time = song.end_time
	
	var current_duration = game.audio_playback.get_length_msec()
	current_duration -= start_time
	current_duration -= game.audio_playback.get_length_msec() - end_time
	
	var progress: float = game.time_msec - start_time
	progress = progress / float(current_duration)
	
	seek_progress_bar.value = progress
	section_seek_progress_bar.value = progress

func update_progress_bar_waypoint():
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time
	var end_time = game.audio_playback.get_length_msec()
	if song.end_time > 0:
		end_time = song.end_time
	
	var current_duration = game.audio_playback.get_length_msec()
	current_duration -= start_time
	current_duration -= game.audio_playback.get_length_msec() - end_time
	
	var waypoint_pos: float = waypoint - start_time
	waypoint_pos = waypoint_pos / float(current_duration)
	
	seek_progess_bar_waypoint.value = waypoint_pos
	section_seek_progess_bar_waypoint.value = waypoint_pos

func update_stats_label():
	for i in range(notes_in_second.size()-1, -1, -1):
		var n_time = notes_in_second[i]
		if n_time < (game.time_msec - 1000):
			notes_in_second.remove_at(i)
	
	var passed_percentage = 0.0
	var avg_latency = 0.0
	
	if stats_total_notes > 0 :
		passed_percentage = stats_passed_notes / float(stats_total_notes) * 100.0
	
	avg_latency = 0.0
	if latency_data:
		for note_i in range(min(latency_data.size(), 40)):
			avg_latency += latency_data[note_i]
		avg_latency /= min(latency_data.size(), 40)
	
	var current_section = game.get_section_at_time(game.time_msec)
	var current_speed = game.get_note_speed_at_time(game.time_msec)
	var current_bpm = 0.0
	var current_time_sig = "4/4"
	for timing_change in game.timing_changes:
		if timing_change.time > game.time_msec:
			break
		
		current_bpm = timing_change.bpm
		current_time_sig = "%d/%d" % [timing_change.time_signature.numerator, timing_change.time_signature.denominator]
	
	ingame_stats_label.text = "Game info:\n"
	ingame_stats_label.text += ('"%s"\n' % current_section.name) if current_section else ""
	ingame_stats_label.text += "BPM: %.*f\n" % [0 if round(current_bpm) == current_bpm else 2, current_bpm]
	ingame_stats_label.text += "Time sig: %s\n" % current_time_sig
	ingame_stats_label.text += "Note speed: %.*fBPM\n" % [0 if round(current_speed) == current_speed else 2, current_speed]
	ingame_stats_label.text += "NPS: %d\n" % notes_in_second.size()
	
	ingame_stats_label.text += "\nAccuracy:\n"
	ingame_stats_label.text += "Notes hit: %d/%d (%.2f %%)\n" % [stats_passed_notes, stats_total_notes, passed_percentage]
	ingame_stats_label.text += "Avg. latency: %.0f ms\n" % [avg_latency]
	ingame_stats_label.text += "Cools: %d/%d\n" % [stats_judgements[HBJudge.JUDGE_RATINGS.COOL], stats_total_notes]
	ingame_stats_label.text += "Fines: %d/%d\n" % [stats_judgements[HBJudge.JUDGE_RATINGS.FINE], stats_total_notes]
	ingame_stats_label.text += "Safes: %d/%d\n" % [stats_judgements[HBJudge.JUDGE_RATINGS.SAFE], stats_total_notes]
	ingame_stats_label.text += "Sads: %d/%d\n" % [stats_judgements[HBJudge.JUDGE_RATINGS.SAD], stats_total_notes]
	ingame_stats_label.text += "Worsts/Wrongs: %d/%d\n" % [stats_judgements[HBJudge.JUDGE_RATINGS.WORST], stats_total_notes]

func _on_note_judged(judgement_info):
	var judgement = judgement_info.judgement
	var target_time = judgement_info.target_time
	
	stats_total_notes += 1
	notes_in_second.append(target_time)
	if judgement >= HBJudge.JUDGE_RATINGS.FINE and not judgement_info.wrong:
		stats_passed_notes += 1
		latency_data.append(judgement_info.time - judgement_info.target_time)
	
	if not judgement_info.wrong:
		stats_judgements[judgement] += 1
	else:
		stats_judgements[HBJudge.JUDGE_RATINGS.WORST] += 1
	
	update_stats_label()


func _on_SeekButton_seeked(seek_pos):
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time
	var end_time = game.audio_playback.get_length_msec()
	if song.end_time > 0:
		end_time = song.end_time
	var current_duration = game.audio_playback.get_length_msec()
	current_duration -= start_time
	current_duration -= game.audio_playback.get_length_msec() - end_time
	var new_time = start_time + (seek_pos * current_duration)
	go_to_time(new_time)
	update_time_label()


func set_velocity(value: float):
	playback_speed = value
	
	game.audio_playback.set_pitch_scale(playback_speed)
	if game.voice_audio_playback:
		game.voice_audio_playback.set_pitch_scale(playback_speed)
	
	pitch_shift_effect.pitch_scale = 1.0 / playback_speed
	
	# TODO: add back pitch shift effect
	
	if pitch_shift_effect.pitch_scale != 1.0:
		add_pitch_effect()
		if video_player.stream:
			video_player.hide()
			$Node2D/Panel.hide()
	else:
		remove_pitch_effect()
		if video_player.stream:
			video_player.show()
			$Node2D/Panel.show()
	
	speed_label.text = str(playback_speed) + "x"

func add_pitch_effect():
	pitch_shift_effect.connect_to_endpoint()
	HBGame.spectrum_analyzer.connect_to_effect(pitch_shift_effect)

func remove_pitch_effect():
	HBGame.spectrum_analyzer.connect_to_endpoint()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		remove_pitch_effect()
