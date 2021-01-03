# Utility methods
class_name HBUtils

enum TimeFormat {
	FORMAT_HOURS   = 1 << 0, # broken, do not use
	FORMAT_MINUTES = 1 << 1,
	FORMAT_SECONDS = 1 << 2,
	FORMAT_MILISECONDS = 1 << 3,
	FORMAT_DEFAULT = 1 << 1 | 1 << 2 | 1 << 3
}

# for lap-time style time formatting
static func format_time(time: float, format = TimeFormat.FORMAT_DEFAULT, digit_format = "%02d"):
	var digits = []
	var s = time / 1000.0
	if format & TimeFormat.FORMAT_HOURS:
		var hours = digit_format % [s / 3600]
		digits.append(hours)

	if format & TimeFormat.FORMAT_MINUTES:
		var minutes = digit_format % [s / 60]
		digits.append(minutes)
	
	if format & TimeFormat.FORMAT_SECONDS:
		var seconds = digit_format % [int(s) % 60]
		digits.append(seconds)

	var formatted = String()
	var colon = ":"
	
	for digit in digits:
		formatted += digit + colon

	if not formatted.empty():
		formatted = formatted.rstrip(colon)
	if format & TimeFormat.FORMAT_MILISECONDS:
		var miliseconds = fmod(time, 1000.0)
		formatted += ".%03d" % [miliseconds]
	return formatted

# Merges two dicts, similar to JS's spread operator
static func merge_dict(target, patch):
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				merge_dict(tv, patch[key])
			else:
				target[key] = patch[key]
		else:
			target[key] = patch[key]
	return target

# Converts a string from being complex to snake case
static func get_valid_filename(value: String):
	# Convert to ascii to strip most characters
	value = value.strip_edges().replace(' ', '_')
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	return regex.sub(value, "", true).to_lower()
	
# ogg loader from file, this is stupid
static func load_ogg(path: String) -> AudioStreamOGGVorbis:
	var ogg_file = File.new()
	ogg_file.open(path, File.READ)
	var bytes = ogg_file.get_buffer(ogg_file.get_len())
	var stream = AudioStreamOGGVorbis.new()
	stream.data = bytes
	ogg_file.close()
	return stream
	
static func load_wav(path: String):
	var file = File.new()
	file.open(path, file.READ)
	var buffer = file.get_buffer(file.get_len())
	var stream = AudioStreamSample.new()
	stream.data = buffer
	
	var mix_rate_encoded = buffer.subarray(24, 27)
	var mix_rate = mix_rate_encoded[0] + (mix_rate_encoded[1] << 8)
	mix_rate += (mix_rate_encoded[2] << 16) + (mix_rate_encoded[3] << 23)
	stream.mix_rate = mix_rate
	
	var channel_count_encoded = buffer.subarray(22, 23)
	var channel_count = channel_count_encoded[0] + (channel_count_encoded[1] << 8)
	stream.stereo = channel_count != 1
	
	var bits_per_sample_encoded = buffer.subarray(34, 35)
	var bits_per_sample = bits_per_sample_encoded[0] + (bits_per_sample_encoded[1] << 8)
	if bits_per_sample == 16:
		stream.format = AudioStreamSample.FORMAT_16_BITS
	else:
		stream.format = AudioStreamSample.FORMAT_8_BITS

	file.close()
	return stream
	
enum OGG_ERRORS {
	OK,
	NOT_AN_OGG,
	NOT_VORBIS
}
	
static func get_ogg_channel_count(path: String) -> int:
	var file = File.new()
	var r = file.open(path, File.READ)
	print("OPENING", path, r)
	var _sectors = {}
	_sectors["header"] = file.get_buffer(4)

	_sectors["version"] = file.get_buffer(1)
	_sectors["flags"] = file.get_buffer(1)
	_sectors["granule"] = file.get_buffer(8)
	_sectors["serial"] = file.get_buffer(4)
	_sectors["sequence"] = file.get_buffer(4)
	_sectors["checksum"] = file.get_buffer(4)
	_sectors["segment_count"] = file.get_8()
	_sectors["segment_table"] = file.get_buffer(_sectors.segment_count)
	_sectors["packet_type"] = file.get_buffer(1)
	_sectors["vorbis_magic"] = file.get_buffer(6)
	_sectors["vorbis_version"] = file.get_buffer(4)
	_sectors["audio_channels"] = file.get_8()
	print("CHANNELS! ", _sectors["audio_channels"])
	return _sectors["audio_channels"]
