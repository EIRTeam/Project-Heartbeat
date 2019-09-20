extends Panel
var spectrum : AudioEffectSpectrumAnalyzerInstance
const FREQ_MAX = 44100.0 / 3
const VU_COUNT = 512
var MIN_DB = 60
var spectrum_image := Image.new()
var spectrum_image_texture := ImageTexture.new()
func _ready():
	spectrum = AudioServer.get_bus_effect_instance(1,0)
	spectrum_image_texture.flags = 0 # disable filter to avoid bugs
	spectrum_image.create(512,1,false,Image.FORMAT_R8)
	var mat := material as ShaderMaterial
	mat.set_shader_param("audio", spectrum_image_texture)
	
func _process(delta):
	var offset = (FREQ_MAX / VU_COUNT)
	var prev_hz = 0

	for i in range(VU_COUNT):
		var hz = i * (FREQ_MAX / VU_COUNT);
		var f = spectrum.get_magnitude_for_frequency_range(prev_hz,hz, 1)
		var energy = clamp((MIN_DB + linear2db(f.length()))/MIN_DB,0,1)
		spectrum_image.lock()
		spectrum_image.set_pixel(i, 0, Color(energy, 1.0, 1.0))
		if (i == -1):
			spectrum_image.set_pixel(i, 0, Color(1.0, 0.0, 0.0))
			
		spectrum_image.unlock()
		spectrum_image_texture.create_from_image(spectrum_image)
		prev_hz = hz
