extends "res://rythm_game/rhythm_game_controller.gd"

onready var progress_bar = $MarginContainer/VBoxContainer/VBoxContainer/ProgressBar
onready var practice_gui = $MarginContainer
onready var progess_bar_waypoint = get_node("MarginContainer/VBoxContainer/VBoxContainer/ProgressBar/ProgresBarWaypoint")
onready var ingame_stats_label = get_node("PracticeModeUIIngame/HBoxContainer/Label")
onready var quit_confirmation = get_node("QuitConfirmation")
onready var time_label = get_node("MarginContainer/VBoxContainer/VBoxContainer/Label")
onready var video_pause_timer = Timer.new()

var stats_passed_notes = 0
var stats_total_notes = 0
var stats_latency_sum = 0
var stats_diffs = []
var last_notes = []

var waypoint = 0.0

func _ready():
	video_pause_timer.connect("timeout", self, "_on_video_pause")
	video_pause_timer.wait_time = 0.050
	game.connect("note_judged", self, "_on_note_judged")
	quit_confirmation.connect("accept", Diagnostics.gamepad_visualizer, "hide")
	quit_confirmation.connect("accept", self, "_on_PauseMenu_quit")
	update_stats_label()
	practice_gui.hide()
	game.disable_ending = true
	Diagnostics.gamepad_visualizer.show()
func set_song(song: HBSong, difficulty: String, modifiers = [], force_caching_off=false, assets=null):
	.set_song(song, difficulty, modifiers, true, assets)
	fade_in_tween.remove_all()
	_fade_in_done()
	disable_intro_skip = true
	pause_disabled = true
	pause_menu_disabled = true
	disable_restart()
	add_child(video_pause_timer)
	video_player.play()
	for _i in range(6):
		yield(get_tree(), 'idle_frame')
	video_player.paused = false
	game._process(0)
	video_player.stream_position = game.time
	practice_gui.hide()
	game.game_ui.disable_score_processing = true
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		get_tree().paused = !get_tree().paused
		practice_gui.visible = get_tree().paused
		#video_player.paused = get_tree().paused
		game.toggle_ui()
		set_process(true)
		update_progress_bar()
		quit_confirmation.hide()
		quit_confirmation.release_focus()
		#vhs_panel.visible = get_tree().paused
		if get_tree().paused:
			last_pause_time = game.time
			game.editing = true
			video_player.paused = true
			update_time_label()
			update_progress_bar()
		else:
			reset_stats()
			video_pause_timer.stop()
			game.editing = false
			game.play_from_pos(game.time)
			game.set_process(true)
			game._process(0)
			video_player.paused = false
			video_player.stream_position = game.time
		
func _on_video_pause():
	video_player.paused = true
		
func _process(delta):
	game.result.used_cheats = true
	if Input.is_action_just_pressed("practice_set_waypoint"):
		waypoint = game.time
		progess_bar_waypoint.show()
		update_progress_bar_waypoint()
	if Input.is_action_just_pressed("practice_go_to_waypoint"):
		go_to_time(waypoint)
		reset_stats()
	if get_tree().paused:
		if Input.is_action_just_pressed("contextual_option"):
			quit_confirmation.popup_centered_ratio(0.35)
		if not quit_confirmation.visible:
			if Input.is_action_pressed("gui_left") or Input.is_action_pressed("gui_right"):
				var dir = Input.get_action_strength("gui_right") - Input.get_action_strength("gui_left")
				go_to_time(game.time + dir * delta * 10.0)
				update_progress_bar()
				update_time_label()
				
