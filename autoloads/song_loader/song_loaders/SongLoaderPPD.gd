# Project Heartbeat-style song song loading code
extends SongLoaderImpl

class_name SongLoaderPPD

const LOG_NAME = "SongLoaderPPD"
const PPD_YOUTUBE_URL_LIST_PATH = "user://ppd_youtube.json"

var ppd_youtube_url_list = {}

func _init_loader():
	var dir := Directory.new()
	if dir.file_exists(PPD_YOUTUBE_URL_LIST_PATH):
		load_ppd_youtube_url_list()

func get_meta_file_name() -> String:
	return "data.ini"

func load_song_meta_from_folder(path: String, id: String):
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var txt = file.get_as_text()
		var song = HBPPDSong.from_ini(txt, id)
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

func set_ppd_youtube_url(song: HBSong, url: String):
	ppd_youtube_url_list[song.id] = url
	song.youtube_url = url
	save_ppd_youtube_url_list()
