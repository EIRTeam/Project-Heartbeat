extends Control

const LOG_NAME = "RhythmGameController"

var MainMenu = load("res://menus/MainMenu3D.tscn")

const FADE_OUT_TIME = 1.0

const ROLLBACK_TIME = 1.3 # Rollback time after pausing and unpausing
var rollback_on_resume = false
onready var fade_out_tween = get_node("FadeOutTween")
onready var fade_in_tween = get_node("FadeInTween")
onready var game : HBRhythmGame

onready var game_ui_container = get_node("GameUIContainer")

var game_ui: HBRhythmGameUIBase

onready var visualizer = get_node("Node2D/Visualizer")
onready var vhs_panel = get_node("VHS")
onready var rollback_label_animation_player = get_node("RollbackLabel/AnimationPlayer")
onready var pause_menu = get_node("PauseMenu")
var pause_disabled = false
var last_pause_time = 0.0
var pause_menu_disabled = false
var prevent_showing_results = false
var prevent_scene_changes = false
var allow_modifiers = true
var disable_intro_skip = false

var current_game_info: HBGameInfo 

onready var video_player = get_node("Node2D/Panel/VideoPlayer")

signal fade_out_finished(game_info)
signal user_quit()

var current_assets = {}

func _ready():
	connect("resized", self, "set_game_size")
	MainMenu = load("res://menus/MainMenu3D.tscn")
	
	game = HBRhythmGame.new()
	add_child(game)
	
	DownloadProgress.holding_back_notifications = true

	fade_in_tween.connect("tween_all_completed", self, "_fade_in_done")
	game.connect("intro_skipped", self, "_on_intro_skipped")
	
	set_process(false)
	
	game.connect("song_cleared", self, "_on_RhythmGame_song_cleared")
	$Label.visible = false
func _on_intro_skipped(new_time):
	video_player.set_stream_position(new_time)

func _fade_in_done():
	video_player.paused = false
	video_player.show()
	$FadeIn.hide()
	# HACK HACK: This makes sync very good and makes it effectively target 0
	# this is why we do a single game cycle, to get the timing right
	game.play_song()
	game._process(0.0)
	video_player.set_stream_position(game.time)
	rescale_video_player()
	
	pause_menu_disabled = false
	game.play_song()
func start_fade_in():
#	video_player.hide()
	$FadeIn.modulate.a = 1.0
	$FadeIn.show()
	var original_color = Color.white
	var target_color = Color.white
	target_color.a = 0.0
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	game.time = song.start_time / 1000.0
	fade_in_tween.interpolate_property($FadeIn, "modulate", original_color, target_color, FADE_OUT_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_in_tween.start()
	pause_menu_disabled = true
	HBGame.song_stats.song_played(song.id)
	HBGame.song_stats.save_song_stats()

func start_session(game_info: HBGameInfo, assets=null):
	current_assets = assets
	if not SongLoader.songs.has(game_info.song_id):
		Log.log(self, "Error starting session: Song not found %s" % [game_info.song_id])
		return
	
	var song = SongLoader.songs[game_info.song_id] as HBSong
	
	var game_mode = HBGame.get_game_mode_for_song(song)
	
	if game_mode is HBGameMode:
		game_ui = game_mode.get_ui().instance()
		game_ui_container.add_child(game_ui)
		game.set_game_ui(game_ui)
		game.set_game_input_manager(game_mode.get_input_manager())
	else:
		Log.log(self, "Can't find game mode for song: %s" % [game_info.song_id], Log.LogLevel.ERROR)
	
	if not song.charts.has(game_info.difficulty):
		Log.log(self, "Error starting session: Chart not found %s %s" % [game_info.song_id, game_info.difficulty])
		return
	
	current_game_info = game_info
	var offset = game_info.get_song().get_video_offset(game_info.variant)
	video_player.offset = -offset / 1000.0
	var modifiers = []
	for modifier_id in game_info.modifiers:
		var modifier = ModifierLoader.get_modifier_by_id(modifier_id).new() as HBModifier
		modifier.modifier_settings = game_info.modifiers[modifier_id]
		modifiers.append(modifier)
	game.current_variant = game_info.variant
	set_song(song, game_info.difficulty, modifiers, false, assets)
	set_process(true)

func disable_restart():
	$PauseMenu.disable_restart()
	
const SONGS_WITH_IMAGE = [
	"imademo_2012",
	"cloud_sky_2019",
	"hyperspeed_out_of_control",
	"music_play_in_the_floor",
	"connected"
]
	
func set_song(song: HBSong, difficulty: String, modifiers = [], force_caching_off=false, assets=null):
	var bg_path = song.get_song_background_image_res_path()
	if assets:
		if "background" in assets:
			$Node2D/TextureRect.texture = assets.background
	else:
		var image = HBUtils.image_from_fs(bg_path)
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, HBGame.platform_settings.texture_mode)
		$Node2D/TextureRect.texture = image_texture
	game.disable_intro_skip = disable_intro_skip
	game.set_song(song, difficulty, assets, modifiers)
	set_game_size()
	if not force_caching_off:
		game.cache_note_drawers()
	$Node2D/Panel.hide()
	
