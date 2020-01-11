extends HBSongListMenu

onready var lobby_title_label = get_node("VBoxContainer/LobbyTitleLabel")

func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("lobby"):
		var lobby = args.lobby as HBLobby
		lobby_title_label.text = "Selecting song for %s" % [lobby.lobby_name]

func _on_song_selected(song: HBSong):
	change_to_menu("lobby", false, {"song": song, "difficulty": current_difficulty})
	
