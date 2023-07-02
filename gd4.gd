extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var actions = UserSettings.get_input_map()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	pass