#	if allow_modifiers:3
#		for 
		
	var large_image_name = "default"
		
	if song.id in SONGS_WITH_IMAGE:
		large_image_name = song.id
		
	var title = song.title
	
	# Discord breaks if the song name is too short
	
	if title.length() <= 1:
		title = "A song named: %s" % [title]
		
	HBGame.rich_presence.update_activity({
		"state": "Playing a song",
		"large_image_key": large_image_name,
		"details": title,
		"start_timestamp": OS.get_unix_time(),
		"large_image_tooltip": title
	})
		
	var modifier_disables_video = false
	for modifier in modifiers:
		if modifier.disables_video:
			modifier_disables_video = true
			Log.log(self, "One of the modifiers disables video playback")
			break
	var video_enabled_for_song = true
	if UserSettings.user_settings.per_song_settings.has(song.id):
		var pss = UserSettings.user_settings.per_song_settings[song.id] as HBPerSongSettings
		video_enabled_for_song = pss.video_enabled
		rescale_video_player()
	start_fade_in()
	if song.has_video_enabled() and not modifier_disables_video and video_enabled_for_song:
		if song.get_song_video_res_path() or (song.youtube_url and song.use_youtube_for_video and song.is_cached()):
			var stream = song.get_video_stream(current_game_info.variant)
			if stream:
				video_player.hide()
				# HACK HACK HACK: vp9 decoder requires us to set the stream position
				# to -1, then set it to 0 wait 5 frames, set our target start time
				# wait another 5 frames and only then can we pause the player
				# yeah I don't know why I bother either
				if not video_player.stream:
					video_player.stream = stream
					video_player.set_stream_position(0)
					video_player.paused = true
				video_player.play()
				video_player.set_stream_position(song.get_video_offset(current_game_info.variant) / 1000.0)
				if game.time < 0.0:
					video_player.paused = true
				$Node2D/Panel.show()
				if visualizer and UserSettings.user_settings.visualizer_enabled:
					visualizer.visible = UserSettings.user_settings.use_visualizer_with_video
			else:
				Log.log(self, "Video Stream failed to load")
	
func rescale_video_player():
	var video_texture = video_player.get_video_texture()
	if video_texture:
		var video_size = video_texture.get_size()
		var video_ar = video_size.x / video_size.y
		var new_size_x = rect_size.y * video_ar
		if new_size_x <= rect_size.x:
			# side black bars (or none)
			video_player.rect_size = Vector2(new_size_x, rect_size.y)
		else:
			# bottom and top black bars
			video_player.rect_size = Vector2(rect_size.x, rect_size.x / video_ar)
		# Center that shit
		video_player.rect_position.x = (rect_size.x - video_player.rect_size.x) / 2.0
		video_player.rect_position.y = (rect_size.y - video_player.rect_size.y) / 2.0

func set_game_size():
	game.size = rect_size
	if $Node2D/Visualizer:
		$Node2D/Visualizer.rect_size = rect_size
	#$Node2D/VHS.rect_size = rect_size
	$Node2D/TextureRect.rect_size = rect_size
	$Node2D/Panel.rect_size = rect_size
	#game_.rect_size = rect_size
	rescale_video_player()
#	$Node2D/VideoPlayer.rect_size = rect_size
func _on_resumed():
	get_tree().paused = false
	$PauseMenu.hide()
	
	set_process(true)
	if not rollback_on_resume:
		game.play_from_pos(game.time)
		game.set_process(true)
		game._process(0)
		video_player.paused = false
		video_player.set_stream_position(game.time)
		if game.time < 0.0:
			video_player.paused = true
	else:
		# Called when resuming with rollback
		$RollbackAudioStreamPlayer.play()
		game.editing = true
		game.kill_active_slide_chains()
		game.time = last_pause_time
		rollback_label_animation_player.play("appear")
		pause_menu_disabled = true
		video_player.set_stream_position(last_pause_time - ROLLBACK_TIME)
		if game.time < 0.0:
			video_player.paused = true
		vhs_panel.show()
		
func _input(event):
	if event.is_action_pressed("hide_ui") and event.shift and event.control:
		game_ui._on_toggle_ui()
		$Node2D.visible = game_ui.is_ui_visible()
func _unhandled_input(event):
	if not pause_menu_disabled:
		if event.is_action_pressed("pause") and not event.is_echo():
			if not get_tree().paused:
				if not pause_disabled:
					_on_paused()
					video_player.paused = true
					game.pause_game()
				Input.stop_joy_vibration(UserSettings.controller_device_idx)
				$PauseMenu.show_pause(current_game_info.song_id)
	
			else:
				_on_resumed()
				$PauseMenu._on_resumed()
			get_tree().set_input_as_handled()


