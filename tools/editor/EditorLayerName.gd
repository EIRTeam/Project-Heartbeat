extends Panel

var layer_name: String setget set_layer_name

func set_layer_name(value):
	layer_name = value
	$Label.text = value
	if value in HBNoteData.NOTE_TYPE.keys():
		$Label.hide()
		$LayerNoteType.show()
		$LayerNoteType.texture = IconPackLoader.get_variations(value).note
	else:
		$Label.show()
		$LayerNoteType.hide()