func update_time_label():
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time / 1000.0
	var end_time = game.audio_stream_player.stream.get_length()
	if song.end_time > 0:
		end_time = song.end_time / 1000.0
	var current_duration = game.audio_stream_player.stream.get_length()
	current_duration -= start_time
	current_duration -= game.audio_stream_player.stream.get_length() - end_time
	var time_str = HBUtils.format_time(game.time * 1000.0 - start_time * 1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
	var song_length_str = HBUtils.format_time(current_duration * 1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
	time_label.text = "%s/%s" % [time_str, song_length_str]
				
func go_to_time(time: float):
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var end_time = game.audio_stream_player.stream.get_length()
	if song.end_time > 0:
		end_time = song.end_time / 1000.0
	time = clamp(time, song.start_time / 1000.0, end_time)
	video_player.play()
	if not get_tree().paused:
		game.reset_hit_notes()
		video_pause_timer.stop()
		game.editing = false
		game.play_from_pos(time)
		game.set_process(true)
		game._process(0)
		game.delete_rogue_notes(game.time)
		video_player.paused = false
		video_player.stream_position = game.time
	else:
		game.reset_hit_notes()
		game.time = time
		game.delete_rogue_notes(game.time)
		game._process(0)
		update_progress_bar()
		video_player.paused = false
		video_player.stream_position = game.time
		video_pause_timer.start()

func reset_stats():
	stats_latency_sum = 0
	stats_passed_notes = 0
	stats_total_notes = 0
	stats_diffs = []
	last_notes = []
	update_stats_label()
func update_progress_bar():
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time / 1000.0
	var end_time = game.audio_stream_player.stream.get_length()
	if song.end_time > 0:
		end_time = song.end_time / 1000.0
	
	var current_duration = game.audio_stream_player.stream.get_length()
	current_duration -= start_time
	current_duration -= game.audio_stream_player.stream.get_length() - end_time
	
	var progress = game.time - start_time
	progress = progress / current_duration
	
	progress_bar.value = progress
func update_progress_bar_waypoint():
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time / 1000.0
	var end_time = game.audio_stream_player.stream.get_length()
	if song.end_time > 0:
		end_time = song.end_time / 1000.0
	
	var current_duration = game.audio_stream_player.stream.get_length()
	current_duration -= start_time
	current_duration -= game.audio_stream_player.stream.get_length() - end_time
	
	var waypoint_pos = waypoint - start_time
	waypoint_pos = waypoint_pos / current_duration
	progess_bar_waypoint.value = waypoint_pos
func update_stats_label():
	
	for i in range(last_notes.size()-1, -1, -1):
		var n_time = last_notes[i]
		if n_time < (game.time * 1000.0) - 1000.0:
			last_notes.remove(i)
	var passed_percentage = 0.0
	var avg_latency = 0.0
	if stats_total_notes > 0 :
		passed_percentage = stats_passed_notes/float(stats_total_notes) * 100.0
	if stats_passed_notes > 0:
		avg_latency = stats_latency_sum / float(stats_passed_notes)
	ingame_stats_label.text = "%d/%d (%.2f %%)\n" % [stats_passed_notes, stats_total_notes, passed_percentage]
	ingame_stats_label.text += "NPS: %d\n" % last_notes.size()
	ingame_stats_label.text += "Avg. latency: %.0f ms" % [avg_latency]
#	var stats_passed_notes = 0
#var stats_total_notes = 0
#var stats_diffs = []
#var stats_average_diff = 0
#var last_notes = []
func _on_note_judged(judgement_info):
	#		var judgement_info = {"judgement": judgement, "target_time": notes[0].time, "time": int(time * 1000), "wrong": wrong, "avg_pos": avg_pos}
	var judgement = judgement_info.judgement
	var target_time = judgement_info.target_time
	stats_total_notes += 1
	last_notes.append(target_time)
	if judgement >= HBJudge.JUDGE_RATINGS.FINE and not judgement_info.wrong:
		stats_passed_notes += 1
		stats_latency_sum += judgement_info.time-judgement_info.target_time
	update_stats_label()


func _on_SeekButton_seeked(seek_pos):
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_time = song.start_time / 1000.0
	var end_time = game.audio_stream_player.stream.get_length()
	if song.end_time > 0:
		end_time = song.end_time / 1000.0
	var current_duration = game.audio_stream_player.stream.get_length()
	current_duration -= start_time
	current_duration -= game.audio_stream_player.stream.get_length() - end_time
	var new_time = start_time + (seek_pos * current_duration)
	go_to_time(new_time)
	update_time_label()
