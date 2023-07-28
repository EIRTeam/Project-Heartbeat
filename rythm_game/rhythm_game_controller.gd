extends Control

const LOG_NAME = "RhythmGameController"

var MainMenu = load("res://menus/MainMenu3D.tscn")

const FADE_OUT_TIME = 1.0

const ROLLBACK_TIME = 1300 # Rollback time after pausing and unpausing
var rollback_on_resume = false
@onready var fade_out_tween = get_node("FadeOutThreen")
@onready var fade_in_tween = get_node("FadeInThreen")
@onready var game : HBRhythmGame

@onready var game_ui_container = get_node("GameUIContainer")

var game_ui: HBRhythmGameUIBase

@onready var visualizer = get_node("Node2D/Visualizer")
@onready var vhs_panel = get_node("VHS")
@onready var background_texture = get_node("Node2D/TextureRect")
@onready var video_player_panel = get_node("Node2D/Panel")
@onready var rollback_label_animation_player = get_node("RollbackLabel/AnimationPlayer")
@onready var pause_menu = get_node("PauseMenu")
@onready var game_over_tween := Threen.new()
var pause_disabled = false
var last_pause_time := 0
var pause_menu_disabled = false
var prevent_showing_results = false
var prevent_scene_changes = false
var allow_modifiers = true
var disable_intro_skip = false

var current_game_info: HBGameInfo 

@onready var video_player = get_node("Node2D/Panel/VideoStreamPlayer")

signal fade_out_finished(game_info)
signal user_quit()

var current_assets: SongAssetLoader.AssetLoadToken
var playing_game_over_animation := false

var skin_override: HBUISkin
var rollback_delta := 0.0

func _ready():
	connect("resized", Callable(self, "set_game_size"))
	MainMenu = load("res://menus/MainMenu3D.tscn")
	
	game = HBRhythmGame.new()
	add_child(game)
	
	DownloadProgress.holding_back_notifications = true

	fade_in_tween.connect("tween_all_completed", Callable(self, "_fade_in_done"))
	game.connect("intro_skipped", Callable(self, "_on_intro_skipped"))
	
	set_process(false)
	game.set_process(false)
	game.connect("song_cleared", Callable(self, "_on_RhythmGame_song_cleared"))
	game.connect("game_over", Callable(self, "_on_RhythmGame_game_over"))
	add_child(game_over_tween)
	game_over_tween.process_mode = Node.PROCESS_MODE_ALWAYS
	$Label.visible = false
	game.health_system_enabled = UserSettings.user_settings.enable_health
func _on_intro_skipped(new_time):
	video_player.set_stream_position(new_time)

func _fade_in_done():
	video_player.paused = false
	game.game_input_manager.set_process_input(true)
	video_player.show()
	$FadeIn.hide()
	game.set_process(true)
	video_player.set_stream_position(game.time_msec / 1000.0)
	rescale_video_player()
	
	pause_menu_disabled = false
func start_fade_in():
#	video_player.hide()
	Shinobu.set_dsp_time(0)
	UserSettings.enable_menu_fps_limits = false
	$FadeIn.modulate.a = 1.0
	$FadeIn.show()
	var original_color = Color.WHITE
	var target_color = Color.WHITE
	target_color.a = 0.0
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	var start_offset := 0
	
	if song.start_time < 0:
		game.seek(0)
		start_offset = -song.start_time
	else:
		game.seek(song.start_time)
	game.schedule_play_start(start_offset + FADE_OUT_TIME * 1000)
	game.start()
	game.time_msec = song.start_time
	fade_in_tween.interpolate_property($FadeIn, "modulate", original_color, target_color, FADE_OUT_TIME, Threen.TRANS_LINEAR, Threen.EASE_IN_OUT)
	fade_in_tween.start()
	pause_menu_disabled = true
	HBGame.song_stats.song_played(song.id)
	HBGame.song_stats.save_song_stats()
	game.game_input_manager.set_process_input(false)

func start_session(game_info: HBGameInfo, assets: SongAssetLoader.AssetLoadToken = null):
	current_assets = assets
	game.set_process(true)
	if not SongLoader.songs.has(game_info.song_id):
		Log.log(self, "Error starting session: Song not found %s" % [game_info.song_id])
		return
	
	var song = SongLoader.songs[game_info.song_id] as HBSong
	
	var game_mode = HBGame.get_game_mode_for_song(song)
	
	if game_mode is HBGameMode:
		game_ui = game_mode.get_ui().instantiate()
		game_ui.skin_override = skin_override
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
	
