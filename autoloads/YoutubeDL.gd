extends Node

const LOG_NAME = "YoutubeDL"

const YOUTUBE_DL_DIR = "user://youtube_dl"
const CACHE_DIR = "user://youtube_dl/cache"
const CACHE_FILE = "user://youtube_dl/cache/cache.json"
enum YOUTUBE_DL_STATUS {
	READY,
	COPYING,
	FAILED
}

signal youtube_dl_ready

signal video_downloaded(id, result)
var cache_meta_mutex = Mutex.new()
var cache_meta: Dictionary = {}
var status_mutex = Mutex.new()
var status = YOUTUBE_DL_STATUS.COPYING
var songs_being_cached = []

func _youtube_dl_updated(thread: Thread):
	thread.wait_to_finish()
	emit_signal("youtube_dl_ready")
	status_mutex.lock()
	Log.log(self, "YTDL READY: " + HBUtils.find_key(YOUTUBE_DL_STATUS, status))
	status_mutex.unlock()
func _update_youtube_dl(userdata):
	Log.log(self, "Updating YTDL...")
	var thread = userdata.thread
	var dir = Directory.new()
	var failed = false
	if dir.open("res://third_party/youtube_dl") == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()
		while dir_name != "":
			if not dir.current_is_dir():
				var result = dir.copy("res://third_party/youtube_dl/" + dir_name, YOUTUBE_DL_DIR + "/%s" % [dir_name])
				if result != OK:
					failed = true
					Log.log(self, "Error copying youtube-dl: " + str(result))
			dir_name = dir.get_next()
	status_mutex.lock()
	if not failed:
		status = YOUTUBE_DL_STATUS.READY
	else:
		status = YOUTUBE_DL_STATUS.FAILED
	status_mutex.unlock()
	call_deferred("_youtube_dl_updated", thread)
func update_youtube_dl():
	var thread = Thread.new()
	var result = thread.start(self, "_update_youtube_dl", {"thread": thread})
	if result != OK:
		Log.log(self, "Error starting thread for ytdl copy: " + str(result), Log.LogLevel.ERROR)
func _ready():
	var dir = Directory.new()
	if not dir.dir_exists(YOUTUBE_DL_DIR):
		dir.make_dir(YOUTUBE_DL_DIR)
	if not dir.dir_exists(CACHE_DIR):
		dir.make_dir(CACHE_DIR)
	if dir.file_exists(CACHE_FILE):
		var file = File.new()
		file.open(CACHE_FILE, File.READ)
		var json = JSON.parse(file.get_as_text()) as JSONParseResult
		if json.error == OK:
			cache_meta = json.result
		else:
			Log.log(self, "Error loading cache meta: " + str(json.error))
	if OS.get_name() == "X11":
		# Ensure YTDL can be executed on linoox
		OS.execute("chmod", ["+x", get_ytdl_executable()], true)
	if dir.file_exists(YOUTUBE_DL_DIR + "/VERSION"):
		
		var file = File.new()
		file.open(YOUTUBE_DL_DIR + "/VERSION", File.READ)
		var local_version = int(file.get_as_text())
		Log.log(self, "Found youtube-dl version " + str(local_version))
		file.close()
		
		file.open("res://third_party/youtube_dl/VERSION", File.READ)
		var version = int(file.get_as_text())
		
		if version > local_version:
			update_youtube_dl()
	else:
		update_youtube_dl()
#	download_video("https://www.youtube.com/watch?v=0jgrCKhxE1s")
func ytdl_download():
	pass

func save_cache():
	var file = File.new()
	file.open(CACHE_FILE, File.WRITE)
	file.store_string(JSON.print(cache_meta, "  "))
	
func get_ytdl_executable():
	var path
	if OS.get_name() == "Windows":
		path = YOUTUBE_DL_DIR + "/youtube-dl.exe"
	elif OS.get_name() == "X11":
		path = YOUTUBE_DL_DIR + "/youtube-dl"
	return ProjectSettings.globalize_path(path)
func get_video_path(video_id, global=false):
	var path = CACHE_DIR + "/" + video_id + ".mp4"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
