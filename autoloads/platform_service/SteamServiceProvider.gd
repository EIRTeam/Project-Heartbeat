extends PlatformServiceProvider

const LOG_NAME = "SteamServiceProvider"

func _init():
	implements_lobby_list = true
	implements_leaderboards = true
	implements_ugc = true
	implements_leaderboard_auth = true
	Steam.connect("get_auth_session_ticket_response", Callable(self, "_on_get_auth_session_ticket_response"))
	Steam.connect("gamepad_text_input_dismissed", Callable(self, "_on_gamepad_input_dismissed"))
	
func _on_gamepad_input_dismissed(submitted: bool, text: String):
	emit_signal("gamepad_input_dismissed", submitted, text)
	
func _on_get_auth_session_ticket_response(auth_id, result):
	if result == 1:
		emit_signal("ticket_ready")
	else:
		emit_signal("ticket_failed", result)
	
func get_avatar() -> Texture2D:
	var img_handle = Steam.getMediumFriendAvatar(Steam.getSteamID())
	var size = Steam.getImageSize(img_handle)
	var buffer = Steam.getImageRGBA(img_handle).buffer
	var avatar_image = Image.create(size.width, size.height, false, Image.FORMAT_RGBAF)
	
	for y in range(size.height):
		for x in range(size.width):
			var pixel = 4 * (x + y * size.height)
			var r = float(buffer[pixel]) / 255.0
			var g = float(buffer[pixel+1]) / 255.0
			var b = float(buffer[pixel+2]) / 255.0
			var a = float(buffer[pixel+3]) / 255.0
			avatar_image.set_pixel(x, y, Color(r, g, b, a))
	var avatar_texture = ImageTexture.create_from_image(avatar_image)
	return avatar_texture
func init_platform() -> int:
	if Engine.has_singleton("Steam"):
		var init = Steam.steamInit()
		
		Log.log(self, init.verbal)
		if init.status != 1 and init.status != Steam.RESULT_NOT_LOGGED_ON:
			return init.status
		
		friendly_username = Steam.getPersonaName()
		user_id = Steam.getSteamID()
		multiplayer_provider = SteamMultiplayerService.new()
		multiplayer_provider.connect("lobby_join_requested", Callable(self, "_on_lobby_join_requested"))
		leaderboard_provider = SteamLeaderboardService.new()
		ugc_provider = SteamUGCService.new()
		
		super.init_platform()
		
		return OK
	else:
		Log.log(self, "Engine was not built with Steam support, aborting...")
		return ERR_METHOD_NOT_FOUND
		
func _post_game_init():
	if UserSettings.user_settings.enable_system_mmplus_loading:
		setup_system_mm_plus()

var MainMenu = load("res://menus/MainMenu3D.tscn")
		
func _on_lobby_join_requested(lobby: HBLobby):
	lobby.join_lobby()
	lobby.connect("lobby_joined", Callable(self, "_on_lobby_joined_from_invite").bind(lobby))
func _on_lobby_joined_from_invite(response, lobby: HBLobby):
	var args = { "lobby": lobby }
	
	if response == HBLobby.LOBBY_ENTER_RESPONSE.SUCCESS:
		if get_tree().current_scene is HBMainMenu:
			var menu: HBMainMenu = get_tree().current_scene
			menu._on_change_to_menu("lobby", false, args)
		else:
			var scene = MainMenu.instantiate()
			get_tree().current_scene.queue_free()
			scene.starting_menu = "lobby"
			scene.starting_menu_args = args
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
		
func run_callbacks():
	Steam.run_callbacks()
	emit_signal("run_mp_callbacks")

# TODO
func get_achivements():
	pass

func write_remote_file(file_name: String, data: PackedByteArray):
	Log.log(self, "Writing to remote file: %s" % [file_name])
	return Steam.fileWrite(file_name, data, data.size())

# HACK because Steam and Godot are dumb, idk which one is dumber
func _wait_for_thread_HACK(thread: Thread):
	thread.wait_to_finish()

func _write_remote_file_async(userdata):
	var result = Steam.fileWrite(userdata.file_name, userdata.data, userdata.data.size())
	if result:
		Log.log(self, "Wrote succesfully to remote file (asynchronously): %s" % [userdata.file_name])
	call_deferred("_wait_for_thread_HACK", userdata.thread)
func write_remote_file_async(file_name: String, data: PackedByteArray):
	var thread = Thread.new()
	Log.log(self, "Writing to remote file (asynchronously): %s" % [file_name])	
	var result = thread.start(Callable(self, "_write_remote_file_async").bind({"file_name": file_name, "data": data, "thread": thread}))
	if result != OK:
		Log.log(self, "Error starting thread for writing remote file: " + str(result), Log.LogLevel.ERROR)

