extends Node

const LOG_NAME = "YoutubeDL"

var YOUTUBE_DL_DIR = "user://youtube_dl"
var CACHE_FILE = "user://youtube_dl/cache/yt_cache.json"
const VIDEO_EXT = "webm"
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
# We use a fake user agent for privacy and to fool google drivez
const USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:94.0) Gecko/20100101 Firefox/94.0"

var unused_cache_size := 0
var unused_video_ids := []

class CachingQueueEntry:
	var mutex := Mutex.new()
	var song: HBSong
	var variant: int
	var range_downloader := HBHTTPRangeDownloader.new()
	var dash_estimated_size := 0
	var step_count := 0
	var current_step := 0
	var step_description := ""
	
	func get_downloaded_bytes():
		if range_downloader.state != HBHTTPRangeDownloader.STATE.STATE_READY:
			if dash_estimated_size != 0:
				return range_downloader.get_dash_downloaded_bytes()
			else:
				return range_downloader.get_downloaded_bytes()
		else:
			return -1
	
	func get_total_bytes():
		if range_downloader.state != HBHTTPRangeDownloader.STATE.STATE_READY:
			if dash_estimated_size != 0:
				return dash_estimated_size
			else:
				return range_downloader.get_download_size()
		else:
			return -1

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
	var result = thread.start(self, "_update_youtube_dl", {"thread": thread})
	if result != OK:
		Log.log(self, "Error starting thread for ytdl copy: " + str(result), Log.LogLevel.ERROR)
		
func get_cache_dir():
	return HBUtils.join_path(HBGame.content_dir, "youtube_dl/cache")
		
func _ready():
	pass
	
func ensure_perms():
	if OS.get_name() == "X11":
		# Ensure YTDL can be executed on linoox
		OS.execute("chmod", ["+x", get_ytdl_executable()], true)
		OS.execute("chmod", ["+x", get_ffmpeg_executable()], true)
		OS.execute("chmod", ["+x", get_ffprobe_executable()], true)
		OS.execute("chmod", ["+x", get_aria2_executable()], true)

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
	var dir = Directory.new()
	# A few versions ago we shipped certs with ytdl, but we don't do that anymore
	var old_cert_file = YOUTUBE_DL_DIR + "/ca-certificates.crt"
	if dir.file_exists(old_cert_file):
		dir.remove(old_cert_file)
	if not dir.dir_exists(YOUTUBE_DL_DIR):
		dir.make_dir(YOUTUBE_DL_DIR)
	if not dir.dir_exists(get_cache_dir()):
		dir.make_dir_recursive(get_cache_dir())
		print("MAKING!!!!", get_cache_dir())
	if not dir.dir_exists(CACHE_FILE.get_base_dir()):
		dir.make_dir(CACHE_FILE.get_base_dir())
	if dir.file_exists(CACHE_FILE):
		var file = File.new()
		file.open(CACHE_FILE, File.READ)
		var json = JSON.parse(file.get_as_text()) as JSONParseResult
		if json.error == OK:
			cache_meta = json.result
			# We remove invalid cache states
			# if the lock file is still there
			# this probably means the download got cut halfway
			for video_id in cache_meta.get("cache", []):
				if is_video_locked(video_id):
					clean_up_files(video_id)
					unlock_video(video_id)
					(cache_meta.cache as Dictionary).erase(video_id)
		else:
			Log.log(self, "Error loading cache meta: " + str(json.error))
	ensure_perms()
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
	
	var d := Directory.new()
	var cache_dir := get_cache_dir() as String
	
	if d.open(cache_dir) == OK:
		d.list_dir_begin(true)
		var curr := d.get_next()
		var f := File.new()
		while not curr.empty():
			var video_id := curr.get_file().get_basename()
			if curr.get_extension() in ["webm", "ogg"]:
				if not video_id in cache_meta.cache:
					if f.open(cache_dir.plus_file(curr), File.READ) == OK:
						unused_cache_size += f.get_len()
						if not video_id in unused_video_ids:
							unused_video_ids.append(video_id)
					f.close()
			curr = d.get_next()

func save_cache():
	var file = File.new()
	var video_cache_str := JSON.print(cache_meta, "  ")
	if video_cache_str:
		file.open(CACHE_FILE, File.WRITE)
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


