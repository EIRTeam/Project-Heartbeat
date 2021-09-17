extends PlatformServiceProvider

const LOG_NAME = "SteamServiceProvider"

func _init():
	implements_lobby_list = true
	implements_leaderboards = true
	implements_ugc = true
	implements_leaderboard_auth = true
	Steam.connect("get_auth_session_ticket_response", self, "_on_get_auth_session_ticket_response")
	Steam.connect("gamepad_text_input_dismissed", self, "_on_gamepad_input_dismissed")
	
func _on_gamepad_input_dismissed(submitted: bool, text: String):
	emit_signal("gamepad_input_dismissed", submitted, text)
	
func _on_get_auth_session_ticket_response(auth_id, result):
	if result == 1:
		emit_signal("ticket_ready")
	else:
		emit_signal("ticket_failed", result)
	
func get_avatar() -> Texture:
	var img_handle = Steam.getMediumFriendAvatar(Steam.getSteamID())
	var size = Steam.getImageSize(img_handle)
	var buffer = Steam.getImageRGBA(img_handle).buffer
	var avatar_image = Image.new()
	var avatar_texture = ImageTexture.new()
	avatar_image.create(size.width, size.height, false, Image.FORMAT_RGBAF)
	
	avatar_image.lock()
	
	for y in range(size.height):
		for x in range(size.width):
			var pixel = 4 * (x + y * size.height)
			var r = float(buffer[pixel]) / 255.0
			var g = float(buffer[pixel+1]) / 255.0
			var b = float(buffer[pixel+2]) / 255.0
			var a = float(buffer[pixel+3]) / 255.0
			avatar_image.set_pixel(x, y, Color(r, g, b, a))
	avatar_image.unlock()
	avatar_texture.create_from_image(avatar_image)
	return avatar_texture
func init_platform() -> int:
	if Engine.has_singleton("Steam"):

		var init = Steam.steamInit()
		
		Log.log(self, init.verbal)
		if init.status != 1:
			return init.status
		
		friendly_username = Steam.getPersonaName()
		user_id = Steam.getSteamID()
		multiplayer_provider = SteamMultiplayerService.new()
		multiplayer_provider.connect("lobby_join_requested", self, "_on_lobby_join_requested")
		leaderboard_provider = SteamLeaderboardService.new()
		ugc_provider = SteamUGCService.new()
		
		.init_platform()
		
		return OK
	else:
		Log.log(self, "Engine was not built with Steam support, aborting...")
		return ERR_METHOD_NOT_FOUND
		
var MainMenu = load("res://menus/MainMenu3D.tscn")
		
func _on_lobby_join_requested(lobby: HBLobby):
	lobby.join_lobby()
	lobby.connect("lobby_joined", self, "_on_lobby_joined_from_invite", [lobby])
func _on_lobby_joined_from_invite(response, lobby: HBLobby):
	var args = { "lobby": lobby }
	
	if response == HBLobby.LOBBY_ENTER_RESPONSE.SUCCESS:
		if get_tree().current_scene is HBMainMenu:
			var menu: HBMainMenu = get_tree().current_scene
			menu._on_change_to_menu("lobby", false, args)
		else:
			var scene = MainMenu.instance()
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

func write_remote_file(file_name: String, data: PoolByteArray):
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
func write_remote_file_async(file_name: String, data: PoolByteArray):
	var thread = Thread.new()
	Log.log(self, "Writing to remote file (asynchronously): %s" % [file_name])	
	var result = thread.start(self, "_write_remote_file_async", {"file_name": file_name, "data": data, "thread": thread})
	if result != OK:
		Log.log(self, "Error starting thread for writing remote file: " + str(result), Log.LogLevel.ERROR)

# Write a file to remote
func write_remote_file_from_path(file_name: String, path: String):
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var buffer = file.get_buffer(file.get_len())
		var result = Steam.fileWrite(file_name, buffer, file.get_len())
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
	var file = File.new()
	if result.result:
		var err = file.open(target_path, File.WRITE)
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
	var ws := OS.window_size
	var height = ws.y
	var position_y = (height / 3.0) * 2.0
	var input_height = (height / 3.0)
	var type = Steam.FLOATING_GAMEPAD_TEXT_INPUT_MODE_SINGLE_LINE
	if multi_line:
		type = Steam.FLOATING_GAMEPAD_TEXT_INPUT_MODE_MULTIPLE_LINES
	return Steam.showFloatingGamepadTextInput(type, position_y, 0, ws.x, input_height)
