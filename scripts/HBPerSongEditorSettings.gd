# Class used for editor settings per song, included int the HBChart file.
extends HBSerializable

class_name HBPerSongEditorSettings

var hidden_layers = []

var bpm = 180.0
var offset = 0.0
var note_resolution = 16
var beats_per_bar = 4
var timeline_snap := true

var auto_multi = false

var waveform = false
var hold_calculator = true
var show_video := true
var show_bg := true

var grid_snap := true
var show_grid := true
var grid_resolution := {"x": 20.0, "y": 40.0}

var separation := 96
var diagonal_angle := 45
var autoslide := true
var arranger_snaps := 16


var transforms_use_center := false
var circle_from_inside := false
var circle_advanced_mode := false
var circle_size := 16
var circle_separation := 96


func get_serialized_type():
	return "PerSongEditorSettings"

func _init():
	serializable_fields += [
		"hidden_layers", "bpm", "offset", "beats_per_bar", "note_resolution", "timeline_snap", 
		"auto_multi", "waveform", "show_video", "show_bg",
		"grid_snap", "show_grid", "grid_resolution",
		"separation", "diagonal_angle", "autoslide", "arranger_snaps",
		"transforms_use_center", "circle_from_inside", "circle_advanced_mode", "circle_size", "circle_separation"
	]
	hidden_layers.append(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_RIGHT) + "2")
	hidden_layers.append(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_LEFT) + "2")
	hidden_layers.append(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.HEART))

func set_layer_visibility(visibility: bool, layer_name: String):
	if visibility:
		if layer_name in hidden_layers:
			hidden_layers.erase(layer_name)
	else:
		hidden_layers.append(layer_name)
