class_name HBServiceMember

var member_id

var member_name: String = "Kirino Kousaka": get = get_member_name
var avatar: Texture2D = preload("res://graphics/default_avatar.png")
# warning-ignore:unused_signal
signal persona_state_change(flags)
func _init(id):
	member_id = id
	
func get_member_name():
	return member_name

func get_avatar():
	return avatar

func is_local_user():
	return true
