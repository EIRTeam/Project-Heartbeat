extends HBMultiplayerService

class_name SteamMultiplayerService

const LOG_NAME = "SteamMultiplayerService"

func _init():
	pass

func request_lobby_list() -> HBLobbyListQuery:
	Log.log(self, "Requesting lobby list")
	var query := Steamworks.matchmaking.create_lobby_list_query()
	query.filter_distance_worldwide()
	return query.request_lobby_list()
