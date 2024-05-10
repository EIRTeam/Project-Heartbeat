extends Control

class_name LobbyMenuDebug

@onready var tree: Tree = get_node("%Tree")

var lobby: HeartbeatSteamLobby:
	set(val):
		lobby = val


func _update_tree():
	tree.clear()
	var root := tree.create_item()
	var lobby_item := tree.create_item(root)
	lobby_item.set_text(0, "Lobby data")
	var lobby_data := lobby.steam_lobby.get_all_lobby_data()
	for meta in lobby_data:
		var meta_item := tree.create_item(lobby_item)
		meta_item.set_text(0, meta)
		meta_item.set_text(1, lobby_data[meta])
	
	const LOBBY_MEMBER_DATA_KEYS = [HeartbeatSteamLobby.MEMBER_SONG_AVAILABILITY_DATA_KEY]
	
	var member_parent := tree.create_item(root)
	member_parent.set_text(0, "Members data")
	for member in lobby.steam_lobby.get_members():
		var member_item := tree.create_item(member_parent)
		member_item.set_text(0, member.persona_name)
		for key in LOBBY_MEMBER_DATA_KEYS:
			var key_item := tree.create_item(member_item)
			key_item.set_text(0, key)
			key_item.set_text(1, lobby.steam_lobby.get_member_data(member, key))

func _on_refresh_button_pressed() -> void:
	_update_tree()
