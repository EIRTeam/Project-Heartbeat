# Project Heartbeat-style song song loading code
extends SongLoaderImpl

class_name SongLoaderPPD

const LOG_NAME = "SongLoaderPPD"
var PPD_YOUTUBE_URL_LIST_PATH = "user://ppd_youtube.json"

var ppd_youtube_url_list = {}

# Extra data json file that is used by the PPD manager tool
const OPT_META_FILE_NAME = "ph_ext.json"

func _init_loader() -> int:
	var dir := Directory.new()
	
	PPD_YOUTUBE_URL_LIST_PATH = HBGame.platform_settings.user_dir_redirect(PPD_YOUTUBE_URL_LIST_PATH)
		
	if dir.file_exists(PPD_YOUTUBE_URL_LIST_PATH):
		load_ppd_youtube_url_list()
	return OK

func get_meta_file_name() -> String:
	return "data.ini"

func get_optional_meta_files() -> Array:
	return [OPT_META_FILE_NAME]

static func load_opt_file(path: String) -> Dictionary:
	var data := {}
	
	var file := File.new()
	
	if file.file_exists(path):
		if file.open(path, File.READ) == OK:
			var contents := file.get_as_text()
			var parse_result := JSON.parse(contents)
			if parse_result.error == OK:
				data = parse_result.result
				if "type" in data:
					data.erase("type")
	
	return data

func load_song_meta_from_folder(path: String, id: String):
	var file = File.new()
	
	var opt_meta_file_path = HBUtils.join_path(path.get_base_dir(), OPT_META_FILE_NAME)
	
	var opt_data = load_opt_file(opt_meta_file_path)
	
	if file.open(path, File.READ) == OK:
		var txt = file.get_as_text()
		var song = HBPPDSong.from_ini(txt, id)
		var dict = HBUtils.merge_dict(song.serialize(), opt_data)
		song = HBPPDSong.deserialize(dict)
		song.id = id
		song.path = path.get_base_dir()
		if id in ppd_youtube_url_list:
			song.youtube_url = ppd_youtube_url_list[id]
		# Audio file discovery
		var dir := Directory.new()
		if dir.open(song.path) == OK:
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			while dir_name != "":
				if not dir.current_is_dir():
					if dir_name.ends_with(".ogg"):
						song.audio = dir_name
						break
				dir_name = dir.get_next()
		
		return song
	return null

func load_ppd_youtube_url_list():
	var file = File.new()
	if file.open(PPD_YOUTUBE_URL_LIST_PATH, File.READ) == OK:
		var result = JSON.parse(file.get_as_text()) as JSONParseResult
		if result.error == OK:
			ppd_youtube_url_list = result.result
		else:
			Log.log(self, "Error loading PPD URL list " + str(result.error))

func save_ppd_youtube_url_list():
	var file = File.new()
	if file.open(PPD_YOUTUBE_URL_LIST_PATH, File.WRITE) == OK:
		file.store_string(JSON.print(ppd_youtube_url_list))

# We attempt to purge a youtube URL's on disk data, if it's not being used by another song
func _try_purge_youtube_video_file(song: HBSong):
	var vid = YoutubeDL.get_video_id(song.youtube_url)
	for f_song in SongLoader.songs.values():
		if f_song != song:
			var id = YoutubeDL.get_video_id(f_song.youtube_url)
			if id == vid:
				return
	var vp = YoutubeDL.get_video_path(vid)
	var ap = YoutubeDL.get_audio_path(vid)
	var dir = Directory.new()
	Log.log(self, "Removing existing on disk data for %s" % [song.title])
	if dir.file_exists(vp):
		var err = dir.remove(vp)
		if err != OK:
			Log.log(self, "Error removing video file: %s for song %s %d" % [vp, song.title, err])
	if dir.file_exists(ap):
		var err = dir.remove(ap)
		if err != OK:
			Log.log(self, "Error removing audio file: %s for song %s %d" % [ap, song.title, err])
func set_ppd_youtube_url(song: HBSong, url: String):
	if YoutubeDL.get_video_id(song.youtube_url) != YoutubeDL.get_video_id(url):
		_try_purge_youtube_video_file(song)
		ppd_youtube_url_list[song.id] = url
		song.youtube_url = url
		save_ppd_youtube_url_list()

func caching_enabled():
	if not HBGame.platform_settings is HBPlatformSettingsDesktop:
		return false
	else:
		return true
