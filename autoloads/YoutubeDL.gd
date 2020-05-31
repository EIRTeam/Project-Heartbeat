extends Node

const LOG_NAME = "YoutubeDL"

const YOUTUBE_DL_DIR = "user://youtube_dl"
const CACHE_FILE = "user://youtube_dl/cache/yt_cache.json"
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
var cache_meta_mutex = Mutex.new()
var cache_meta: Dictionary = {
	"cache": {},
	"__version": 1
}
var status_mutex = Mutex.new()
var status = YOUTUBE_DL_STATUS.COPYING
var songs_being_cached = []
var caching_queue = []
const PROGRESS_THING = preload("res://autoloads/DownloadProgressThing.tscn")
func _youtube_dl_updated(thread: Thread):
	thread.wait_to_finish()
	
	status_mutex.lock()
	Log.log(self, "YTDL READY: " + HBUtils.find_key(YOUTUBE_DL_STATUS, status))
	emit_signal("youtube_dl_status_updated")
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
		
func get_cache_dir():
	return HBUtils.join_path(UserSettings.user_settings.content_path, "youtube_dl/cache")
		
func _ready():
	var dir = Directory.new()
	if not dir.dir_exists(YOUTUBE_DL_DIR):
		dir.make_dir(YOUTUBE_DL_DIR)
	if not dir.dir_exists(get_cache_dir()):
		dir.make_dir(get_cache_dir())
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
		OS.execute("chmod", ["+x", get_ffmpeg_executable()], true)
		OS.execute("chmod", ["+x", get_ffprobe_executable()], true)
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
			status = YOUTUBE_DL_STATUS.READY
			emit_signal("youtube_dl_status_updated")
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
func get_video_path(video_id, global=false):
	var path = get_cache_dir() + "/" + video_id + ".mp4"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
func get_audio_path(video_id, global=false, temp=false):
	var path = get_cache_dir() + "/" + video_id
	if temp:
		path += "_temp"
	path += ".ogg"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
func _download_video(userdata):
	var download_video = userdata.download_video
	var download_audio = userdata.download_audio
	if not userdata.video_id in cache_meta.cache:
		cache_meta.cache[userdata.video_id] = {}
	var result = {"video_id": userdata.video_id}
	# we have to ignroe the cache dir because youtube-dl is stupid
	var shared_params = ["--ignore-config", "--no-cache-dir", ]
	
	if download_audio:
		var out = []
		var temp_audio_path = get_audio_path(userdata.video_id, true, true).get_base_dir() + "/" + "%(id)s_temp.%(ext)s"
		Log.log(self, "Start downloading audio for %s" % [userdata.video_id])
		var audio_params = ["-f", "bestaudio", "--extract-audio", "--audio-format", "vorbis", "-o", temp_audio_path, "https://youtu.be/" + userdata.video_id]
		OS.execute(get_ytdl_executable(), shared_params + audio_params, true, out)
		# We bring the ogg down back to stereo because godot is stupid and can't do selective channel playback
		OS.execute(get_ffmpeg_executable(), ["-y", "-i", get_audio_path(userdata.video_id, true, true), "-ac", "2", get_audio_path(userdata.video_id, true)], true, out)
		print("ffmpeg output", out)
		var dir = Directory.new()
		dir.remove(get_audio_path(userdata.video_id, true, true))
		result["audio"] = true
		result["audio_out"] = out[-1]
		
		if audio_exists(userdata.video_id):
			cache_meta_mutex.lock()
			cache_meta.cache[userdata.video_id]["audio"] = true
			cache_meta.cache[userdata.video_id]["audio_ext"] = AUDIO_EXT
			cache_meta_mutex.unlock()
		else:
			result["audio"] = false
			Log.log(self, "Error downloading audio " + userdata.video_id)
			for line in out:
				print(line)
	if download_video:
		var out = []
		var video_height = UserSettings.user_settings.desired_video_resolution
		var video_fps = UserSettings.user_settings.desired_video_fps
		Log.log(self, "Start downloading video for %s" % [userdata.video_id])
		var video_params = ["-f", "bestvideo[ext=mp4][vcodec^=avc1][height<=%d][fps<=%d]" % [video_height, video_fps], "-o", get_video_path(userdata.video_id, true), "https://youtu.be/" + userdata.video_id]
		OS.execute(get_ytdl_executable(), shared_params + video_params, true, out)
		result["video"] = true
		result["video_out"] = out[-1]
		if video_exists(userdata.video_id):
			cache_meta_mutex.lock()
			cache_meta.cache[userdata.video_id]["video"] = true
			cache_meta.cache[userdata.video_id]["video_ext"] = VIDEO_EXT
			cache_meta.cache[userdata.video_id]["video_fps"] = video_fps
			cache_meta.cache[userdata.video_id]["video_resolution"] = video_height
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
	var has_error = false
	if result.has("video"):
		if not result.video:
			has_error = true
	if result.has("audio"):
		if not result.audio:
			has_error = true
	if has_error:
		var progress_thing = PROGRESS_THING.instance()
		DownloadProgress.add_notification(progress_thing, true)
		progress_thing.type = HBDownloadProgressThing.TYPE.ERROR
		progress_thing.text = "Error downloading media for %s." % [tracked_video_downloads[result.video_id].song.get_visible_title()]
		progress_thing.life_timer = 2
	else:
		var progress_thing = PROGRESS_THING.instance()
		DownloadProgress.add_notification(progress_thing, true)
		progress_thing.type = HBDownloadProgressThing.TYPE.SUCCESS
		progress_thing.text = "Finished downloading media for %s." % [tracked_video_downloads[result.video_id].song.get_visible_title()]
		progress_thing.life_timer = 2
	if result.video_id in tracked_video_downloads:
		DownloadProgress.remove_notification(tracked_video_downloads[result.video_id].progress_thing)
		tracked_video_downloads.erase(result.video_id)
	for song in caching_queue:
		if get_video_id(song.youtube_url) == result.video_id:
			caching_queue.erase(song)
			break
	if caching_queue.size() > 0:
		cache_song(caching_queue[0])
	emit_signal("video_downloaded", result.video_id, result)
	