func get_video_path(video_id, global=false):
	var path = get_cache_dir() + "/" + video_id + ".webm"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
	
func get_video_lock_path(video_id: String) -> String:
	return get_cache_dir() + "/%s.lock" % video_id
	
func is_video_locked(video_id: String):
	var f := File.new()
	return f.file_exists(get_video_lock_path(video_id))
	
func lock_video_id(video_id: String):
	var f := File.new()
	assert(!is_video_locked(video_id))
	f.open(get_video_lock_path(video_id), File.WRITE)
	
func unlock_video(video_id: String):
	assert(is_video_locked(video_id))
	var f := Directory.new()
	f.remove(get_video_lock_path(video_id))
	
func get_audio_path(video_id, global=false, temp=false):
	var path = get_cache_dir() + "/" + video_id
	if temp:
		path += "_temp"
	path += ".ogg"
	if global:
		path = ProjectSettings.globalize_path(path)
	return path
	
func get_ytdl_shared_params(downloader := false):
	var shared_params = ["--ignore-config",
	"--no-cache-dir",
	"--force-ipv4",
	"--compat-options", "youtube-dl",
	"--user-agent", USER_AGENT,
	# aria2 seems good at preventing throttling from Niconico
	]
	if downloader:
		shared_params.append_array(
			["--external-downloader", YoutubeDL.get_aria2_executable(),
			"--external-downloader-args", "--disable-ipv6 --user-agent '%s'" % [USER_AGENT]
			])
	
	if OS.get_name() == "X11":
		shared_params += ["--ffmpeg-location", ProjectSettings.globalize_path(YOUTUBE_DL_DIR)]
	
	return shared_params
	
# Builds headers from a format JSON
func _build_headers(data: Dictionary) -> Array:
	# Grab the headers from the JSON
	var headers := []
	
	var json_headers = data.get("http_headers", {})
	
	for header_name in json_headers:
		var header_content = json_headers[header_name]
		headers.append("%s: %s" % [header_name, header_content])
	
	return headers
	
func clean_up_temp_files(video_id: String):
	var temp_audio_file := get_audio_path(video_id, false, true) as String
	var f := Directory.new()
	if f.file_exists(temp_audio_file):
		var err = f.remove(temp_audio_file)
		if err != OK:
			push_error("Error deleting file %s" % [temp_audio_file])
			
func clean_up_files(video_id: String):
	clean_up_temp_files(video_id)
	var files_to_clean_up := [
		get_video_path(video_id),
		get_audio_path(video_id)
	]
	
	var f := Directory.new()
	for file in files_to_clean_up:
		if f.file_exists(file):
			var err := f.remove(file)
			if err != OK:
				push_error("Error deleting file %s" % [file])
	
