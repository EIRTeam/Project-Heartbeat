extends HBSongListMenu

@onready var lobby_title_label = get_node("VBoxContainer/LobbyTitleLabel")
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	previous_menu = "lobby"
	if args.has("lobby"):
		var lobby := args.lobby as HeartbeatSteamLobby
		lobby_title_label.text = "Selecting song for %s" % [lobby.lobby_data.lobby_name]

func _on_difficulty_selected(song: HBSong, difficulty: String):
	change_to_menu("lobby", false, {"action": LobbyMenu.LobbyMenuAction.CHANGE_SONG, "song": song, "difficulty": difficulty})
	
