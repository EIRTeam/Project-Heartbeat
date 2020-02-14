extends HBLobbyMember

class_name SteamLobbyMember

func _init(id):
	service_member = SteamServiceMember.new(id)
