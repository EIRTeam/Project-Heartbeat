extends Node

class_name PlatformServiceProvider

const DEFAULT_AVATAR = preload("res://graphics/default_avatar.png")
# relative to user://
const FILES_TO_SYNC_ON_STARTUP = ["user_settings.json", "history.json", "song_stats.hbdict"]

var friendly_username = "Player"
var user_id = "Player" # unique user id, can be a number
var multiplayer_provider: HBMultiplayerService
var leaderboard_provider: HBLeaderboardService
var ugc_provider: HBUGCService
var implements_lobby_list = false
var implements_leaderboards = false
var implements_leaderboard_auth = false
var implements_ugc = false

signal run_mp_callbacks
signal ticket_ready
signal ticket_failed

func _init():
	name = "PlatformServiceProvider"

func init_platform() -> int:
	if is_remote_storage_enabled():
		for file_path in FILES_TO_SYNC_ON_STARTUP:
			read_remote_file_to_path(file_path, "user://" + file_path.get_file())
#		write_remote_file_from_path(file_path, "user://" + file_path.get_file())
	if multiplayer_provider:
		add_child(multiplayer_provider)
	return 0

func get_avatar() -> Texture:
	return DEFAULT_AVATAR

func run_callbacks():
	pass

func get_achivements():
	return []
func write_remote_file_async(file_name: String, data: PoolByteArray):
	pass
# Remote storage (for save sync)
func write_remote_file(file_name: String, data: PoolByteArray):
	pass

func write_remote_file_from_path(file_name: String, path: String):
	pass
	
func read_remote_file(file_name: String):
	pass
	
func read_remote_file_to_path(file_name: String, target_path: String):
	pass
func is_remote_storage_enabled():
	return false
func get_leaderboard_auth_token():
	pass
