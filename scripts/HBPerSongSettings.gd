# Class used for individual song settings by the user.
extends HBSerializable

class_name HBPerSongSettings

var lag_compensation = 0
var volume = 1.0
var video_enabled = true
var use_song_skin := true
var vocals_enabled := true

func _init():
	serializable_fields += ["lag_compensation", "volume", "video_enabled", "use_song_skin", "vocals_enabled"]

func get_serialized_type():
	return "PerSongSettings"
