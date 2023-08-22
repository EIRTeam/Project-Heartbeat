extends Panel
var FREQ_MAX = 44100.0 / 2.5: set = set_freq_max
const VU_COUNT = 256 # high VU_COUNTS break on windows
var MIN_DB = 60: set = set_min_db
var spectrum_image: Image
var spectrum_image_texture: ImageTexture
@export var fallback_stylebox: StyleBox
@export var ingame: bool = false
func set_freq_max(value: float):
	FREQ_MAX = value

func set_min_db(value):
	MIN_DB = value

func _ready():
	add_to_group("song_backgrounds")
	spectrum_image = Image.create(VU_COUNT, 1, false, Image.FORMAT_R8)
	spectrum_image_texture = ImageTexture.create_from_image(spectrum_image) #,Texture2D.FLAG_FILTER
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("audio", spectrum_image_texture)
	mat.set_shader_parameter("FREQ_RANGE", VU_COUNT)
	set("z", -1000)
	if not UserSettings.user_settings.visualizer_enabled:
		if ingame and UserSettings.user_settings.background_dim == 0:
			queue_free()
		else:
			set_process(false)
			material = CanvasItemMaterial.new()
			if fallback_stylebox:
				add_theme_stylebox_override("panel", fallback_stylebox)
	else:
		_background_dim_changed(UserSettings.user_settings.background_dim)

func _background_dim_changed(new_dim: float):
	if not UserSettings.user_settings.visualizer_enabled:
		var box = fallback_stylebox as StyleBoxFlat
		box.bg_color.a = 0.5 + (new_dim * 0.5)

func _process(delta):
	for i in range(VU_COUNT):
		var magnitude := HBGame.spectrum_snapshot.get_value_at_i(i) as float
		spectrum_image.set_pixel(i, 0, Color(magnitude, 0.0, 0.0))
	
	spectrum_image_texture.update(spectrum_image)
	var mat := material as ShaderMaterial
	mat.set_shader_parameter("size", size)

 
