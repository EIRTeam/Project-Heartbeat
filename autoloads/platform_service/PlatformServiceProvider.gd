extends Node

class_name PlatformServiceProvider

const DEFAULT_AVATAR = preload("res://graphics/default_avatar.png")

var friendly_username = "Player"
var user_id = "Player" # unique user id, can be a number
var multiplayer_provider: HBMultiplayerService
var leaderboard_provider: HBLeaderboardService

var implements_lobby_list = false
var implements_leaderboards = false

signal run_mp_callbacks

func init_platform() -> int:
	return 0

func get_avatar() -> Texture:
	return DEFAULT_AVATAR

func run_callbacks():
	pass

func get_achivements():
	return []
