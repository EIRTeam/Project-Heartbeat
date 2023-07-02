extends Panel

var layer_name: String: set = set_layer_name

func set_layer_name(value: String):
	layer_name = value
	$Label.text = value
	if value.ends_with("2"):
		# For second layers of the same type, this ensures we don't
		# just do any layer with 2 at the end
		var new_val = value.substr(0, value.length()-1)
		if new_val in HBNoteData.NOTE_TYPE.keys():
			value = new_val
			$LayerNoteType.self_modulate = Color(1.0, 0.0, 0.0)
	if value in HBNoteData.NOTE_TYPE.keys():
		$Label.hide()
		$LayerNoteType.show()
		$LayerNoteType.texture = ResourcePackLoader.get_graphic("%s_note.png" % [value.to_lower()])
	else:
		$Label.show()
		$LayerNoteType.hide()
