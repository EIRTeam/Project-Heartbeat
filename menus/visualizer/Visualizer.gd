extends Panel
var spectrum : AudioEffectSpectrumAnalyzerInstance
var FREQ_MAX = 44100.0 / 3 setget set_freq_max
const VU_COUNT = 64 # high VU_COUNTS break on windows
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
	spectrum = AudioServer.get_bus_effect_instance(1,0)
	spectrum_image_texture.flags = 0 # disable filter to avoid bugs
	spectrum_image.create(VU_COUNT,1,false,Image.FORMAT_R8)
	spectrum_image_texture.create_from_image(spectrum_image)
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

		
func _physics_process(delta):
	var prev_hz = 0
	spectrum_image.lock()
	for i in range(VU_COUNT):
		var hz = i * (FREQ_MAX / VU_COUNT);
		var f = spectrum.get_magnitude_for_frequency_range(prev_hz,hz, 1)
		var energy = clamp((MIN_DB + linear2db(f.length()))/MIN_DB,0,1)
		
		spectrum_image.set_pixel(i, 0, Color(energy, 1.0, 1.0))
		if (i == -1):
			spectrum_image.set_pixel(i, 0, Color(1.0, 0.0, 0.0))
			
		prev_hz = hz
	spectrum_image.unlock()
	spectrum_image_texture.set_data(spectrum_image)
	var mat := material as ShaderMaterial
	mat.set_shader_param("size", rect_size)

