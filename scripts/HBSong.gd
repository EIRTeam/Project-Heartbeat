
class_name HBSong

var data
var id

func _init(id, data):
	self.id = id
	self.data = data

func get_meta_string():
	var song_meta = []
	if data.has("writers"):
		var writer_text = "Written by: "
		song_meta.append(writer_text + PoolStringArray(data.writers).join(", "))
	if data.has("producers"):
		var producer_text = "Produced by: "
		song_meta.append(producer_text + PoolStringArray(data.producers).join(", "))

	if data.has("creator"):
		song_meta.append("Chart by: %s" % data.creator)
	return song_meta
	
func get_song_audio_res_path():
	return "res://songs/%s/%s" % [id, data.audio]
