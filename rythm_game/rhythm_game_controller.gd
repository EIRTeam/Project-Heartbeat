extends Control

const LOG_NAME = "RhythmGameController"

var MainMenu = load("res://menus/MainMenu3D.tscn")

const FADE_OUT_TIME = 1.0

onready var fade_out_tween = get_node("FadeOutTween")
onready var game : HBRhythmGame = get_node("RhythmGame")
var pause_disabled = false
var prevent_showing_results = false

var current_game_info: HBGameInfo 

onready var video_player = get_node("Node2D/Panel/VideoPlayer")

signal fade_out_finished(game_info)
signal user_quit()
func _ready():
	set_game_size()
	connect("resized", self, "set_game_size")
	MainMenu = load("res://menus/MainMenu3D.tscn")
func start_session(game_info: HBGameInfo):
	if not SongLoader.songs.has(game_info.song_id):
		Log.log(self, "Error starting session: Song not found %s" % [game_info.song_id])
		return
	
	var song = SongLoader.songs[game_info.song_id] as HBSong
	
	if not song.charts.has(game_info.difficulty):
		Log.log(self, "Error starting session: Chart not found %s %s" % [game_info.song_id, game_info.difficulty])
		return
	
	current_game_info = game_info
	
	set_song(song, game_info.difficulty, game_info.modifiers)

func disable_restart():
	$PauseMenu.disable_restart()
	
func set_song(song: HBSong, difficulty: String, modifiers = []):
	var bg_path = song.get_song_background_image_res_path()
	var image = HBUtils.image_from_fs(bg_path)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image, Texture.FLAGS_DEFAULT)
	$Node2D/TextureRect.texture = image_texture
	$RhythmGame.set_modifiers(modifiers)
	$RhythmGame.set_song(song, difficulty)
	
	if song.get_song_video_res_path() or (song.youtube_url and song.use_youtube_for_video and song.is_cached()):
		var stream = song.get_video_stream()
		if stream:
			video_player.show()
			video_player.stream = stream
			video_player.play()
		else:
			Log.log(self, "Video Stream failed to load")
	else:
		video_player.hide()
	rescale_video_player()
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
	if event.is_action_pressed("pause") and not event.is_echo():
		if not get_tree().paused:
			if not pause_disabled:
				_on_paused()
				video_player.paused = true
				$RhythmGame.pause_game()
			$PauseMenu.show_pause()

		else:
			_on_resumed()
			$PauseMenu._on_resumed()
		get_tree().set_input_as_handled()


func _show_results(game_info: HBGameInfo):
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
	current_game_info.result = result
	fade_out_tween.interpolate_property($FadeToBlack, "modulate", original_color, target_color, FADE_OUT_TIME,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_out_tween.connect("tween_all_completed", self, "_show_results", [current_game_info])
	fade_out_tween.connect("tween_all_completed", self, "emit_signal", ["fade_out_finished", current_game_info])
	fade_out_tween.start()

func _on_PauseMenu_quit():
	emit_signal("user_quit")
	var scene = MainMenu.instance()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "song_list"
	scene.starting_menu_args = {"song": current_game_info.song_id, "song_difficulty": current_game_info.difficulty}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	_on_resumed()
