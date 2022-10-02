# Class used for editor settings per song, included int the HBChart file.
extends HBSerializable

class_name HBPerSongEditorSettings

signal property_changed

var hidden_layers = []

var bpm := 180.0
var offset := 0.0
var note_resolution := 16
var beats_per_bar := 4
var timeline_snap := true

var auto_multi := false

var waveform := true
var hold_calculator := true
var show_video := true
var show_bg := true
var selected_variant := -1

var grid_snap := true
var show_grid := true

var separation := 96
var reverse_arrange := false
var autoslide := true
var angle_snaps := 32
var autoplace := true
var autoangle := true

var circle_size := 16
var circle_separation := 96


func get_serialized_type():
	return "PerSongEditorSettings"

func _init():
	serializable_fields += [
		"hidden_layers", "bpm", "offset", "beats_per_bar", "note_resolution", "timeline_snap", 
		"auto_multi", "waveform", "show_video", "show_bg", "selected_variant", 
		"grid_snap", "show_grid",
		"separation", "diagonal_angle", "autoslide", "autoplace", "autoangle", "angle_snaps",
		"circle_size", "circle_separation"
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

func set(property, value):
	.set(property, value)
	emit_signal("property_changed")
