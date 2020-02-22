
extends HBSerializable

class_name HBSong

# Because user loaded songs don't have .import files we have to load stuff like songs
# differently, seriously???
enum SONG_FS_ORIGIN {
	BUILT_IN,
	USER
}

var path: String
var id: String

var title := ""
var romanized_title := ""
var artist := ""
var artist_alias := ""
var composers = []
var writers = []
var vocals = []
var audio = ""
var voice = ""
var creator = ""
var original_title = ""
var bpm = 150
var preview_start = 77000
var charts = {}
var preview_image = ""
var background_image = ""
var circle_image = ""
var circle_logo = ""

func get_serialized_type():
	return "Song"

func _init():
	serializable_fields += ["title", "romanized_title", "artist", "artist_alias", 
	"composers", "vocals", "writers", "audio", "creator", "original_title", "bpm",
	"preview_start", "charts", "preview_image", "background_image", "voice", 
	"circle_image", "circle_logo"]

func get_meta_string():
	var song_meta = []
	if writers.size() > 0:
		var writer_text = tr("Written by: ")
		song_meta.append(writer_text + PoolStringArray(writers).join(", "))
	if vocals.size() > 0:
		var vocals_text = tr("Vocals by: ")
		song_meta.append(vocals_text + PoolStringArray(vocals).join(", "))
	if composers.size() > 0:
		var composers_text = tr("Composed by: ")
		song_meta.append(composers_text + PoolStringArray(composers).join(", "))
	if creator != "":
		song_meta.append(tr("Chart by: %s") % creator)
	return song_meta
	
	
func get_fs_origin():
	if path.begins_with("res://"):
		return SONG_FS_ORIGIN.BUILT_IN
	return SONG_FS_ORIGIN.USER 
	
func get_chart_path(difficulty):
	return path.plus_file("/%s" % [charts[difficulty].file])
	
func get_song_audio_res_path():
	if audio:
		return path.plus_file("/%s" % [audio])
	else:
		return path.plus_file(HBUtils.get_valid_filename(title)) + ".ogg"
		
func get_song_voice_res_path():
	if voice:
		return path.plus_file("/%s" % [voice])
	else:
		return path.plus_file("/%s" % ["voice.ogg"])
func get_song_preview_res_path():
	if preview_image != "":
		return path.plus_file("/%s" % [preview_image])
	else:
		null
		
func get_song_background_image_res_path():
	if background_image != "":
		return path.plus_file("/%s" % [background_image])
	else:
		return "res://graphics/background.png"
		
func get_song_circle_image_res_path():
	if circle_image != "":
		return path.plus_file("/%s" % [circle_image])
	else:
		return null
		
func get_song_circle_logo_image_res_path():
	if circle_logo != "":
		return path.plus_file("/%s" % [circle_logo])
	else:
		return null
		
func get_meta_path():
	return path.plus_file("song.json")
		
func get_audio_stream():
	if get_fs_origin() == SONG_FS_ORIGIN.BUILT_IN:
		return load(get_song_audio_res_path())
	else:
		return HBUtils.load_ogg(get_song_audio_res_path())
func get_voice_stream():
	if get_fs_origin() == SONG_FS_ORIGIN.BUILT_IN:
		return load(get_song_voice_res_path())
	else:
		return HBUtils.load_ogg(get_song_voice_res_path())
	
func save_song():
	# Ensure song directory exists
	var dir := Directory.new()
	dir.make_dir_recursive(path)
	
	save_to_file(get_meta_path())

func get_visible_title() -> String:
	if UserSettings.user_settings.romanized_titles_enabled and romanized_title:
		return romanized_title
	else:
		return title