func video_exists(video_id):
	var file = File.new()
	return file.file_exists(get_video_path(video_id))
func audio_exists(video_id):
	var file = File.new()
	return file.file_exists(get_audio_path(video_id))
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
			Log.log(self, "Already cached, no need to download again")
			emit_signal("video_downloaded", video_id)
			if video_id in tracked_video_downloads:
				DownloadProgress.remove_notification(tracked_video_downloads[video_id].progress_thing, true)
				tracked_video_downloads.erase(video_id)
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

func validate_video_url(url):
	return get_video_id(url) != null

func get_cache_status(url: String, video=true, audio=true):
	var cache_status = CACHE_STATUS.OK
	cache_meta_mutex.lock()
	var yt_id = get_video_id(url)
	
	if yt_id in cache_meta.cache:
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

func cache_song(song: HBSong):
	if YoutubeDL.status != YoutubeDL.YOUTUBE_DL_STATUS.READY:
		yield(self, "youtube_dl_status_updated")
	if not song in caching_queue:
		caching_queue.append(song)
	if caching_queue[0] == song:
		if YoutubeDL.status == YoutubeDL.YOUTUBE_DL_STATUS.READY:
			var video_url_ok = validate_video_url(song.youtube_url)
			if video_url_ok:
				var video_id = get_video_id(song.youtube_url)
				if not video_id in songs_being_cached:
					var result = download_video(song.youtube_url, song.use_youtube_for_video and song.has_video_enabled(), song.use_youtube_for_audio)
					if not video_id in tracked_video_downloads:
						var progress_thing = PROGRESS_THING.instance()
						DownloadProgress.add_notification(progress_thing)
						progress_thing.spinning = true
						progress_thing.set_type(HBDownloadProgressThing.TYPE.NORMAL)
						progress_thing.text = "Downloading media for %s" % [song.get_visible_title()]
						tracked_video_downloads[video_id] = {
							"progress_thing": progress_thing,
							"song": song
						}
					return result
			else:
				var progress_thing = PROGRESS_THING.instance()
				DownloadProgress.add_notification(progress_thing)
				progress_thing.set_type(HBDownloadProgressThing.TYPE.ERROR)
				progress_thing.life_timer = 2.0
				progress_thing.text = "Downloading media for %s failed: Invalid URL" % [song.get_visible_title()]
			
func is_already_downloading(song):
	return get_video_id(song.youtube_url) in songs_being_cached or song in caching_queue
