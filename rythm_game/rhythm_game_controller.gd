extends Control

const LOG_NAME = "RhythmGameController"

var MainMenu = load("res://menus/MainMenu3D.tscn")

const FADE_OUT_TIME = 1.0

onready var fade_out_tween = get_node("FadeOutTween")
onready var fade_in_tween = get_node("FadeInTween")
onready var game : HBRhythmGame = get_node("RhythmGame")
onready var visualizer = get_node("Node2D/Control")
var pause_disabled = false
var pause_menu_disabled = false
var prevent_showing_results = false
var prevent_scene_changes = false
var allow_modifiers = true
var disable_intro_skip = false

var current_game_info: HBGameInfo 

onready var video_player = get_node("Node2D/Panel/VideoPlayer")

signal fade_out_finished(game_info)
signal user_quit()
func _ready():
	set_game_size()
	connect("resized", self, "set_game_size")
	MainMenu = load("res://menus/MainMenu3D.tscn")
	DownloadProgress.holding_back_notifications = true

	fade_in_tween.connect("tween_all_completed", self, "_fade_in_done")

func _fade_in_done():
	$RhythmGame.play_song()
	$FadeIn.hide()
	video_player.paused = false
	video_player.play()
	pause_menu_disabled = false

func start_fade_in():
	$FadeIn.modulate.a = 1.0
	$FadeIn.show()
	var original_color = Color.white
	var target_color = Color.white
	target_color.a = 0.0
	var song = SongLoader.songs[current_game_info.song_id] as HBSong
	video_player.stream_position = song.start_time  / 1000.0
	fade_in_tween.interpolate_property($FadeIn, "modulate", original_color, target_color, FADE_OUT_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)	
	fade_in_tween.start()
	pause_menu_disabled = true
	

func start_session(game_info: HBGameInfo):
	if not SongLoader.songs.has(game_info.song_id):
		Log.log(self, "Error starting session: Song not found %s" % [game_info.song_id])
		return
	
	var song = SongLoader.songs[game_info.song_id] as HBSong
	
	if not song.charts.has(game_info.difficulty):
		Log.log(self, "Error starting session: Chart not found %s %s" % [game_info.song_id, game_info.difficulty])
		return
	
	current_game_info = game_info
	var modifiers = []
	for modifier_id in game_info.modifiers:
		var modifier = ModifierLoader.get_modifier_by_id(modifier_id).new() as HBModifier
		modifier.modifier_settings = game_info.modifiers[modifier_id]
		modifiers.append(modifier)
	set_song(song, game_info.difficulty, modifiers)

func disable_restart():
	$PauseMenu.disable_restart()
	
func set_song(song: HBSong, difficulty: String, modifiers = []):
	var bg_path = song.get_song_background_image_res_path()
	var image = HBUtils.image_from_fs(bg_path)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image, Texture.FLAGS_DEFAULT)
	$Node2D/TextureRect.texture = image_texture
	$RhythmGame.disable_intro_skip = disable_intro_skip
	$RhythmGame.set_song(song, difficulty, null, modifiers)
	$Node2D/Panel.hide()
	
#	if allow_modifiers:3
#		for 
		
		
	var modifier_disables_video = false
	for modifier in modifiers:
		if modifier.disables_video:
			modifier_disables_video = true
			Log.log(self, "One of the modifiers disables video playback")
			break
	if song.has_video_enabled() and not modifier_disables_video:
		if song.get_song_video_res_path() or (song.youtube_url and song.use_youtube_for_video and song.is_cached()):
			var stream = song.get_video_stream()
			if stream:
				video_player.stream = stream
				video_player.stop()
				$Node2D/Panel.show()
				visualizer.visible = UserSettings.user_settings.use_visualizer_with_video
			else:
				Log.log(self, "Video Stream failed to load")
		rescale_video_player()
	start_fade_in()
	
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
	$RhythmGame.size = rect_size
	$Node2D/Control.rect_size = rect_size
	$Node2D/TextureRect.rect_size = rect_size
	$Node2D/Panel.rect_size = rect_size
	rescale_video_player()
#	$Node2D/VideoPlayer.rect_size = rect_size
func _on_resumed():
	$RhythmGame.resume()
	$PauseMenu.hide()
	video_player.paused = false
	
func _unhandled_input(event):
	if not pause_menu_disabled:
		if event.is_action_pressed("pause") and not event.is_echo():
			if not get_tree().paused:
				if not pause_disabled:
					_on_paused()
					video_player.paused = true
					$RhythmGame.pause_game()
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
			scene.starting_menu_args = {"game_info": game_info}
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
#	scene.set_result(results)

func _on_paused():
	pass

func _on_RhythmGame_song_cleared(result: HBResult):
	var original_color = Color.black
	original_color.a = 0
	var target_color = Color.black
	$FadeToBlack.show()
	pause_menu_disabled = true
	current_game_info.result = result
	print("SONG CLEARED!")
	fade_out_tween.interpolate_property($FadeToBlack, "modulate", original_color, target_color, FADE_OUT_TIME,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_out_tween.connect("tween_all_completed", self, "_show_results", [current_game_info])
	fade_out_tween.connect("tween_all_completed", self, "emit_signal", ["fade_out_finished", current_game_info])
	fade_out_tween.start()

var _last_time = 0.0

func _process(delta):
	pass

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
	var song = SongLoader.songs[current_game_info.song_id]
	set_song(song, current_game_info.difficulty, modifiers)
	start_fade_in()
