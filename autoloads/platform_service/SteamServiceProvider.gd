extends PlatformServiceProvider

const LOG_NAME = "SteamServiceProvider"

var local_user: HBSteamFriend

const APP_ID := 1216230

signal auth_ticket_received(ticket)
var current_awaiting_token: HBAuthTicketForWebAPI
var auth_token: HBAuthTicketForWebAPI

func _init():
	implements_lobby_list = true
	implements_leaderboards = true
	implements_ugc = true
	implements_leaderboard_auth = true
	
func _on_gamepad_input_dismissed(submitted: bool, text: String):
	emit_signal("gamepad_input_dismissed", submitted, text)
	
func get_avatar() -> Texture2D:
	return local_user.avatar

func init_platform() -> int:
	if Engine.has_singleton("Steamworks"):
		var init = Steamworks.is_valid()
		if not init:
			return ERR_UNAVAILABLE
		Steamworks.set_run_callbacks_automatically(false)
		
		InputGlyphsSingleton.init()
		
		local_user = Steamworks.user.get_local_user()
		friendly_username = local_user.persona_name
		user_id = local_user.steam_id
		if not HBGame.demo_mode:
			ugc_provider = SteamUGCService.new()
		else:
			implements_ugc = false
		Steamworks.utils.gamepad_text_input_dismissed.connect(self._on_gamepad_input_dismissed)
		
		super.init_platform()
		
		Steamworks.friends.lobby_join_requested.connect(self._on_lobby_join_requested)
		_check_cmd()
		return OK
	else:
		Log.log(self, "Engine was not built with Steam support, aborting...")
		return ERR_METHOD_NOT_FOUND
		
func _check_cmd():
	var arguments = OS.get_cmdline_args()
	
	# Steam argument detection shit
	if arguments.size() > 1:
		for i in range(arguments.size()):
			var argument = arguments[i]
			if argument == "+connect_lobby" and i < arguments.size()-1:
				_on_lobby_join_requested(HBSteamLobby.from_id(arguments[i+1]))
				break
		
func _on_lobby_join_requested(steam_lobby: HBSteamLobby):
	var lobby := await HeartbeatSteamLobby.join_lobby(steam_lobby)
	var MainMenu = load("res://menus/MainMenu3D.tscn")

	var scene = MainMenu.instantiate()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "lobby"
	scene.starting_menu_args = {
		"lobby": lobby
	}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
		
func _post_game_init():
	if UserSettings.user_settings.enable_system_mmplus_loading and not HBGame.demo_mode:
		setup_system_mm_plus()

var MainMenu = load("res://menus/MainMenu3D.tscn")
		
func run_callbacks():
	Steamworks.run_callbacks()
	emit_signal("run_mp_callbacks")

# TODO
func get_achivements():
	pass

#func write_remote_file(file_name: String, data: PackedByteArray):
	#Log.log(self, "Writing to remote file: %s" % [file_name])
	#return Steamworks.remote_storage.file_write(file_name, data)

# HACK because Steam and Godot are dumb, idk which one is dumber
func _wait_for_thread_HACK(thread: Thread):
	thread.wait_to_finish()

#func _write_remote_file_async(userdata):
	#var result = Steamworks.remote_storage.file_write(userdata.file_name, userdata.data)
	#if result:
		#Log.log(self, "Wrote succesfully to remote file (asynchronously): %s" % [userdata.file_name])
	#call_deferred("_wait_for_thread_HACK", userdata.thread)
#func write_remote_file_async(file_name: String, data: PackedByteArray):
	#var thread = Thread.new()
	#Log.log(self, "Writing to remote file (asynchronously): %s" % [file_name])	
	#var result = thread.start(Callable(self, "_write_remote_file_async").bind({"file_name": file_name, "data": data, "thread": thread}))
	#if result != OK:
		#Log.log(self, "Error starting thread for writing remote file: " + str(result), Log.LogLevel.ERROR)
#
## Write a file to remote
#func write_remote_file_from_path(file_name: String, path: String):
	#var file = FileAccess.open(path, FileAccess.READ)
	#if FileAccess.get_open_error() == OK:
		#var buffer = file.get_buffer(file.get_length())
		#var result = Steamworks.remote_storage.file_write(file_name, buffer)
		#if not result:
			#Log.log(self, "Error writing file to remote storage: %s" % [file_name])
	#else:
		#Log.log(self, "Error reading file to write in remote: %s" % [path])
	
