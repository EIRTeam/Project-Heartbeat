extends Panel
var FREQ_MAX = 44100.0 / 2.5 setget set_freq_max
const VU_COUNT = 256 # high VU_COUNTS break on windows
var MIN_DB = 60 setget set_min_db
var spectrum_image := Image.new()
var spectrum_image_texture := ImageTexture.new()
export(StyleBox) var fallback_stylebox: StyleBox
export(bool) var ingame = false
func set_freq_max(value: float):
	FREQ_MAX = value

func set_min_db(value):
	MIN_DB = value

func _ready():
	add_to_group("song_backgrounds")
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		# GLES2 doesn't like R8
		spectrum_image.create(VU_COUNT, 1, false, Image.FORMAT_RGB8)
	else:
		spectrum_image.create(VU_COUNT, 1, false, Image.FORMAT_R8)
	spectrum_image_texture.create_from_image(spectrum_image, Texture.FLAG_FILTER)
	var mat := material as ShaderMaterial
	mat.set_shader_param("audio", spectrum_image_texture)
	mat.set_shader_param("FREQ_RANGE", VU_COUNT)
	set("z", -1000)
	if not UserSettings.user_settings.visualizer_enabled:
		if ingame and UserSettings.user_settings.background_dim == 0:
			queue_free()
		else:
			set_physics_process(false)
			material = CanvasItemMaterial.new()
			if fallback_stylebox:
				add_stylebox_override("panel", fallback_stylebox)
	else:
		_background_dim_changed(UserSettings.user_settings.background_dim)

func _background_dim_changed(new_dim: float):
	if not UserSettings.user_settings.visualizer_enabled:
		var box = fallback_stylebox as StyleBoxFlat
		box.bg_color.a = 0.5 + (new_dim * 0.5)

func _process(delta: float):
	update()

func _physics_process(delta):
	spectrum_image.lock()
	
	for i in range(VU_COUNT):
		var magnitude := HBGame.spectrum_snapshot.get_value_at_i(i) as float
		spectrum_image.set_pixel(i, 0, Color(magnitude, 0.0, 0.0))
	
	spectrum_image.unlock()
	spectrum_image_texture.set_data(spectrum_image)
	var mat := material as ShaderMaterial
	mat.set_shader_param("size", rect_size)

 