# Write a file to remote
func write_remote_file_from_path(file_name: String, path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var buffer = file.get_buffer(file.get_length())
		var result = Steam.fileWrite(file_name, buffer, file.get_length())
		if not result:
			Log.log(self, "Error writing file to remote storage: %s" % [file_name])
	else:
		Log.log(self, "Error reading file to write in remote: %s" % [path])
	
func is_big_picture():
	return Steam.isSteamInBigPictureMode()
	
func is_steam_deck():
	return Steam.isSteamRunningOnSteamDeck()
	
func read_remote_file(file_name: String):
	var result = {}
	if not Steam.fileExists(file_name):
		Log.log(self, "Attempted to read a remote file that does not exist: %s" % [file_name])
		result["result"] = false
	else:
		var read_result = Steam.fileRead(file_name, Steam.getFileSize(file_name))
		if not read_result.ret:
			Log.log(self, "Error reading remote file: %s" % [file_name])
		else:
			result["buffer"] = read_result.buf
		result["result"] = read_result.ret != 0
	return result
func read_remote_file_to_path(file_name: String, target_path: String):
	var result = read_remote_file(file_name)
	if result.result:
		var file := FileAccess.open(target_path, FileAccess.WRITE)
		var err := FileAccess.get_open_error()
		if err == OK:
			file.store_buffer(result.buffer)
		else:
			Log.log(self, "Error opening file to write remote data: %s (Error: %d)" % [file_name, err])

func is_remote_storage_enabled():
	return Steam.isCloudEnabledForApp()

# Leaderboard auth token
func get_leaderboard_auth_token():
	return Steam.getAuthSessionTicket().buffer

func unlock_achievement(achievement_name: String):
	var achievement_result = Steam.setAchievement(achievement_name)
	if not achievement_result:
		Log.log(self, "Error setting achievement %s" % [achievement_name], Log.LogLevel.ERROR)
func save_achievements():
	var store_stats_result = Steam.storeStats()
	if not store_stats_result:
		Log.log(self, "Error storing achievement stats", Log.LogLevel.ERROR)

func show_gamepad_text_input(existing_text := "", multi_line := false, description := "Enter text") -> bool:
	var line_mode = Steam.GAMEPAD_TEXT_INPUT_LINE_MODE_MULTIPLE_LINES if \
		multi_line else Steam.GAMEPAD_TEXT_INPUT_LINE_MODE_SINGLE_LINE
	return Steam.showGamepadTextInput(Steam.GAMEPAD_TEXT_INPUT_MODE_NORMAL, line_mode, description, 1024, existing_text)

func show_floating_gamepad_text_input(multi_line := false) -> bool:
	var ws := get_window().size
	var height = ws.y
	var position_y = (height / 3.0) * 2.0
	var input_height = (height / 3.0)
	var type = Steam.FLOATING_GAMEPAD_TEXT_INPUT_MODE_SINGLE_LINE
	if multi_line:
		type = Steam.FLOATING_GAMEPAD_TEXT_INPUT_MODE_MULTIPLE_LINES
	return Steam.showFloatingGamepadTextInput(type, position_y, 0, ws.x, input_height)

const MMPLUS_APPID := 1761390

func setup_system_mm_plus():
	var owns_mmplus: bool = Steam.isSubscribedApp(MMPLUS_APPID)
	if not owns_mmplus:
		HBGame.mmplus_error = HBGame.MMPLUS_ERROR.NOT_OWNED
		return
	var is_mmplus_installed: bool = Steam.isAppInstalled(MMPLUS_APPID)
	if not is_mmplus_installed:
		HBGame.mmplus_error = HBGame.MMPLUS_ERROR.NOT_INSTALLED
		return
	var mmplus_path: String = Steam.getAppInstallDir(MMPLUS_APPID)
	var dsc_loader = SongLoaderDSC.new()
	dsc_loader.GAME_LOCATION = mmplus_path
	dsc_loader.game_type = "MMPLUS"
	HBGame.mmplus_loader = dsc_loader
	SongLoader.add_song_loader("system_mmplus", dsc_loader)
	if dsc_loader.has_fatal_error():
		HBGame.mmplus_error = HBGame.MMPLUS_ERROR.LOAD_ERROR
		return
	HBGame.mmplus_error = HBGame.MMPLUS_ERROR.OK
