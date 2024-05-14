extends Node

class_name HBMultiplayerService

# warning-ignore:unused_signal
signal lobby_match_list(lobbies)
# warning-ignore:unused_signal
signal lobby_join_requested(lobby)

func request_lobby_list():
	pass

func get_lobby_name(lobby_id):
	pass
	
func get_lobby_members(lobby_id):
	pass

func get_lobby_max_members(lobby_id):
	pass

func _init():
	name = "MultiplayerService"
