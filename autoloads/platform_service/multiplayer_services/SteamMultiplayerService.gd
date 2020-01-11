extends HBMultiplayerService

class_name SteamMultiplayerService

const LOG_NAME = "SteamMultiplayerService"

func _init():
	Steam.connect("lobby_match_list", self , "_on_lobby_list_returned")
func _check_cmd():
	var arguments = OS.get_cmdline_args()
	
	var lobby_invite_arg = false
	# Steam argument detection shit
	if arguments.size() > 0:

		for argument in arguments:
			if lobby_invite_arg:
				var lobby = SteamLobby.new(int(argument))
				join_lobby(lobby)

			if argument == "+connect_lobby":
				lobby_invite_arg = true
				

func request_lobby_list():
	Log.log(self, "Requesting lobby list")
	Steam.addRequestLobbyListDistanceFilter(3) # = worldwide
	Steam.requestLobbyList()
func _on_lobby_list_returned(lobbies):
	Log.log(self, "Received %s lobbies" % lobbies.size())
	var lobby_list = []
	for lobby_id in lobbies:
		lobby_list.append(SteamLobby.new(lobby_id))
	emit_signal("lobby_match_list", lobby_list)

func create_lobby():
	return SteamLobby.new(null)
