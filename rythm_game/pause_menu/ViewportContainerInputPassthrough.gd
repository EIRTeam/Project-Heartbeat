extends SubViewportContainer

func _ready():
	pass

func _unhandled_input(event):
	$ViewPort3D.unhandled_input(event)
	get_viewport().set_input_as_handled()
