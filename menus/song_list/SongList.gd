extends HBMenu
signal song_hovered(song)
func _on_menu_enter():
	$VBoxContainer/MarginContainer/ScrollContainer.grab_focus()

func _ready():
	print(get_node("VBoxContainer/MarginContainer/ScrollContainer"))
	$VBoxContainer/MarginContainer/ScrollContainer.connect("song_hovered", self, "_on_song_hovered")
func _on_song_hovered(song: HBSong):
	emit_signal("song_hovered", song)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		change_to_menu("main_menu")
