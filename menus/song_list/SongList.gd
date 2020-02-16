extends HBMenu

class_name HBSongListMenu

signal song_hovered(song)
var current_difficulty
onready var difficulty_list = get_node("VBoxContainer/DifficultyList")
onready var scroll_container = get_node("VBoxContainer/MarginContainer/ScrollContainer")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$VBoxContainer/MarginContainer/ScrollContainer.grab_focus()
	if args.has("song_difficulty"):
#		_select_difficulty(args.song_difficulty)
		for i in range(difficulty_list.get_child_count()):
			var button = difficulty_list.get_child(i)
			if button.get_meta("difficulty") == args.song_difficulty:
				difficulty_list.select_button(i)
	else:
		difficulty_list.select_button(0)
	if args.has("song"):
		$VBoxContainer/MarginContainer/ScrollContainer.select_song_by_id(args.song)

func _ready():
	print(get_node("VBoxContainer/MarginContainer/ScrollContainer"))
	$VBoxContainer/MarginContainer/ScrollContainer.connect("song_hovered", self, "_on_song_hovered")
	for difficulty in SongLoader.available_difficulties:
		var button = HBHovereableButton.new()
		button.focus_mode = FOCUS_NONE
		button.text = difficulty.capitalize()
		button.connect("hovered", self, "_select_difficulty", [difficulty])
		button.set_meta("difficulty", difficulty)
		difficulty_list.add_child(button)

	scroll_container.connect("song_selected", self, "_on_song_selected")
	
func _on_song_hovered(song: HBSong):
	emit_signal("song_hovered", song)

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		get_tree().set_input_as_handled()
		change_to_menu("main_menu")
	if event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right"):
		$VBoxContainer/DifficultyList._gui_input(event)

func _on_song_selected(song: HBSong):
	change_to_menu("pre_song", false, {"song": song, "difficulty": current_difficulty})
#	var new_scene = preload("res://rythm_game/rhythm_game.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song, current_difficulty)



func _select_difficulty(difficulty: String):
	current_difficulty = difficulty
	$VBoxContainer/MarginContainer/ScrollContainer.set_songs(SongLoader.get_songs_with_difficulty(difficulty), difficulty)
