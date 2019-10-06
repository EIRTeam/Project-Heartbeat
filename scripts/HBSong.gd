
extends HBSerializable

class_name HBSong

var title := ""
var artist := ""
var artist_alias := ""
var producers = []
var writers = []
var audio = ""
var creator = ""
var bpm = 150
var preview_start = 77000
var charts = []

var id
	
func get_serialized_type():
	return "Song"

func _init():
	serializable_fields += ["title", "artist", "artist_alias", "producers", "writers", "audio", "creator", "bpm", "preview_start", "charts"]

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
	
func get_chart_path(difficulty):
	return "res://songs/%s/%s" % [id, charts[difficulty].file]
	
func get_waveform_path():
	return "res://songs/%s/%s" % [id, "waveform.json"]
	
func get_song_audio_res_path():
	return "res://songs/%s/%s" % [id, audio]