func _download_video(userdata):
	var download_video = userdata.download_video
	var download_audio = userdata.download_audio
	if not userdata.video_id in cache_meta.cache:
		cache_meta_mutex.lock()
		cache_meta.cache[userdata.video_id] = {}
		cache_meta_mutex.unlock()
	var result = {"video_id": userdata.video_id, "song": userdata.song, "cache_entry": userdata.entry}
	# we have to ignroe the cache dir because youtube-dl is stupid
	var audio_download_ok = true
	
	var steps = 1 # Step 1 is meta download
	if download_audio:
		# Audio has two steps, one for ffmpeg
		steps += 2
	if download_video:
		steps += 1

	var entry: CachingQueueEntry = userdata.entry

	entry.mutex.lock()
	entry.step_count = steps
	entry.step_description = tr("Downloading metadata")
	entry.mutex.unlock()
	
	var format_info := get_video_info_json("https://youtu.be/" + userdata.video_id)

	if format_info.has("__error"):
		if download_video:
			result["video"] = false
			result["video_out"] = format_info.__error
		else:
			result["audio"] =  false
			result["audio_out"] = format_info.__error
		download_audio = false
		download_video = false

	var formats := format_info.get("formats", []) as Array
	
	if download_audio:
		var highest_abr := 0
		var highest_abr_i := -1
		# Find highest quality audio using average bit rate
		for i in range(formats.size()):
			var format := formats[i] as Dictionary
			if format.get("vcodec", "") == "none" and \
					not format.get("format_note", "") == "DASH audio" and \
					format.get("audio_ext", "") in ["webm", "ogg", "ogv", "m4a"] and \
					format.get("abr", 0) > highest_abr:
				highest_abr = format.get("abr", 0)
				highest_abr_i = i
		if highest_abr_i != -1:
			var chosen_format := formats[highest_abr_i] as Dictionary
			var download_url := chosen_format.get("url", "") as String
			var chunk_size := chosen_format.get("downloader_options", {}).get("http_chunk_size", 1024) as int
			
			var headers := _build_headers(chosen_format)
			
			entry.mutex.lock()
			entry.current_step += 1
			entry.step_description = tr("Downloading audio")
			entry.mutex.unlock()
		
			var temp_audio_path := get_audio_path(userdata.video_id, false, true) as String
		
			var range_downloader := entry.range_downloader as HBHTTPRangeDownloader
			range_downloader.download(download_url, temp_audio_path, chunk_size, headers)
			# Don't even think about using yield() here, it will make the execution resume on the main
			# thread which is very very bad and terrible and grrr i hate godot
			while range_downloader.state == HBHTTPRangeDownloader.STATE.STATE_BUSY:
				OS.delay_msec(50)
			if range_downloader.has_error():
				audio_download_ok = false
				result["audio"] = false
				result["audio_out"] = range_downloader.get_error_string()
				print(result["audio_out"])
			else:
				entry.mutex.lock()
				entry.current_step += 1
				entry.step_description = tr("Processing audio")
				entry.mutex.unlock()
				var ff_out := []
				# Convert audio to vorbis ogg
				var ffmpeg_args := ["-i", get_audio_path(userdata.video_id, true, true), "-c:a", "libvorbis", get_audio_path(userdata.video_id, true, false)]

				var ffmpeg_result =  OS.execute(get_ffmpeg_executable(), ffmpeg_args, true, ff_out, true)
				
				if ffmpeg_result != OK:
					audio_download_ok = false
					result["audio"] = false
					result["audio_out"] = tr("Unknown FFMPEG error")
					if ff_out.size() > 0:
						result["audio_out"] = ff_out[0]
					print(ff_out)
				elif audio_exists(userdata.video_id):
					cache_meta_mutex.lock()
					cache_meta.cache[userdata.video_id]["audio"] = true
					cache_meta.cache[userdata.video_id]["audio_ext"] = AUDIO_EXT
					cache_meta_mutex.unlock()
			
		else:
			audio_download_ok = false
			result["audio"] = false
			result["audio_out"] = tr("Couldn't find a suitable audio format")
				
	if download_video and audio_download_ok:
		var video_height = UserSettings.user_settings.desired_video_resolution
		var video_fps = UserSettings.user_settings.desired_video_fps
		Log.log(self, "Start downloading video for %s" % [userdata.video_id])
		
		var found_format_i := -1
		var closest_format_height := 0
		var closest_format_fps := 0
		
		for i in range(formats.size()):
			var format := formats[i] as Dictionary
			for allow_dash in [false, true]:
				if format.get("format_note", "") == "DASH video":
					if not allow_dash:
						continue
				if "vp9" in format.get("vcodec", "") and \
						format.get("video_ext", "") == "webm":
					var height := format.get("height", 0) as int
					var fps := format.get("fps", 0) as int
					
					if fps <= video_fps and fps >= closest_format_fps:
						if height <= video_height and height >= closest_format_height:
							found_format_i = i
							closest_format_height = height
							closest_format_fps = fps
				if found_format_i != -1:
					break
		if found_format_i != -1:
			var chosen_format := formats[found_format_i] as Dictionary
			var download_url := chosen_format.get("url", "") as String
			# Buffer default is 2 mb and it is usually used when downloading with DASH streams
			var chunk_size := chosen_format.get("downloader_options", {}).get("http_chunk_size", 2000000) as int
			
			var headers := _build_headers(chosen_format)
			
			entry.mutex.lock()
			entry.current_step += 1
			entry.step_description = tr("Downloading video")
			entry.mutex.unlock()
		
			var output_video_path := get_video_path(userdata.video_id, false) as String
		
			var range_downloader := entry.range_downloader as HBHTTPRangeDownloader
			
			var dash_fragments := []
			
			if chosen_format.get("format_note", "") == "DASH video":
				for fragment in chosen_format.get("fragments", []):
					var fragment_path := fragment.get("path", "") as String
					if fragment_path:
						dash_fragments.append(fragment_path)
				download_url = chosen_format.get("fragment_base_url", "")
				entry.dash_estimated_size = chosen_format.get("filesize_approx", chosen_format.get("filesize", 0))
			
			range_downloader.download(download_url, output_video_path, chunk_size, headers, dash_fragments)
			
			while range_downloader.state == HBHTTPRangeDownloader.STATE.STATE_BUSY:
				OS.delay_msec(100)
			
			if range_downloader.has_error():
				result["video"] = false
				result["video_out"] = range_downloader.get_error_string()
				print(result["video_out"])
			else:
				result["video"] = true
				result["video_out"] = "Download OK"
				if video_exists(userdata.video_id):
					cache_meta_mutex.lock()
					cache_meta.cache[userdata.video_id]["video"] = true
					cache_meta.cache[userdata.video_id]["video_ext"] = VIDEO_EXT
					cache_meta.cache[userdata.video_id]["video_fps"] = video_fps
					cache_meta.cache[userdata.video_id]["video_resolution"] = video_height
					cache_meta_mutex.unlock()
		else:
			result["video"] = false
			result["video_out"] = tr("Couldn't find a suitable video format")
	
	# If an error has been emitted, clean up
	if not result.get("video", true) or not result.get("audio", true):
		 clean_up_files(userdata.video_id)
	elif download_audio:
		# Clean up the temp ogg file
		clean_up_temp_files(userdata.video_id)
					
	Log.log(self, "Video download finish!")
	unlock_video(userdata.video_id)
	call_deferred("_video_downloaded", userdata.thread, result)
	
