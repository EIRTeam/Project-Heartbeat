extends Control

var MainMenu = load("res://menus/MainMenu3D.tscn")

const FADE_OUT_TIME = 1.0

onready var fade_out_tween = get_node("FadeOutTween")
onready var game = get_node("RhythmGame")
var pause_disabled = false
func _ready():
	set_game_size()
	connect("resized", self, "set_game_size")
	MainMenu = load("res://menus/MainMenu3D.tscn")

func set_song(song: HBSong, difficulty: String):
	var bg_path = song.get_song_background_image_res_path()
	var image = HBUtils.image_from_fs(bg_path)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image, Texture.FLAGS_DEFAULT)
	$Node2D/TextureRect.texture = image_texture
	$RhythmGame.set_song(song, difficulty)

func set_game_size():
	$RhythmGame.size = rect_size
	$Node2D/Control.rect_size = rect_size
	$Node2D/TextureRect.rect_size = rect_size
func _on_resumed():
	$RhythmGame.resume()
	$PauseMenu.hide()
	
func _unhandled_input(event):
	if event.is_action_pressed("pause") and not event.is_echo() and not pause_disabled:
		if not get_tree().paused:
			$RhythmGame.pause_game()
			$PauseMenu.show_pause()
		else:
			_on_resumed()
			$PauseMenu._on_resumed()
		get_tree().set_input_as_handled()

func _show_results(results: HBResult):
	var scene = MainMenu.instance()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "results"
	scene.starting_menu_args = {"results": results}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
#	scene.set_result(results)

func _on_RhythmGame_song_cleared(results: HBResult):
	var original_color = Color.black
	original_color.a = 0
	var target_color = Color.black
	fade_out_tween.interpolate_property($FadeToBlack, "modulate", original_color, target_color, FADE_OUT_TIME,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	fade_out_tween.connect("tween_all_completed", self, "_show_results", [results])
	fade_out_tween.start()


func _on_PauseMenu_quit():
	var scene = MainMenu.instance()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "song_list"
	scene.starting_menu_args = {"song": game.current_song.id, "song_difficulty": game.result.difficulty}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	_on_resumed()
