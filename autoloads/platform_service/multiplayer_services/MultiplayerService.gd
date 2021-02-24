extends Node

class_name HBMultiplayerService

# warning-ignore:unused_signal
signal lobby_match_list(lobbies)
# warning-ignore:unused_signal
signal lobby_join_requested(lobby)

var lobby: HBLobby

func request_lobby_list():
	pass

func get_lobby_name(lobby_id):
	pass
	
func get_lobby_members(lobby_id):
	pass

func get_lobby_max_members(lobby_id):
	pass

func join_lobby(new_lobby: HBLobby):
	pass

func create_lobby():
	return HBLobby.new(null)

func _init():
	name = "MultiplayerService"