func set_song(song: HBSong, difficulty: String, modifiers = [], force_caching_off=false, assets: SongAssetLoader.AssetLoadToken = null):
	var bg_path = song.get_song_background_image_res_path()
	if assets:
		var background := assets.get_asset(SongAssetLoader.ASSET_TYPES.BACKGROUND) as Texture2D
		if background:
			background_texture.texture = background
			background_texture.material = null
			if background is DIVASpriteSet.DIVASprite:
				background_texture.material = background.get_material()
	else:
		print("No assets, whoops")
		var image = HBUtils.image_from_fs(bg_path)
		var image_texture = ImageTexture.create_from_image(image)
		background_texture.texture = image_texture
	game.disable_intro_skip = disable_intro_skip
	game.set_song(song, difficulty, assets, modifiers)
	set_game_size()
	
	video_player_panel.hide()
	
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
		"start_timestamp": Time.get_unix_time_from_system(),
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
				if game.time_msec < 0:
					video_player.paused = true
				video_player_panel.show()
				if visualizer and UserSettings.user_settings.visualizer_enabled:
					visualizer.visible = UserSettings.user_settings.use_visualizer_with_video
			else:
				Log.log(self, "Video Stream failed to load")
	
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

func set_game_size():
	game.size = size
	if visualizer:
		visualizer.size = size
	
	background_texture.size = size
	video_player_panel.size = size
	
	rescale_video_player()

func _on_resumed():
	UserSettings.enable_menu_fps_limits = false
	get_tree().paused = false
	$PauseMenu.hide()
	
	set_process(true)
	if not rollback_on_resume:
		game.start()
		game.set_process(true)
		game._process(0)
		video_player.paused = false
		video_player.set_stream_position(game.time_msec / 1000.0)
		if game.time_msec < 0:
			video_player.paused = true
	else:
		# Called when resuming with rollback
		game.notify_rollback()
		HBGame.fire_and_forget_sound(HBGame.rollback_sfx, HBGame.sfx_group)
		game.editing = true
		game.time_msec = last_pause_time
		rollback_label_animation_player.play("appear")
		pause_menu_disabled = true
		video_player.set_stream_position((last_pause_time - ROLLBACK_TIME) / 1000.0)
		if game.time_msec < 0:
			video_player.paused = true
		vhs_panel.show()
		
func _input(event):
	if event.is_action_pressed("hide_ui") and event.shift_pressed and event.is_command_or_control_pressed():
		game_ui._on_toggle_ui()
		$Node2D.visible = game_ui.is_ui_visible()
func _unhandled_input(event):
	if playing_game_over_animation:
		return
	if not pause_menu_disabled:
		if event.is_action_pressed("pause") and not event.is_echo():
			if not get_tree().paused:
				if not pause_disabled:
					_on_paused()
	
			else:
				_on_resumed()
				$PauseMenu._on_resumed()
			get_viewport().set_input_as_handled()


func _show_results(game_info: HBGameInfo):
	get_tree().paused = false
	if not prevent_scene_changes:
		if not prevent_showing_results:
			var scene = MainMenu.instantiate()
			var old_scene = get_tree().current_scene
			get_tree().current_scene.queue_free()
			scene.starting_menu = "results"
			scene.starting_menu_args = {"game_info": game_info, "assets": current_assets}
			scene.starting_song = current_game_info.get_song()
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
			get_tree().root.remove_child(old_scene)
#	scene.set_result(results)

func _on_paused():
	get_tree().paused = true
	set_process(false)
	if game.time_msec - last_pause_time >= ROLLBACK_TIME and game.time_msec > 0:
		last_pause_time = game.time_msec
		rollback_on_resume = true
		rollback_delta = 0
		game.set_process(false)
		game.editing = true
	video_player.paused = true
	game.pause_game()
	$PauseMenu.show_pause(current_game_info.song_id)

func _on_RhythmGame_song_cleared(result: HBResult):
	var original_color = Color.BLACK
	original_color.a = 0
	var target_color = Color.BLACK
	$FadeToBlack.show()
	current_game_info.result = result
	fade_out_tween.interpolate_property($FadeToBlack, "modulate", original_color, target_color, FADE_OUT_TIME,Threen.TRANS_LINEAR, Threen.EASE_IN_OUT)
	fade_out_tween.connect("tween_all_completed", Callable(self, "_show_results").bind(current_game_info))
	fade_out_tween.connect("tween_all_completed", Callable(self, "_on_fade_out_finished"))
	fade_out_tween.start()
	
func _on_fade_out_finished():
	emit_signal("fade_out_finished", current_game_info)

