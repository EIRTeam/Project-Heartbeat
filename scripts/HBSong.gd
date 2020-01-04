
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
var artist := ""
var artist_alias := ""
var producers = []
var writers = []
var audio = ""
var creator = ""
var bpm = 150
var preview_start = 77000
var charts = {}
var preview_image = ""
var background_image = ""
	
func get_serialized_type():
	return "Song"

func _init():
	serializable_fields += ["title", "artist", "artist_alias", "producers", "writers", "audio", "creator", "bpm", "preview_start", "charts", "preview_image", "background_image"]

func get_meta_string():
	var song_meta = []
	if writers.size() > 0:
		var writer_text = "Written by: "
		song_meta.append(writer_text + PoolStringArray(writers).join(", "))
	if producers.size() > 0:
		var producer_text = "Produced by: "
		song_meta.append(producer_text + PoolStringArray(producers).join(", "))

	if creator != "":
		song_meta.append("Chart by: %s" % creator)
	return song_meta
	
	
func get_fs_origin():
	if path.begins_with("res://"):
		return SONG_FS_ORIGIN.BUILT_IN
	return SONG_FS_ORIGIN.USER 
	
func get_chart_path(difficulty):
	return path.plus_file("/%s" % [charts[difficulty].file])
	
func get_waveform_path():
	return path.plus_file("/%s" % ["waveform.json"])
	
func get_song_audio_res_path():
	if audio:
		return path.plus_file("/%s" % [audio])
	else:
		return path.plus_file(HBUtils.get_valid_filename(title)) + ".ogg"
		
func get_song_preview_res_path():
	if preview_image != "":
		return path.plus_file("/%s" % [preview_image])
	else:
		return "res://graphics/no_preview.png"
		
func get_song_background_image_res_path():
	if background_image != "":
		return path.plus_file("/%s" % [background_image])
	else:
		return "res://graphics/background.png"
		
func get_meta_path():
	return path.plus_file("song.json")
		
func get_audio_stream():
	if get_fs_origin() == SONG_FS_ORIGIN.BUILT_IN:
		return load(get_song_audio_res_path())
	else:
		return HBUtils.load_ogg(get_song_audio_res_path())
		
	
func save_song():
	# Ensure song directory exists
	var dir := Directory.new()
	dir.make_dir_recursive(path)
	
	save_to_file(get_meta_path())
