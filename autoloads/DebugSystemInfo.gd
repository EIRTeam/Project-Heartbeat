extends CanvasLayer

var sv = SteamMultiplayerService.new()

func _ready():
	$"Version Label".text = HBVersion.get_version_string()
##	sv.connect("lobby_match_list", self, "_on_lobbylist_returned")
##	sv.request_lobby_list()
##	print(Steam.getAppID())
#func _on_lobbylist_returned(lobbies):
#	for lobby in lobbies:
#		print(lobby.lobby_name)
