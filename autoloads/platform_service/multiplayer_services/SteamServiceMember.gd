extends HBServiceMember

class_name SteamServiceMember

var steam_avatar_cached = false
var user: HBSteamFriend

func _init(id):
	super(id)
	user = HBSteamFriend.from_steam_id(id)
	user.request_user_information(true)
	member_name = user.persona_name
	user.information_updated.connect(_persona_state_change)

func _persona_state_change():
	member_name = user.persona_name
	emit_signal("persona_state_change")
	
func get_avatar():
	return user.avatar

func is_local_user():
	return user == Steamworks.user.get_local_user()