func _show_results(game_info: HBGameInfo):
	get_tree().paused = false
	if not prevent_scene_changes:
		if not prevent_showing_results:
			var scene = MainMenu.instance()
			get_tree().current_scene.queue_free()
			scene.starting_menu = "results"
			scene.starting_menu_args = {"game_info": game_info, "assets": current_assets}
			scene.starting_song = current_game_info.get_song()
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
#	scene.set_result(results)

func _on_paused():
	get_tree().paused = true
	set_process(false)
	if game.time - last_pause_time >= ROLLBACK_TIME and game.time > 0:
		last_pause_time = game.time
		rollback_on_resume = true
		game.set_process(false)
		game.editing = true
func _on_RhythmGame_song_cleared(result: HBResult):
	var original_color = Color.black
	original_color.a = 0
	var target_color = Color.black
	$FadeToBlack.show()
	current_game_info.result = result
	fade_out_tween.interpolate_property($FadeToBlack, "modulate", original_color, target_color, FADE_OUT_TIME,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_out_tween.connect("tween_all_completed", self, "_show_results", [current_game_info])
	fade_out_tween.connect("tween_all_completed", self, "_on_fade_out_finished")
	fade_out_tween.start()
	
func _on_fade_out_finished():
	emit_signal("fade_out_finished", current_game_info)

var _last_time = 0.0

#var prev_aht = 0

func _process(delta):
#	$Label.visible = Diagnostics.fps_label.visible
#	$Label.text = "pos %f \n audiopos %f \n diff %f \n LHI: %d\nAudio norm off: %.2f\n" % [video_player.stream_position, game.time, game.time - video_player.stream_position, game.last_hit_index, game._volume_offset]
#	$Label.text += "al: %.4f %.4f\n" % [AudioServer.get_time_to_next_mix(), AudioServer.get_output_latency()]
#	$Label.text += "Ticks: %d\n BT: %d" % [OS.get_ticks_usec(), game.time_begin]
#	var AHT = game.audio_stream_player.get_playback_position() - AudioServer.get_output_latency()
#	AHT = int(AHT*1000.0)
#	if AHT < prev_aht:
#		AHT = prev_aht
#	else:
#		prev_aht = AHT
#	$Label.text = "GT: %d\nAHT: %d\ndiff: %d" % [int(game.time*1000.0), AHT, int(game.time*1000.0) - AHT]
	var latency_compensation = UserSettings.user_settings.lag_compensation
	if current_game_info:
		if current_game_info.song_id in UserSettings.user_settings.per_song_settings:
			latency_compensation += UserSettings.user_settings.per_song_settings[current_game_info.song_id].lag_compensation
	if rollback_on_resume:
		game.time -= delta
		game.audio_stream_player.stream_paused = true
		game.audio_stream_player_voice.stream_paused = true
		game.audio_stream_player.seek(game.time + latency_compensation)
		game._process(0)
#		$Label.text += "%f" % [last_pause_time]
		if game.time <= last_pause_time - ROLLBACK_TIME:
			game.time = last_pause_time - ROLLBACK_TIME
			rollback_on_resume = false
			vhs_panel.hide()
			pause_menu_disabled = false
			rollback_label_animation_player.play("disappear")
			game.editing = false
			_on_resumed()
func seek(pos: float):
	var latency_compensation = UserSettings.user_settings.lag_compensation
	if current_game_info:
		if current_game_info.song_id in UserSettings.user_settings.per_song_settings:
			latency_compensation += UserSettings.user_settings.per_song_settings[current_game_info.song_id].lag_compensation
	game.time = pos
	print("SEEK To %.2f", pos)
	game.audio_stream_player.stream_paused = true
	game.audio_stream_player_voice.stream_paused = true
	game.audio_stream_player.seek(game.time + latency_compensation)
func _on_PauseMenu_quit():
	emit_signal("user_quit")
	var scene = MainMenu.instance()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "song_list"
	scene.starting_menu_args = {"song": current_game_info.song_id, "song_difficulty": current_game_info.difficulty}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	_on_resumed()
	
func _on_PauseMenu_restarted():
	var modifiers = []
	for modifier_id in current_game_info.modifiers:
		var modifier = ModifierLoader.get_modifier_by_id(modifier_id).new() as HBModifier
		modifier.modifier_settings = current_game_info.modifiers[modifier_id]
		modifiers.append(modifier)
	last_pause_time = 0.0
	rollback_on_resume = false
	game.restart()
	video_player.stream_position = current_game_info.get_song().start_time / 1000.0
	#set_song(song, current_game_info.difficulty, modifiers)
	set_process(true)
	game.set_process(true)
	game.editing = false
	start_fade_in()
