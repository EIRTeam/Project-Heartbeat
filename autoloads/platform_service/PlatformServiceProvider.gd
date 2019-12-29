extends Node

class_name PlatformServiceProvider

const DEFAULT_AVATAR = preload("res://graphics/default_avatar.png")

var friendly_username = "Player"
var user_id = "Player" # unique user id, can be a number


func init_platform() -> int:
	return 0

func get_avatar() -> Texture:
	return DEFAULT_AVATAR
