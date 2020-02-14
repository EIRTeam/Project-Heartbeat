extends HBMenu

onready var song_title = get_node("MarginContainer/VBoxContainer/SongTitle")
onready var leaderboard = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/Leaderboard")
onready var button_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel2/MarginContainer/VBoxContainer")
onready var button_panel = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel2")
var current_song: HBSong
var current_difficulty: String

const BASE_BUTTON_PANEL_HEIGHT = 106
const BASE_HEIGHT = 720.0

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
func _on_resized():
	# We have to wait a frame for the resize to happen...
	# seriously wtf
	yield(get_tree(), "idle_frame")
	var inv = 1.0 / (rect_size.y / BASE_HEIGHT)
	button_panel.size_flags_stretch_ratio = inv

func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("song"):
		current_song = args.song
	button_container.grab_focus()
	current_difficulty = current_song.charts.keys()[0]
	if args.has("difficulty"):
		current_difficulty = args.difficulty
	song_title.difficulty = current_difficulty
	leaderboard.set_song(current_song.id, current_difficulty)
	

func _on_StartButton_pressed():
	var new_scene = preload("res://rythm_game/rhythm_game.tscn")
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.set_song(current_song, current_difficulty)


func _on_BackButton_pressed():
	change_to_menu("song_list", false, {"song": current_song.id, "song_difficulty": current_difficulty})