func show_error(output: String, message: String, song: HBSong):
	var progress_thing = PROGRESS_THING.instance()
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
	thread.wait_to_finish()

	songs_being_cached.erase(result.video_id)
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
		var progress_thing = PROGRESS_THING.instance()
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
	process_queue()
	emit_signal("video_downloaded",  result.video_id, result)
	save_cache()
	
func video_exists(video_id):
	var file = File.new()
	return file.file_exists(get_video_path(video_id))
func audio_exists(video_id):
	var file = File.new()
	return file.file_exists(get_audio_path(video_id))
func download_video(entry: CachingQueueEntry):
	var variant = entry.song.get_variant_data(entry.variant)
	var download_video = entry.song.use_youtube_for_video and not variant.audio_only
	var download_audio = entry.song.use_youtube_for_audio
	var song := entry.song
	var thread = Thread.new()
	var url = variant.variant_url
	var video_id = get_video_id(url)
	if video_id in songs_being_cached:
		Log.log(self, "We are already caching this: " + url)
		return ERR_BUSY
	if not video_id:
		Log.log(self, "Error parsing youtube url: " + url)
		return ERR_FILE_NOT_FOUND
		
	songs_being_cached.append(video_id)
	
	if is_video_locked(video_id):
		# Probably a good idea to redownload everything if we get this far...
		clean_up_files(video_id)
		clean_up_temp_files(video_id)
		unlock_video(video_id)
	
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
			Log.log(self, "Already cached, no need to download again %s" % [entry.song.title])
			emit_signal("video_downloaded", video_id, {"cache_entry": entry})
			if is_video_locked(video_id):
				unlock_video(video_id)
			return ERR_ALREADY_EXISTS
	lock_video_id(video_id)
	emit_signal("song_download_start", song)
	var result = thread.start(self, "_download_video", {"thread": thread, "video_id": video_id, "download_video": download_video, "download_audio": download_audio, "song": song, "entry": entry})
	if result != OK:
		print("ERROR STARTING THREAD: ", result)
		Log.log(self, "Error starting thread for ytdl download: " + str(result), Log.LogLevel.ERROR)
	return OK
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

func cache_song(song: HBSong, variant := -1):
	var entry = CachingQueueEntry.new()
	entry.song = song
	entry.variant = variant
	caching_queue.append(entry)
	process_queue()

