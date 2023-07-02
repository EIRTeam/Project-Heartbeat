extends HBMultiplayerService

class_name SteamMultiplayerService

const LOG_NAME = "SteamMultiplayerService"

func _init():
	Steam.connect("lobby_match_list", Callable(self, "_on_lobby_list_returned"))
	Steam.connect("join_requested", Callable(self, "_on_lobby_join_requested"))
	
func _check_cmd():
	var arguments = OS.get_cmdline_args()
	
	# Steam argument detection shit
	if arguments.size() > 1:

		for i in range(arguments.size()):
			var argument = arguments[i]
			if argument == "+connect_lobby" and i < arguments.size()-1:
				_on_lobby_join_requested(int(arguments[i+1]), 0)
				break

func request_lobby_list():
	Log.log(self, "Requesting lobby list")
	Steam.addRequestLobbyListDistanceFilter(3) # = worldwide
	Steam.requestLobbyList()
func _on_lobby_list_returned(lobbies):
	Log.log(self, "Received %s lobbies" % lobbies.size())
	var lobby_list = []
	for lobby_id in lobbies:
		var lobby = SteamLobby.new(lobby_id)
		lobby_list.append(lobby)
		lobby.obtain_game_info()
	emit_signal("lobby_match_list", lobby_list)

func create_lobby():
	return SteamLobby.new(null)

func _on_lobby_join_requested(lobby_id: int, steam_id: int):
	var lobby = SteamLobby.new(lobby_id)
	emit_signal("lobby_join_requested", lobby)