func is_big_picture():
	return Steamworks.utils.is_in_big_picture_mode()
	
func is_steam_deck():
	return Steamworks.utils.is_on_steam_deck()
	
#func read_remote_file(file_name: String):
	#var result = {}
	#if not Steamworks.remote_storage.file_exists(file_name):
		#Log.log(self, "Attempted to read a remote file that does not exist: %s" % [file_name])
		#result["result"] = false
	#else:
		#var read_result = Steamworks.remote_storage.file_read(file_name)
		#if not read_result.size() > 0:
			#Log.log(self, "Error reading remote file: %s" % [file_name])
		#else:
			#result["buffer"] = read_result
		#result["result"] = read_result.size() != 0
	#return result
#func read_remote_file_to_path(file_name: String, target_path: String):
	#var result = read_remote_file(file_name)
	#if result.result:
		#var file := FileAccess.open(target_path, FileAccess.WRITE)
		#var err := FileAccess.get_open_error()
		#if err == OK:
			#file.store_buffer(result.buffer)
		#else:
			#Log.log(self, "Error opening file to write remote data: %s (Error: %d)" % [file_name, err])

func is_remote_storage_enabled():
	return false
	return Steamworks.remote_storage.is_cloud_enabled()

# Leaderboard auth token
func get_leaderboard_auth_token():
	return auth_token.ticket_data
	
func request_new_auth_token() -> HBAuthTicketForWebAPI:
	var ticket := Steamworks.user.get_auth_ticket_for_web_api("Project Heartbeat")
	return ticket
func unlock_achievement(achievement_name: String):
	var achievement_result = Steamworks.user_stats.set_achievement(achievement_name)
	if not achievement_result:
		Log.log(self, "Error setting achievement %s" % [achievement_name], Log.LogLevel.ERROR)
func save_achievements():
	var store_stats_result = Steamworks.user_stats.store_stats()
	if not store_stats_result:
		Log.log(self, "Error storing achievement stats", Log.LogLevel.ERROR)

func show_gamepad_text_input(existing_text := "", multi_line := false, description := "Enter text") -> bool:
	var line_mode = SteamworksConstants.GAMEPAD_TEXT_INPUT_LINE_MODE_MULTIPLE_LINES if \
		multi_line else SteamworksConstants.GAMEPAD_TEXT_INPUT_LINE_MODE_SINGLE_LINE
	return Steamworks.utils.show_gamepad_text_input(SteamworksConstants.GAMEPAD_TEXT_INPUT_MODE_NORMAL, line_mode, description, existing_text, 1024)

func show_floating_gamepad_text_input(multi_line := false) -> bool:
	var ws := get_window().size
	var height = ws.y
	var position_y = (height / 3.0) * 2.0
	var input_height = (height / 3.0)
	var type = SteamworksConstants.FLOATING_GAMEPAD_TEXT_INPUT_MODE_MODE_SINGLE_LINE
	if multi_line:
		type = SteamworksConstants.FLOATING_GAMEPAD_TEXT_INPUT_MODE_MODE_MULTIPLE_LINES
	return Steamworks.utils.show_floating_gamepad_text_input(type, Rect2(position_y, 0, ws.x, input_height))

const MMPLUS_APPID := 1761390

func setup_system_mm_plus():
	var owns_mmplus: bool = Steamworks.apps.is_subscribed_app(MMPLUS_APPID)
	if not owns_mmplus:
		HBGame.mmplus_error = HBGame.MMPLUS_ERROR.NOT_OWNED
		return
	var is_mmplus_installed: bool = Steamworks.apps.is_app_installed(MMPLUS_APPID)
	if not is_mmplus_installed:
		HBGame.mmplus_error = HBGame.MMPLUS_ERROR.NOT_INSTALLED
		return
	var mmplus_path: String = Steamworks.apps.get_app_install_dir(MMPLUS_APPID)
	var dsc_loader = SongLoaderDSC.new()
	dsc_loader.GAME_LOCATION = mmplus_path
	dsc_loader.game_type = "MMPLUS"
	HBGame.mmplus_loader = dsc_loader
	SongLoader.add_song_loader("system_mmplus", dsc_loader)
	if dsc_loader.has_fatal_error():
		HBGame.mmplus_error = HBGame.MMPLUS_ERROR.LOAD_ERROR
		return
	HBGame.mmplus_error = HBGame.MMPLUS_ERROR.OK
