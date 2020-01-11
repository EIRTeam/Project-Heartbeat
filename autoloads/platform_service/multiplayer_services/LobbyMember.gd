class_name HBLobbyMember

var member_id

var member_name: String = "Kirino Kousaka" setget ,get_member_name
var avatar: Texture = preload("res://graphics/default_avatar.png")

func _init(id):
	member_id = id
	
func get_member_name():
	return member_name

func get_avatar():
	return avatar
