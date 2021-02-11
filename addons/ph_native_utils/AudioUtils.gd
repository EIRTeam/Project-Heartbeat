class_name HBAudioUtils

var utils_native = null

func _init():
	var AudioNormalizer = preload("res://addons/ph_native_utils/AudioNormalizer.gdns") as NativeScript
	if not AudioNormalizer.library.get_current_library_path().empty():
		utils_native = AudioNormalizer.new()

func split_audio(stream: AudioStreamOGGVorbis):
	if utils_native:
		utils_native.split_dsc_audio(stream.data)
func get_split_instrumental():
	if utils_native:
		var inst := utils_native.get_instrumental_audio() as PoolByteArray
		var mix_rate_encoded = inst.subarray(24, 27)
		var mix_rate = mix_rate_encoded[0] + (mix_rate_encoded[1] << 8)
		mix_rate += (mix_rate_encoded[2] << 16) + (mix_rate_encoded[3] << 23)
		var stream = AudioStreamSample.new()
		stream.format = AudioStreamSample.FORMAT_16_BITS
		stream.mix_rate = mix_rate
		stream.data = inst
		stream.stereo = true
		var file = File.new()
		file.open("user://f.wav", File.WRITE)
		file.store_buffer(inst)
		file.close()
		return stream

func get_split_voice():
	if utils_native:
		var inst := utils_native.get_voice_audio() as PoolByteArray
		var mix_rate_encoded = inst.subarray(24, 27)
		var mix_rate = mix_rate_encoded[0] + (mix_rate_encoded[1] << 8)
		mix_rate += (mix_rate_encoded[2] << 16) + (mix_rate_encoded[3] << 23)
		var stream = AudioStreamSample.new()
		stream.format = AudioStreamSample.FORMAT_16_BITS
		stream.mix_rate = mix_rate
		stream.data = inst
		stream.stereo = true
		return stream
