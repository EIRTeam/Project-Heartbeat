extends HBSerializable

class_name HBWebUserInfo

var id: int = 0
var steam_id: String = ""
var is_admin: bool = false
var level: int = 1
var experience: int = 0 

func _init():
	serializable_fields += ["id", "steam_id", "is_admin", "level", "experience"]

func get_serialized_type():
	return "WebUserInfo"
