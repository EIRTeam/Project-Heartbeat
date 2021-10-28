extends VideoPlayer

var offset = -10.0

func _ready():
	add_to_group("song_backgrounds")
	_background_dim_changed(UserSettings.user_settings.background_dim)
func _background_dim_changed(new_dim: float):
	modulate = Color.white - (Color.black * new_dim)

func set_stream_position(pos: float):
	prints(pos, offset)
	.set_stream_position(pos + offset)

func _process(delta):
	pass