func get_audio_path(video_id, global=false):
	var path = CACHE_DIR + "/" + video_id + ".ogg"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
func _download_video(userdata):
	var download_video = userdata.download_video
	var download_audio = userdata.download_audio
	var file := File.new()
	if not userdata.video_id in cache_meta:
		cache_meta[userdata.video_id] = {}
	var result = {"video_id": userdata.video_id}
	if download_audio:
		var out = []
		var audio_path = get_audio_path(userdata.video_id, true).get_base_dir() + "/" + "%(id)s.%(ext)s"
		OS.execute(get_ytdl_executable(), ["--ignore-config", "-f", "bestaudio[acodec=opus]", "--extract-audio", "--audio-format", "vorbis", "-o", audio_path, "https://youtu.be/" + userdata.video_id], true, out)
		result["audio"] = true
		result["audio_out"] = out[-1]
		
		if file.file_exists(get_audio_path(userdata.video_id)):
			cache_meta_mutex.lock()
			cache_meta[userdata.video_id]["audio"] = true
			cache_meta_mutex.unlock()
		else:
			result["audio"] = false
			Log.log(self, "Error downloading audio " + userdata.video_id)
			for line in out:
				print(line)
	if download_video:
		var out = []
		
		OS.execute(get_ytdl_executable(), ["--ignore-config", "-f", "bestvideo[container=mp4,height<=1080]", "-o", get_video_path(userdata.video_id, true), "https://youtu.be/" + userdata.video_id], true, out)
		result["video"] = true
		result["video_out"] = out[-1]
		if file.file_exists(get_video_path(userdata.video_id)):
			cache_meta_mutex.lock()
			cache_meta[userdata.video_id]["video"] = true
			cache_meta_mutex.unlock()
		else:
			result["video"] = false
			Log.log(self, "Error downloading video " + userdata.video_id + " ")
			for line in out:
				print(line)
	Log.log(self, "Video download finish!")
	call_deferred("_video_downloaded", userdata.thread, result)
	save_cache()
	
func _video_downloaded(thread: Thread, result):
	thread.wait_to_finish()
	songs_being_cached.erase(result.video_id)
	emit_signal("video_downloaded", result.video_id, result)
	
func download_video(url: String, download_video = true, download_audio = true):
	var thread = Thread.new()
	var video_id = get_video_id(url)
	if video_id in songs_being_cached:
		Log.log(self, "We are already caching this: " + url)
		return
	if not video_id:
		Log.log(self, "Error parsing youtube url: " + url)
		return ERR_FILE_NOT_FOUND
		
	songs_being_cached.append(video_id)

		
	if video_id in cache_meta:
		var all_found = true
		if download_audio:
			if not cache_meta[video_id].has("audio"):
				all_found = false
		if download_video:
			if not cache_meta[video_id].has("video"):
				all_found = false
		if all_found:
			Log.log(self, "Already cached, no need to download again")
			emit_signal("video_downloaded", video_id)
			songs_being_cached.erase(video_id)
			return
	var result = thread.start(self, "_download_video", {"thread": thread, "video_id": video_id, "download_video": download_video, "download_audio": download_audio})
	if result != OK:
		Log.log(self, "Error starting thread for ytdl download: " + str(result), Log.LogLevel.ERROR)
	
func get_video_id(url: String):
	var regex = RegEx.new()
	regex.compile("^.*(youtu\\.be\\/|v\\/|u\\/\\w\\/|embed\\/|watch\\?v=|\\&v=)([^#\\&\\?]*).*")
	var result = regex.search(url)
	if result:
		return result.get_string(2)

func is_cached(url: String, video=true, audio=true):
	var cached = true
	cache_meta_mutex.lock()
	var yt_id = get_video_id(url)
	
	if yt_id in cache_meta:
		if video and not cache_meta[yt_id].has("video"):
			cached = false
		if audio and not cache_meta[yt_id].has("audio"):
			cached = false
	else:
		cached = false
	cache_meta_mutex.unlock()
	return cached