# Verifies if an OGG
static func verify_ogg(path: String):
	var file = File.new()
	file.open(path, File.READ)
	var _sectors = {}
	_sectors["header"] = file.get_buffer(4)

	_sectors["version"] = file.get_buffer(1)
	_sectors["flags"] = file.get_buffer(1)
	_sectors["granule"] = file.get_buffer(8)
	_sectors["serial"] = file.get_buffer(4)
	_sectors["sequence"] = file.get_buffer(4)
	_sectors["checksum"] = file.get_buffer(4)
	_sectors["segment_count"] = file.get_8()
	_sectors["segment_table"] = file.get_buffer(_sectors.segment_count)
	_sectors["packet_type"] = file.get_buffer(1)
	_sectors["vorbis_magic"] = file.get_buffer(6)
	_sectors["vorbis_version"] = file.get_buffer(32)
	_sectors["audio_channels"] = file.get_8()
	
	var error = OGG_ERRORS.OK
	
	if not _sectors.header.get_string_from_utf8() == "OggS":
		error = OGG_ERRORS.NOT_AN_OGG
	elif not _sectors.vorbis_magic.get_string_from_utf8() == "vorbis":
		error = OGG_ERRORS.NOT_VORBIS
	return error

# finds a key by its value
static func find_key(dictionary, value):
	var index = dictionary.values().find(value)
	return dictionary.keys()[index]

# New note curve calculation function, it's fast
static func calculate_note_sine(time: float, pos: Vector2, angle: float, frequency: float, amplitude: float, distance: float):
	if distance == 0:
		return pos
	elif not fmod(frequency, 2) == 0:
		frequency *= -1
	time = 1.0 - time
	var point_x = time * distance
	var point_y = sin(time * PI * frequency) / 12.0 * amplitude
	var point = Vector2(point_x, point_y).rotated(deg2rad(angle)) + pos
	return point
	
# Loads images from FS properly (although it breaks in single-threaded render mode...)
static func image_from_fs(path: String):
	if path.begins_with("res://"):
		var src = load(path)
		if src is Texture:
			return src.get_data()
		else:
			return src
	else:
		var image = Image.new()
		image.load(path)
		return image

static func _wrap_image_texture(img: Image):
	var text = ImageTexture.new()
	text.create_from_image(img, Texture.FLAGS_DEFAULT & ~(Texture.FLAG_MIPMAPS))
	return text

static func texture_from_fs(path: String):
	if path.begins_with("res://"):
		var src = load(path)
		if src is Texture:
			return src
		else:
			return _wrap_image_texture(src)
	else:
		var image = Image.new()
		image.load(path)
		return _wrap_image_texture(image)

# same as image_from_fs but async?
# static func image_from_fs_async(path: String):
# 	if path.begins_with("res://"):
# 		var img = load(path)
# 		return img
# 	else:
# 		var image = Image.new()
# 		image.load(path)
# 		return image
		
static func texture_from_fs_image(path: String) -> Texture:
	var img: Image
	if path.begins_with("res://"):
		img = load(path) as Image
	else:
		img = Image.new()
		img.load(path)
		
	var texture = ImageTexture.new()
	texture.create_from_image(img, Texture.FLAGS_DEFAULT & ~(Texture.FLAG_MIPMAPS))
	return texture
	

# Adds a thousands separator to the number given
static func thousands_sep(number, prefix=''):
	number = int(number)
	var neg = false
	if number < 0:
		number = -number
		neg = true
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	if neg: res = '-'+prefix+res
	else: res = prefix+res
	return res
	
static func remap(value, low1, low2, high1, high2):
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1)

static func join_path(path1: String, path2: String) -> String:
	if not path1.ends_with("/") and not path2.begins_with("/"):
		path1 += "/"
	return path1 + path2

static func get_experience_to_next_level(level: int) -> int:
	return 500 + (500 * level)