func _process(delta):
	for video_id in tracked_video_downloads:
		var progress_thing := tracked_video_downloads[video_id].progress_thing as HBDownloadProgressThing
		var entry := tracked_video_downloads[video_id].entry as CachingQueueEntry
		if entry.step_count > 0:
			var downloaded_bytes := entry.get_downloaded_bytes() as int
			var total_byes := entry.get_total_bytes() as int
			var song := entry.song
			var text := "(%d / %d) %s for %s" % [entry.current_step+1, entry.step_count, entry.step_description, song.get_visible_title()]
			if downloaded_bytes != -1 and total_byes != -1:
				text += " (%.2f MB / %.2f MB)" % [downloaded_bytes * 1e-6, total_byes * 1e-6]
			progress_thing.text = text

func process_queue():
	if YoutubeDL.status != YoutubeDL.YOUTUBE_DL_STATUS.READY:
		yield(self, "youtube_dl_status_updated")
	if caching_queue.size() > 0 and songs_being_cached.size() < UserSettings.user_settings.max_simultaneous_downloads:
		for i in range(caching_queue.size()-1, -1, -1):
			var entry = caching_queue[i]
			if YoutubeDL.status == YoutubeDL.YOUTUBE_DL_STATUS.READY:
				var song := entry.song as HBSong
				var variant = song.get_variant_data(entry.variant)
				var video_url_ok = validate_video_url(variant.variant_url)
				if video_url_ok:
					var video_id = get_video_id(variant.variant_url)
					if not video_id in songs_being_cached:
						var result = download_video(entry)
						if result == OK:
							if not video_id in tracked_video_downloads:
								var progress_thing = PROGRESS_THING.instance()
								DownloadProgress.add_notification(progress_thing)
								progress_thing.spinning = true
								progress_thing.set_type(HBDownloadProgressThing.TYPE.NORMAL)
								progress_thing.text = "Downloading media for %s" % [song.get_visible_title()]
								if entry.variant != -1:
									progress_thing.text += " (%s)" % [variant.variant_name]
								tracked_video_downloads[video_id] = {
									"progress_thing": progress_thing,
									"song": song,
									"entry": entry
								}
								emit_signal("song_queued", entry)
				else:
					var progress_thing = PROGRESS_THING.instance()
					DownloadProgress.add_notification(progress_thing)
					progress_thing.set_type(HBDownloadProgressThing.TYPE.ERROR)
					progress_thing.life_timer = 2.0
					progress_thing.text = "Downloading media for %s failed: Invalid URL" % [song.get_visible_title()]
					caching_queue.remove(i)
				if songs_being_cached.size() >= UserSettings.user_settings.max_simultaneous_downloads:
					break
			
func is_already_downloading(song, variant := -1):
	var in_queue = false
	for entry in caching_queue:
		if entry.song == song and entry.variant == variant:
			in_queue = true
			break
	return get_video_id(song.get_variant_data(variant).variant_url) in songs_being_cached or in_queue

func cancel_song(song: HBSong, variant := -1):
	if not get_video_id(song.youtube_url) in songs_being_cached:
		for entry in caching_queue:
			if entry.song == song and entry.variant == variant:
				caching_queue.erase(entry)
				break

func get_video_info_json(video_url: String) -> Dictionary:
	var shared_params = get_ytdl_shared_params()
	shared_params += ["--dump-json", video_url]
	var cmd_out = []
	var err = OS.execute(get_ytdl_executable(), shared_params, true, cmd_out, true)
	var out_dict = {}
	if err == OK:
		for line in cmd_out[0].split("\n"):
			if line.begins_with("{"):
				var parse_result := JSON.parse(line)
				if parse_result.error == OK:
					out_dict = parse_result.result
					break
	else:
		var error_str := "Unknown error"
		for out in cmd_out:
			var found_error := false
			for line in out.split("\n"):
				if line.begins_with("ERROR: [youtube] "):
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
		delete_media_for_video(video_id)
	unused_cache_size = 0
	unused_video_ids.clear()

func delete_media_for_video(video_id: String):
	var d := Directory.new()
	var video_file := (get_cache_dir().plus_file(video_id) + ".webm") as String
	var audio_file := (get_cache_dir().plus_file(video_id) + ".ogg") as String
	if d.file_exists(video_file):
		d.remove(video_file)
	if d.file_exists(audio_file):
		d.remove(audio_file)
