extends Node

const LOG_NAME = "YoutubeDL"

var YOUTUBE_DL_DIR = "user://youtube_dl"
var CACHE_FILE = "user://youtube_dl/cache/yt_cache.json"
const VIDEO_EXT = "mp4"
const AUDIO_EXT = "ogg"
enum YOUTUBE_DL_STATUS {
	READY,
	COPYING,
	FAILED
}

enum CACHE_STATUS {
	OK,
	MISSING,
	AUDIO_MISSING,
	VIDEO_MISSING
}

# Dictionary: song_id -> 
var tracked_video_downloads = {}

signal youtube_dl_status_updated

signal video_downloaded(id, result)
signal song_cached(song)
signal song_queued(song)
signal song_download_start(song)
signal song_caching_failed(song)

var cache_meta_mutex = Mutex.new()
var cache_meta: Dictionary = {
	"cache": {},
	"__version": 1
}
var status_mutex = Mutex.new()
var status = YOUTUBE_DL_STATUS.COPYING
var video_ids_being_cached = []
var caching_queue = []
const PROGRESS_THING = preload("res://autoloads/DownloadProgressThing.tscn")
# We use a fake user agent for privacy and to fool google drivez

var unused_cache_size := 0
var unused_video_ids := []

enum CACHING_STAGE {
	STARTING,
	DOWNLOADING_AUDIO,
	PROCESSING_AUDIO,
	DOWNLOADING_VIDEO,
}

var FLOATING_POINT_REGEX := RegEx.new()
var DOWNLOAD_REGEX := RegEx.new()

class CachingQueueEntry:
	var song: HBSong
	var variant: int
	var mutex := Mutex.new()
	## Download progress, [0.0-1.0], it's -1 if unknown
	var download_progress := -1.0
	var download_speed := 0.0
	## Download size in bytes, it's -1 if unknown
	var download_size := -1.0
	var caching_stage: int = CACHING_STAGE.STARTING
	var video_id: String

	var current_process: Process
	var aborted := false
	var thread: Thread
	signal download_progress_changed(download_progress, download_speed)
	var extension := ""

	func abort_download():
		mutex.lock()
		aborted = true
		if current_process:
			current_process.kill(true)
		mutex.unlock()
		
	func process_download_progress(process: Process):
		var lines := []
		
		while process.get_available_stdout_lines() > 0:
			lines.append(process.get_stdout_line())
		var progress_changed = false
		for i in range(lines.size()-1, -1, -1):
			var line := lines[i] as String
			if line.begins_with("PHD:"):
				var l := line.substr(4)
				l = l.strip_edges()
				var s := l.split("-")
				if s.size() == 5:
					var downloaded_bytes := s[0].to_int()
					var total_bytes := s[1].to_int()
					var total_bytes_estimate := s[2].to_int()
					var speed := s[3].to_int()
					if total_bytes == 0:
						# Guard against dividing by 0
						total_bytes = max(total_bytes_estimate, 1)
					mutex.lock()
					download_progress = downloaded_bytes/float(total_bytes)
					download_size = total_bytes
					download_speed = speed
					mutex.unlock()
					progress_changed = true
					if extension.is_empty():
						extension = s[4]
		if progress_changed:
			call_deferred("emit_signal", "download_progress_changed", download_progress, download_speed)

func _init():
	var compile_out := DOWNLOAD_REGEX.compile("PHD:([0-9]+)-([0-9]+)-([0-9]+)-([0-9]*\\.[0-9]+)")
	assert(compile_out == OK)
func _youtube_dl_updated(thread: Thread):
	thread.wait_to_finish()
	
	status_mutex.lock()
	Log.log(self, "YTDL READY: " + HBUtils.find_key(YOUTUBE_DL_STATUS, status))
	emit_signal("youtube_dl_status_updated")
	status_mutex.unlock()