var _last_time = 0.0

#var prev_aht = 0

# latency compensated target rollback time
func get_target_rollback_time_msec() -> int:
	var latency_compensation = UserSettings.user_settings.lag_compensation
	if current_game_info:
		if current_game_info.song_id in UserSettings.user_settings.per_song_settings:
			latency_compensation += UserSettings.user_settings.per_song_settings[current_game_info.song_id].lag_compensation
	return last_pause_time - ROLLBACK_TIME + latency_compensation
	
func _process(delta):
#	$Label.visible = Diagnostics.fps_label.visible
#	$Label.text = "pos: %d\n" % [game.time_msec]
#	$Label.text = "pos %d \n audiopos %d \n diff %f \n LHI: %d\nAudio norm off: %.2f\n" % [game.audio_playback.get_playback_position_msec(), game.audio_playback.get_playback_position_msec(), game.time - video_player.stream_position, game.last_hit_index, game.audio_playback.volume]
#	$Label.text += "al: %.4f %.4f\n" % [AudioServer.get_time_to_next_mix(), AudioServer.get_output_latency()]
#	$Label.text += "Ticks: %d\n BT: %d" % [OS.get_ticks_usec(), game.time_begin]
#	AHT = int(AHT*1000.0)
#	if AHT < prev_aht:
#		AHT = prev_aht
#	else:
#		prev_aht = AHT
#	$Label.text = "GT: %d\nAHT: %d\ndiff: %d" % [int(game.time*1000.0), AHT, int(game.time*1000.0) - AHT]
	if rollback_on_resume:
		rollback_delta -= delta * 1000.0
		game.seek_new(max(last_pause_time + rollback_delta, last_pause_time - ROLLBACK_TIME))
		game._process(0)
#		$Label.text += "%f" % [last_pause_time]
		if game.time_msec <= last_pause_time - ROLLBACK_TIME:
			game.seek_new(get_target_rollback_time_msec())
			rollback_on_resume = false
			vhs_panel.hide()
			pause_menu_disabled = false
			rollback_label_animation_player.play("disappear")
			game.editing = false
			_on_resumed()
func _on_PauseMenu_quit():
	emit_signal("user_quit")
	var scene = MainMenu.instantiate()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "song_list"
	scene.starting_menu_args = {"song": current_game_info.song_id, "song_difficulty": current_game_info.difficulty}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	get_tree().paused = false
#	_on_resumed()
	
func _on_PauseMenu_restarted():
	var modifiers = []
	for modifier_id in current_game_info.modifiers:
		var modifier = ModifierLoader.get_modifier_by_id(modifier_id).new() as HBModifier
		modifier.modifier_settings = current_game_info.modifiers[modifier_id]
		modifiers.append(modifier)
	last_pause_time = 0
	rollback_on_resume = false
	game.restart()
	video_player.stream_position = current_game_info.get_song().start_time / 1000.0
	#set_song(song, current_game_info.difficulty, modifiers)
	set_process(true)
	game.set_process(true)
	game.editing = false
	game.game_input_manager.set_process_input(false)
	await get_tree().process_frame
	start_fade_in()

func _on_RhythmGame_game_over():
	playing_game_over_animation = true
	game.audio_playback.volume = 0
	game.audio_playback.stop()
	if game.voice_audio_playback:
		game.voice_audio_playback.volume = 0
		game.voice_audio_playback.stop()
	vhs_panel.show()
	vhs_panel.material.set_shader_parameter("desaturation", 0.5)
	game_ui.play_game_over()
	game_over_tween.interpolate_property(game_ui.game_layer_node, "rotation", 0, deg_to_rad(90), 1.0, Threen.TRANS_BOUNCE, Threen.EASE_IN)
	game_over_tween.interpolate_property(game_ui.game_layer_node, "position", game_ui.game_layer_node.position, size, 1.0, Threen.TRANS_BOUNCE, Threen.EASE_IN)
	game_over_tween.start()
	get_tree().paused = true
	game.pause_game()
	await game_over_tween.tween_all_completed
	await get_tree().create_timer(2.0).timeout
	game_ui.play_tv_off_animation()
	await game_ui.tv_off_animation_finished
	current_game_info.result = game.result
	current_game_info.result.failed = true
	_show_results(current_game_info)
	vhs_panel.material.set_shader_parameter("desaturation", 0.25)

func _notification(what):
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not pause_disabled and UserSettings.user_settings.pause_on_focus_loss and \
			not get_tree().paused and not pause_menu_disabled:
				_on_paused()
