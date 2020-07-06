extends PlatformServiceProvider

const LOG_NAME = "SteamServiceProvider"

func _init():
	implements_lobby_list = true
	implements_leaderboards = true
	implements_ugc = true
func init_platform() -> int:
	if Engine.has_singleton("Steam"):

		var init = Steam.steamInit()
		
		Log.log(self, init.verbal)
		if init.status != 1:
			return init.status
		
		friendly_username = Steam.getPersonaName()
		user_id = Steam.getSteamID()
		multiplayer_provider = SteamMultiplayerService.new()
		leaderboard_provider = SteamLeaderboardService.new()
		ugc_provider = SteamUGCService.new()
		
		.init_platform()
		
		return OK
	else:
		Log.log(self, "Engine was not built with Steam support, aborting...")
		return ERR_METHOD_NOT_FOUND
func run_callbacks():
	Steam.run_callbacks()
	emit_signal("run_mp_callbacks")

# TODO
func get_achivements():
	pass

func write_remote_file(file_name: String, data: PoolByteArray):
	Log.log(self, "Writing to remote file: %s" % [file_name])
	return Steam.fileWrite(file_name, data, data.size())

func _write_remote_file_async(userdata):
	var result = Steam.fileWrite(userdata.file_name, userdata.data, userdata.data.size())
	if result:
		Log.log(self, "Wrote succesfully to remote file (asynchronously): %s" % [userdata.file_name])
	userdata.thread.call_deferred("wait_to_finish")
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
