extends VideoStreamPlayer

var offset = -10.0

func _ready():
	add_to_group("song_backgrounds")
	_background_dim_changed(UserSettings.user_settings.background_dim)

func _background_dim_changed(new_dim: float):
	modulate = Color.WHITE - (Color.BLACK * new_dim)

func set_stream_position(pos: float):
	super.set_stream_position(pos + offset)

func _process(delta):
	pass