func _update_youtube_dl(userdata):
	Log.log(self, "Updating YTDL...")
	var thread = userdata.thread
	var failed = false
	var dir = DirAccess.open("res://third_party/youtube_dl")
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir_name = dir.get_next()
		while dir_name != "":
			if not dir.current_is_dir():
				# We copy the version file last to prevent corrupted installs
				if dir_name != "VERSION":
					var result = dir.copy("res://third_party/youtube_dl/" + dir_name, YOUTUBE_DL_DIR + "/%s" % [dir_name])
					if result != OK:
						failed = true
						Log.log(self, "Error copying youtube-dl: " + str(result))
			dir_name = dir.get_next()
	var result = dir.copy("res://third_party/youtube_dl/" + "VERSION", YOUTUBE_DL_DIR + "/%s" % ["VERSION"])
	status_mutex.lock()
	if not failed and result == OK:
		status = YOUTUBE_DL_STATUS.READY
	else:
		status = YOUTUBE_DL_STATUS.FAILED
	status_mutex.unlock()
	
	ensure_perms()
	
	call_deferred("_youtube_dl_updated", thread)
func update_youtube_dl():
	var thread = Thread.new()
	var result = thread.start(Callable(self, "_update_youtube_dl").bind({"thread": thread}))
	if result != OK:
		Log.log(self, "Error starting thread for ytdl copy: " + str(result), Log.LogLevel.ERROR)
		
func get_cache_dir():
	return HBUtils.join_path(HBGame.content_dir, "youtube_dl/cache")
		
func _ready():
	pass
	
func ensure_perms():
	if OS.get_name() == "X11":
		# Ensure YTDL can be executed on linoox
		OS.execute("chmod", ["+x", get_ytdl_executable()])
		OS.execute("chmod", ["+x", get_ffmpeg_executable()])
		OS.execute("chmod", ["+x", get_ffprobe_executable()])
		OS.execute("chmod", ["+x", get_aria2_executable()])

func get_aria2_executable():
	var path
	if OS.get_name() == "Windows":
		path = YOUTUBE_DL_DIR + "/aria2c.exe"
	elif OS.get_name() == "X11":
		path = YOUTUBE_DL_DIR + "/aria2c"
	return ProjectSettings.globalize_path(path)

