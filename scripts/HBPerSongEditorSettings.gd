extends HBSerializable

class_name HBPerSongEditorSettings

var hidden_layers = []
var bpm = 0.0
var offset = 0.0
var note_resolution = 4
var beats_per_bar = 4
var auto_multi = true
func get_serialized_type():
	return "PerSongEditorSettings"

func _init():
	serializable_fields += ["hidden_layers", "bpm", "offset", "beats_per_bar", "note_resolution", "auto_multi"]
	hidden_layers.append(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_RIGHT) + "2")
	hidden_layers.append(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_LEFT) + "2")

func set_layer_visibility(visibility: bool, layer_name: String):
	if visibility:
		if layer_name in hidden_layers:
			hidden_layers.erase(layer_name)
	else:
		hidden_layers.append(layer_name)
