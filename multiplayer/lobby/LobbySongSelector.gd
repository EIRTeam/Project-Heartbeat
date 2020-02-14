extends HBSongListMenu

onready var lobby_title_label = get_node("VBoxContainer/LobbyTitleLabel")

func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("lobby"):
		var lobby = args.lobby as HBLobby
		lobby_title_label.text = "Selecting song for %s" % [lobby.lobby_name]

func _on_song_selected(song: HBSong):
	change_to_menu("lobby", false, {"song": song, "difficulty": current_difficulty})
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		change_to_menu("lobby")
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		$VBoxContainer/DifficultyList._gui_input(event)
