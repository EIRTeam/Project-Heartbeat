extends Panel

var layer_name: String setget set_layer_name

func set_layer_name(value):
	layer_name = value
	$Label.text = value