func _init_ytdl():
	YOUTUBE_DL_DIR = HBGame.platform_settings.user_dir_redirect(YOUTUBE_DL_DIR)
	CACHE_FILE = HBGame.platform_settings.user_dir_redirect(CACHE_FILE)
	
	clean_temp_folder()
	
	# A few versions ago we shipped certs with ytdl, but we don't do that anymore
	if not DirAccess.dir_exists_absolute(YOUTUBE_DL_DIR):
		DirAccess.make_dir_recursive_absolute(YOUTUBE_DL_DIR)
	if not DirAccess.dir_exists_absolute(get_cache_dir()):
		DirAccess.make_dir_recursive_absolute(get_cache_dir())
	if not DirAccess.dir_exists_absolute(CACHE_FILE.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(CACHE_FILE.get_base_dir())
	if FileAccess.file_exists(CACHE_FILE):
		var file = FileAccess.open(CACHE_FILE, FileAccess.READ)
		var test_json_conv = JSON.new()
		var err := test_json_conv.parse(file.get_as_text())
		if err == OK:
			cache_meta = test_json_conv.data
			for id in cache_meta.cache:
				if not cache_meta.cache[id] is Dictionary:
					cache_meta.cache[id] = {}
		else:
			Log.log(self, "Error loading cache meta: " + str(test_json_conv.get_error_message()))
	ensure_perms()
	if FileAccess.file_exists(YOUTUBE_DL_DIR + "/VERSION"):
		
		var file := FileAccess.open(YOUTUBE_DL_DIR + "/VERSION", FileAccess.READ)
		var local_version = int(file.get_as_text())
		Log.log(self, "Found youtube-dl version " + str(local_version))
		file.close()
		
		file = FileAccess.open("res://third_party/youtube_dl/VERSION", FileAccess.READ)
		var version = int(file.get_as_text())
		
		if version > local_version:
			update_youtube_dl()
		else:
			status = YOUTUBE_DL_STATUS.READY
			emit_signal("youtube_dl_status_updated")
	else:
		update_youtube_dl()
	
	var cache_dir := get_cache_dir() as String
	
	var d := DirAccess.open(cache_dir)
	if DirAccess.get_open_error() == OK:
		d.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var curr := d.get_next()
		while not curr.is_empty():
			var video_id := curr.get_file().get_basename()
			if curr.get_extension() in ["webm", "ogg", "mp4"]:
				if not video_id in cache_meta.cache:
					var f := FileAccess.open(cache_dir.path_join(curr), FileAccess.READ)
					if FileAccess.get_open_error() == OK:
						unused_cache_size += f.get_length()
						if not video_id in unused_video_ids:
							unused_video_ids.append(video_id)
					f.close()
			curr = d.get_next()

func save_cache():
	var video_cache_str := JSON.stringify(cache_meta, "  ")
	if video_cache_str:
		var file = FileAccess.open(CACHE_FILE, FileAccess.WRITE)
		file.store_string(video_cache_str)
	
func get_ytdl_executable():
	var path
	if OS.get_name() == "Windows":
		path = YOUTUBE_DL_DIR + "/youtube-dl.exe"
	elif OS.get_name() == "X11":
		path = YOUTUBE_DL_DIR + "/youtube-dl"
	return ProjectSettings.globalize_path(path)
func get_ffmpeg_executable():
	var path
	if OS.get_name() == "Windows":
		path = YOUTUBE_DL_DIR + "/ffmpeg.exe"
	elif OS.get_name() == "X11":
		path = YOUTUBE_DL_DIR + "/ffmpeg"
	return ProjectSettings.globalize_path(path)
func get_ffprobe_executable():
	var path
	if OS.get_name() == "Windows":
		path = YOUTUBE_DL_DIR + "/ffprobe.exe"
	elif OS.get_name() == "X11":
		path = YOUTUBE_DL_DIR + "/ffprobe"
	return ProjectSettings.globalize_path(path)


func get_video_path(video_id, global=false) -> String:
	var ext := "mp4"
	if video_id in cache_meta.cache:
		ext = cache_meta.cache[video_id].get("video_ext", "mp4")
	var path = get_cache_dir() + "/" + video_id + "." + ext
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
func get_audio_path(video_id, global=false, temp=false) -> String:
	var path = get_cache_dir() + "/" + video_id
	if temp:
		path += "_temp"
	path += ".ogg"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
	
func get_ytdl_error(process: Process) -> String:
	var error := "Unknown error"
	for _i in range(process.get_available_stderr_lines()):
		var line := process.get_stderr_line()
		if "ERROR:" in line:
			error = line
			break
	return error
	
func get_ytdl_shared_params(handle_temp_files := false):
	var shared_params = ["--ignore-config",
		"--no-cache-dir",
		"--force-ipv4",
		"--compat-options", "youtube-dl",
		"--no-part",
		"--newline",
		"--output-na-placeholder", "0",
		"--progress-template", "PHD:%(progress.downloaded_bytes)s-%(progress.total_bytes)s-%(progress.total_bytes_estimate)s-%(progress.speed)s-%(info.ext)s",
	]
	
	if handle_temp_files:
		shared_params.append_array([
			"-P", "temp:temp",
		])
		
		shared_params.append("-P")
		
		shared_params.append(ProjectSettings.globalize_path(get_cache_dir()))
	
	if OS.get_name() == "X11":
		shared_params += ["--ffmpeg-location", ProjectSettings.globalize_path(YOUTUBE_DL_DIR)]
	
	return shared_params

func cleanup_video_media(video_id: String, video := false, audio := false):
	var video_path := get_video_path(video_id, true)
	var audio_path_temp := get_audio_path(video_id, true, true)
	var audio_path := get_audio_path(video_id, true)
	
	var paths := []
	if video:
		paths.append(video_path)
	if audio:
		paths.append(audio_path)
		paths.append(audio_path_temp)
	
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func clean_temp_folder():
	HBUtils.remove_recursive(get_cache_dir().path_join("temp"))

func _download_video(userdata):
	var download_video = userdata.download_video
	var download_audio = userdata.download_audio
	if not userdata.video_id in cache_meta.cache:
		cache_meta_mutex.lock()
		cache_meta.cache[userdata.video_id] = {}
		cache_meta_mutex.unlock()
	var result = {"video_id": userdata.video_id, "song": userdata.song, "cache_entry": userdata.entry}
	var entry := userdata.entry as CachingQueueEntry
	# we have to ignroe the cache dir because youtube-dl is stupid
	var shared_params = get_ytdl_shared_params(true)
	var audio_download_ok = true
#	var audio_download_process: Process
#	var ffmpeg_process: Process
	if download_audio:
		# Step 1: Download audio
		var out_ffmpeg = []
		var temp_audio_path = "%(id)s_temp.%(ext)s"
		Log.log(self, "Start downloading audio for %s" % [userdata.video_id])
		var audio_params = ["-f", "bestaudio", "--extract-audio", "--audio-format", "vorbis", "-o", temp_audio_path, "https://youtu.be/" + userdata.video_id]
		
		entry.mutex.lock()
		if entry.aborted:
			entry.mutex.unlock()
			call_deferred("_video_downloaded", userdata.thread, result)
			return
		var audio_download_process := PHNative.create_process(get_ytdl_executable(), shared_params + audio_params)
		entry.caching_stage = CACHING_STAGE.DOWNLOADING_AUDIO
		entry.current_process = audio_download_process
		entry.mutex.unlock()
		
		while audio_download_process.get_exit_status() == -1:
			entry.process_download_progress(audio_download_process)
		
		var ytdl_error_code = audio_download_process.get_exit_status()
		
		# Audio download error checking
		if ytdl_error_code != OK:
			audio_download_ok = false
			result["audio"] = false
			result["audio_out"] = get_ytdl_error(audio_download_process)
		else:
			# Step 2: Audio conversion
			# We bring the ogg down back to stereo because godot is stupid and can't do selective channel playback
			entry.mutex.lock()
			if entry.aborted:
				entry.mutex.unlock()
				call_deferred("_video_downloaded", userdata.thread, result)
				return
			var input_path := "%s" % get_audio_path(userdata.video_id, true, true)
			var output_path := "%s" % get_audio_path(userdata.video_id, true)
			var ffmpeg_process := PHNative.create_process(get_ffmpeg_executable(), ["-nostdin", "-y", "-i", input_path, "-ac", "2", output_path])
			entry.caching_stage = CACHING_STAGE.PROCESSING_AUDIO
			entry.current_process = ffmpeg_process
			entry.mutex.unlock()
			
			while ffmpeg_process.get_exit_status() == -1:
				entry.process_download_progress(ffmpeg_process)
				
			DirAccess.remove_absolute(get_audio_path(userdata.video_id, true, true))
				
			var ffmpeg_error_code := ffmpeg_process.get_exit_status()
			
			# Audio conversion error handling
			if ffmpeg_error_code != OK:
				var stderr_lines := PackedStringArray()
				
				for _i in range(ffmpeg_process.get_available_stderr_lines()):
					stderr_lines.append(ffmpeg_process.get_stderr_line())
				
				result["audio_out"] = "".join(stderr_lines)
				result["audio"] = false
				audio_download_ok = false
			else:
				# Final step: Checking if the file that should exist actually exists
				if audio_exists(userdata.video_id):
					cache_meta_mutex.lock()
					cache_meta.cache[userdata.video_id]["audio"] = true
					cache_meta.cache[userdata.video_id]["audio_ext"] = AUDIO_EXT
					cache_meta_mutex.unlock()
				else:
					result["audio"] = false
					result["audio_out"] = "Unknown error"
					audio_download_ok = false
					
	if download_video and audio_download_ok:
		var video_height = UserSettings.user_settings.desired_video_resolution
		var video_fps = UserSettings.user_settings.desired_video_fps
		Log.log(self, "Start downloading video for %s" % [userdata.video_id])
		var video_params = [
			"-f", "bestvideo[vcodec!^=av01][height<=%d][fps<=%d]" % [video_height, video_fps], "-o", userdata.video_id + ".%(ext)s", "https://youtu.be/" + userdata.video_id,
			"--match-filter", "ext=mp4", "--match-filter", "ext=webm", "--force-overwrites"]
		
		entry.mutex.lock()
		if entry.aborted:
			entry.mutex.unlock()
			call_deferred("_video_downloaded", userdata.thread, result)
			return 
		var download_process := PHNative.create_process(get_ytdl_executable(), shared_params + video_params)
		entry.caching_stage = CACHING_STAGE.DOWNLOADING_VIDEO
		entry.current_process = download_process
		entry.download_progress = -1.0
		entry.download_size = -1.0
		entry.extension = ""
		entry.mutex.unlock()
		
		while download_process.get_exit_status() == -1:
			entry.process_download_progress(download_process)
		
		var exit_code := download_process.get_exit_status()

		if exit_code != OK or entry.extension.is_empty():
			result["video"] = false
			if exit_code != OK:
				result["video_out"] = get_ytdl_error(download_process)
			else:
				result["video_out"] = "Error obtaining downloaded video metadata despite succesful download, this is likely a bug, please report."
		else:
			result["video"] = true
			var video_path := get_video_path(userdata.video_id).get_basename() + "." + entry.extension
			if FileAccess.file_exists(video_path):
				cache_meta_mutex.lock()
				cache_meta.cache[userdata.video_id]["video"] = true
				cache_meta.cache[userdata.video_id]["video_ext"] = entry.extension
				cache_meta.cache[userdata.video_id]["video_fps"] = video_fps
				cache_meta.cache[userdata.video_id]["video_resolution"] = video_height
				cache_meta_mutex.unlock()
			else:
				result["video"] = false
				Log.log(self, "Error downloading video " + userdata.video_id + " ")
				result["video_out"] = "Unknown error (file not found after download)"
	Log.log(self, "Video download finish!")
	call_deferred("_video_downloaded", userdata.thread, result)
	
func show_error(output: String, message: String, song: HBSong):
	var progress_thing = PROGRESS_THING.instantiate()
	DownloadProgress.add_notification(progress_thing, true)
	progress_thing.type = HBDownloadProgressThing.TYPE.ERROR
	var error_message = output.split("\n")
	if error_message.size() > 1:
		# "error\n" <- potential trailing newline
		if error_message[-1] == "":
			error_message = error_message[-2]
		else:
			error_message = error_message[-1]
	else:
		error_message = output
	
	progress_thing.text = message.format({"song_title": song.get_visible_title(), "error_message": error_message})
	progress_thing.life_timer = 10.0
	
	# We log the whole output to disk just in case
	Log.log(self, message.format({"song_title": song.get_visible_title(), "error_message": output}), Log.LogLevel.ERROR)
	
func _video_downloaded(thread: Thread, result):
	if thread:
		thread.wait_to_finish()

	if not result.video_id in tracked_video_downloads:
		return

	video_ids_being_cached.erase(result.video_id)
	
	if video_ids_being_cached.size() == 0:
		clean_temp_folder()
	
	var has_error = false
	var current_song := tracked_video_downloads[result.video_id].song as HBSong
	var song = current_song
	if result.has("video"):
		if not result.video:
			has_error = true
			show_error(result.video_out, "Error downloading video for {song_title}. ({error_message})", current_song)
	if result.has("audio"):
		if not result.audio:
			has_error = true
			show_error(result.audio_out, "Error downloading audio for {song_title}. ({error_message})", current_song)
	if not has_error:
		var progress_thing = PROGRESS_THING.instantiate()
		DownloadProgress.add_notification(progress_thing, true)
		progress_thing.type = HBDownloadProgressThing.TYPE.SUCCESS
		progress_thing.text = "Finished downloading media for %s." % [tracked_video_downloads[result.video_id].song.get_visible_title()]
		progress_thing.life_timer = 5.0
	if result.video_id in tracked_video_downloads:
		DownloadProgress.remove_notification(tracked_video_downloads[result.video_id].progress_thing)
		tracked_video_downloads.erase(result.video_id)
	caching_queue.erase(result.cache_entry)
	if not has_error:
		song.emit_signal("song_cached")
		emit_signal("song_cached", song)
	else:
		emit_signal("song_caching_failed", song)
	process_queue()
	emit_signal("video_downloaded",  result.video_id, result)
	save_cache()
	
func video_exists(video_id):
	return FileAccess.file_exists(get_video_path(video_id))
func audio_exists(video_id):
	return FileAccess.file_exists(get_audio_path(video_id))
	
## Starts threaded video download immediately
func download_video(entry: CachingQueueEntry):
	var variant = entry.song.get_variant_data(entry.variant)
	var download_video = entry.song.use_youtube_for_video and not variant.audio_only
	var download_audio = entry.song.use_youtube_for_audio
	var song := entry.song
	var thread = Thread.new()
	var url = variant.variant_url
	var video_id = entry.video_id
	if video_id in video_ids_being_cached:
		Log.log(self, "We are already caching this: " + url)
		return
	if not video_id:
		Log.log(self, "Error parsing youtube url: " + url)
		return ERR_FILE_NOT_FOUND
		
	# Videos may still be downloaded if they are not on disk
	if video_id in cache_meta.cache:
		var all_found = true
		if download_audio:
			if not cache_meta.cache[video_id].has("audio") or not audio_exists(video_id):
				all_found = false
			elif download_audio:
				# No need to download what we already have
				download_audio = false
		if download_video:
			if not cache_meta.cache[video_id].has("video") or not video_exists(video_id):
				all_found = false
			elif download_video:
				# No need to download what we already have
				download_video = false
		if all_found:
			Log.log(self, "Already cached, no need to download again! (%s)" % [video_id])
			emit_signal("video_downloaded", video_id, {})
			if video_id in tracked_video_downloads:
				DownloadProgress.remove_notification(tracked_video_downloads[video_id].progress_thing, true)
				tracked_video_downloads.erase(video_id)
			return ERR_ALREADY_EXISTS
	video_ids_being_cached.append(video_id)
	emit_signal("song_download_start", song)
	var result = thread.start(Callable(self, "_download_video").bind({"thread": thread, "video_id": video_id, "download_video": download_video, "download_audio": download_audio, "song": song, "entry": entry}))
	entry.thread = thread
	if result != OK:
		Log.log(self, "Error starting thread for ytdl download: " + str(result), Log.LogLevel.ERROR)
	
func get_video_id(url: String):
	var regex = RegEx.new()
	regex.compile("^.*(youtu\\.be\\/|v\\/|u\\/\\w\\/|embed\\/|watch\\?v=|\\&v=|\\/shorts\\/)([^#\\&\\?]*).*")
	var result = regex.search(url)
	if result:
		return result.get_string(2)
func validate_video_url(url):
	return get_video_id(url) != null

func get_cache_status(url: String, video=true, audio=true):
	var cache_status = CACHE_STATUS.OK
	cache_meta_mutex.lock()
	var yt_id = get_video_id(url)
	
	if yt_id in cache_meta.cache:
		if not cache_meta.cache[yt_id] is Dictionary:
			cache_meta.cache[yt_id] = {}
		var video_missing = false
		if video and (not cache_meta.cache[yt_id].has("video") or not video_exists(yt_id)):
			cache_status = CACHE_STATUS.VIDEO_MISSING
			video_missing = true
		var audio_missing = false
		if audio and (not cache_meta.cache[yt_id].has("audio") or not audio_exists(yt_id)):
			cache_status = CACHE_STATUS.AUDIO_MISSING
			audio_missing = true
		if video_missing and audio_missing:
			cache_status = CACHE_STATUS.MISSING
	else:
		cache_status = CACHE_STATUS.MISSING
	cache_meta_mutex.unlock()
	return cache_status

func cache_song(song: HBSong, variant := -1):
	var entry = CachingQueueEntry.new()
	entry.song = song
	entry.variant = variant
	var variant_data = song.get_variant_data(entry.variant)
	if validate_video_url(variant_data.variant_url):
		var video_id = get_video_id(variant_data.variant_url)
		entry.video_id = video_id
		caching_queue.append(entry)
		process_queue()
	else:
		var progress_thing = PROGRESS_THING.instantiate()
		DownloadProgress.add_notification(progress_thing)
		progress_thing.set_type(HBDownloadProgressThing.TYPE.ERROR)
		progress_thing.life_timer = 2.0
		progress_thing.text = "Downloading media for %s failed: Invalid URL" % [song.get_visible_title()]

func process_queue(offset := 0):
	if YoutubeDL.status != YoutubeDL.YOUTUBE_DL_STATUS.READY:
		await self.youtube_dl_status_updated
	if caching_queue.size() > offset:
		if tracked_video_downloads.size() >= UserSettings.user_settings.max_simultaneous_media_downloads:
			return
		var entry = caching_queue[offset]
		
		var song := entry.song as HBSong
		var variant = song.get_variant_data(entry.variant)
		
		if YoutubeDL.status == YoutubeDL.YOUTUBE_DL_STATUS.READY:
			var video_id = entry.video_id
			if video_id in video_ids_being_cached:
				process_queue(offset+1)
				return
			var result = download_video(entry)
			if result == ERR_ALREADY_EXISTS:
				caching_queue.remove_at(offset)
				var progress_thing = PROGRESS_THING.instantiate()
				DownloadProgress.add_notification(progress_thing, true)
				progress_thing.type = HBDownloadProgressThing.TYPE.SUCCESS
				progress_thing.text = "Finished downloading media for %s (Already downloaded)." % [song.get_visible_title()]
				progress_thing.life_timer = 5.0
				emit_signal("song_cached", entry)
				process_queue(offset)
				return
			if video_id in tracked_video_downloads:
				process_queue(offset+1)
				return
			
			var progress_thing = PROGRESS_THING.instantiate()
			DownloadProgress.add_notification(progress_thing)
			progress_thing.spinning = true
			progress_thing.set_type(HBDownloadProgressThing.TYPE.NORMAL)
			progress_thing.text = "Downloading media for %s" % [song.get_visible_title()]
			if entry.variant != -1:
				progress_thing.text += " (%s)" % [variant.variant_name]
			tracked_video_downloads[video_id] = {
				"progress_thing": progress_thing,
				"song": song,
				"entry": entry,
				"video_id": video_id
			}
			caching_queue.remove_at(offset)
			emit_signal("song_queued", entry)
			if tracked_video_downloads.size() < UserSettings.user_settings.max_simultaneous_media_downloads:
				process_queue(offset)
func _process(delta):
	for video_id in tracked_video_downloads:
		var entry := tracked_video_downloads[video_id].entry as CachingQueueEntry
		var progress_thing := tracked_video_downloads[video_id].progress_thing as HBDownloadProgressThing
		
		entry.mutex.lock()
		var progress_percentage := entry.download_progress
		var progress_size := entry.download_size
		var download_speed := entry.download_speed
		var stage := entry.caching_stage
		entry.mutex.unlock()
		
		var prev_stage := tracked_video_downloads[video_id].get("last_caching_stage", CACHING_STAGE.STARTING) as int
		if prev_stage != stage:
			if stage == CACHING_STAGE.PROCESSING_AUDIO:
				var dl_str := tr("Processing audio for %s") % [entry.song.get_visible_title()]
				progress_thing.text = dl_str
		
		if stage != CACHING_STAGE.STARTING and stage != CACHING_STAGE.PROCESSING_AUDIO:
			var last_download_progres := tracked_video_downloads[video_id].get("last_download_progress", -1) as float
			if last_download_progres != progress_percentage and progress_percentage != -1.0:
				tracked_video_downloads[video_id]["last_download_progress"] = last_download_progres
				var format_info := {
					"song_title": entry.song.get_visible_title(),
					"download_type": tr("audio"),
					"percentage": "%.2f%%" % [progress_percentage * 100.0],
					"size": "",
					"speed": ""
				}

				if stage == CACHING_STAGE.DOWNLOADING_VIDEO:
					format_info.download_type = tr("video")

				if progress_size != -1.0:
					format_info["size"] = tr(" of %s") % ["".humanize_size(progress_size)]
				if download_speed > 0:
					format_info["speed"] = tr(" at %s/s" % ["".humanize_size(download_speed)])
				var dl_str := tr("Downloading {download_type} for {song_title} ({percentage}{size}{speed})").format(format_info)
				progress_thing.text = dl_str
				progress_thing.set_progress(progress_percentage)
		tracked_video_downloads[video_id]["last_caching_stage"] = stage
func is_already_downloading(song, variant := -1):
	var in_queue = false
	for entry in caching_queue:
		if entry.song == song and entry.variant == variant:
			in_queue = true
			break
	return get_video_id(song.get_variant_data(variant).variant_url) in video_ids_being_cached or in_queue

func cancel_song_download(entry: CachingQueueEntry):
	var variant_data := entry.song.get_variant_data(entry.variant) as HBSongVariantData
	if not entry.video_id in video_ids_being_cached:
		if entry in caching_queue:
			caching_queue.erase(entry)
	else:
		var download_data := tracked_video_downloads.get(get_video_id(variant_data.variant_url), {}) as Dictionary
		if not download_data.is_empty():
			tracked_video_downloads.erase(entry.video_id)
			video_ids_being_cached.erase(entry.video_id)
			entry.abort_download()
		var video = entry.song.use_youtube_for_video and not variant_data.audio_only
		var audio = entry.song.use_youtube_for_audio
		
		if tracked_video_downloads.size() == 0:
			clean_temp_folder()
		
		cleanup_video_media(entry.video_id, video, audio)
		
		DownloadProgress.remove_notification(download_data.progress_thing, true)
		process_queue()
		
func get_video_info_json(video_url: String):
	var shared_params = get_ytdl_shared_params()
	shared_params += ["--dump-json", video_url]
	var cmd_out = []
	var err = OS.execute(get_ytdl_executable(), shared_params, cmd_out, true)
	var out_dict = {}
	if err == OK:
		for line in cmd_out[0].split("\n"):
			var test_json_conv = JSON.new()
			var parse_err := test_json_conv.parse(line)
			if parse_err == OK:
				out_dict = test_json_conv.data
				break
	else:
		var error_str := "Unknown error"
		for out in cmd_out:
			var found_error := false
			for line in out.split("\n"):
				if line.begins_with("ERROR: "):
					var o := (line as String).split(": ")
					if o.size() > 2:
						error_str = o[2]
						found_error = true
						break
			if found_error:
				break
		out_dict = {"__error": error_str}
	
	return out_dict

func clear_unused_media():
	for video_id in unused_video_ids:
		cleanup_video_media(video_id)
	unused_cache_size = 0
	unused_video_ids.clear()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		for entry in caching_queue:
			entry.abort_download()
