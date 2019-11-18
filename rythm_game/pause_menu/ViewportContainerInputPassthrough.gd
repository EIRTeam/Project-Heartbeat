extends ViewportContainer

func _ready():
	pass

func _unhandled_input(event):
	$ViewPort3D.unhandled_input(event)
	print(event)
	get_tree().set_input_as_handled()
