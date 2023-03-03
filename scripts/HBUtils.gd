# Utility methods
class_name HBUtils

enum TimeFormat {
	FORMAT_HOURS   = 1 << 0, # broken, do not use
	FORMAT_MINUTES = 1 << 1,
	FORMAT_SECONDS = 1 << 2,
	FORMAT_MILISECONDS = 1 << 3,
	FORMAT_DEFAULT = 1 << 1 | 1 << 2 | 1 << 3
}

const MOUSE_BUTTON_NAMES := {
	BUTTON_LEFT: "Left Click",
	BUTTON_RIGHT: "Right Click",
	BUTTON_MIDDLE: "Middle Click",
	BUTTON_XBUTTON1: "Mouse Extra Button 1",
	BUTTON_XBUTTON2: "Mouse Extra Button 2",
	BUTTON_WHEEL_UP: "Mouse Wheel Up",
	BUTTON_WHEEL_DOWN: "Mouse Wheel Down",
	BUTTON_WHEEL_LEFT: "Mouse Wheel Left Button",
	BUTTON_WHEEL_RIGHT: "Mouse Wheel Right Button",
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
	var buffer := file.get_buffer(file.get_len()) as PoolByteArray
	var stream = AudioStreamSample.new()
	
	var mix_rate_encoded = buffer.subarray(24, 27)
	var mix_rate = mix_rate_encoded[0] + (mix_rate_encoded[1] << 8)
	mix_rate += (mix_rate_encoded[2] << 16) + (mix_rate_encoded[3] << 24)
	stream.mix_rate = mix_rate
	var channel_count_encoded = buffer.subarray(22, 23)
	var channel_count = channel_count_encoded[0] + (channel_count_encoded[1] << 8)
	stream.stereo = channel_count != 1
	
	var bits_per_sample_encoded = buffer.subarray(34, 35)
	var bits_per_sample = bits_per_sample_encoded[0] + (bits_per_sample_encoded[1] << 8)
	
	# we strip anything after the data chunk to prevent clicking sounds
	var audio_data_chunk_start = 36
	if buffer.subarray(36, 39).get_string_from_utf8() == "LIST":
		var list_data_chunk_size_enc = buffer.subarray(40, 43)
		var list_data_chunk_size = list_data_chunk_size_enc[0] + (list_data_chunk_size_enc[1] << 8)
		audio_data_chunk_start = 44+list_data_chunk_size
	var audio_data_chunk_size_enc = buffer.subarray(audio_data_chunk_start+4, audio_data_chunk_start+7)
	var audio_data_chunk_size = audio_data_chunk_size_enc[0] + (audio_data_chunk_size_enc[1] << 8)
	audio_data_chunk_size += (audio_data_chunk_size_enc[2] << 16) + (audio_data_chunk_size_enc[3] << 24)
	
	stream.data = buffer.subarray(audio_data_chunk_start+8, audio_data_chunk_start+7+audio_data_chunk_size)
	
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
	var _r = file.open(path, File.READ)
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
	return _sectors["audio_channels"]

static func get_ogg_channel_count_buff(spb: StreamPeerBuffer) -> int:
	var _sectors = {}
	_sectors["header"] = spb.get_data(4)[1]
	_sectors["version"] = spb.get_data(1)[1]
	_sectors["flags"] = spb.get_data(1)[1]
	_sectors["granule"] = spb.get_data(8)[1]
	_sectors["serial"] = spb.get_data(4)[1]
	_sectors["sequence"] = spb.get_data(4)[1]
	_sectors["checksum"] = spb.get_data(4)[1]
	_sectors["segment_count"] = spb.get_8()
	_sectors["segment_table"] = spb.get_data(_sectors.segment_count)[1]
	_sectors["packet_type"] = spb.get_data(1)[1]
	_sectors["vorbis_magic"] = spb.get_data(6)[1]
	_sectors["vorbis_version"] = spb.get_data(4)[1]
	_sectors["audio_channels"] = spb.get_8()
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
	var out: Image
	if path.begins_with("res://"):
		var src = load(path)
		if src is Texture:
			out = src.get_data()
		else:
			out = src
	else:
		var image = Image.new()
		if image.load(path) == OK:
			out = image
	
	if out:
		out.fix_alpha_edges()
	return out

static func _wrap_image_texture(img: Image):
	var text = ImageTexture.new()
	text.create_from_image(img, Texture.FLAGS_DEFAULT & ~(Texture.FLAG_MIPMAPS))
	return text

static func texture_from_fs(path: String):
	var out
	if path.begins_with("res://"):
		var src = load(path)
		if src is Texture:
			out =  src
		else:
			out = _wrap_image_texture(src)
	else:
		var image = Image.new()
		image.load(path)
		out = _wrap_image_texture(image)
	out.resource_path = path + str(rand_range(0, 200000))
	return out

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
	texture.resource_path = path + str(rand_range(0, 200000))
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

static func array2texture(body: PoolByteArray) -> Texture:
	var tex = ImageTexture.new()
	var img = Image.new()
	if body.subarray(0, 2) == PoolByteArray([0xFF, 0xD8, 0xFF]):
		img.load_jpg_from_buffer(body)
	elif body.subarray(0, 3) == PoolByteArray([0x89, 0x50, 0x4E, 0x47]):
		img.load_png_from_buffer(body)
	elif body.subarray(0, 3) == PoolByteArray([0x52, 0x49, 0x46, 0x46]):
		img.load_webp_from_buffer(body)

	tex.create_from_image(img, 0)
	return tex

static func pack_images_turbo16(images: Dictionary, margin=1, strip_transparent=true):
	var time_start = OS.get_ticks_usec()
	
	var _image_sizes = PoolVector2Array()
	
	_image_sizes.resize(images.size())
	for i in range(images.size()):
		var image_name := images.keys()[i] as String
		var image := images[image_name] as Image
		var image_used_rect := image.get_used_rect()
		if not strip_transparent:
			image_used_rect = Rect2(Vector2.ZERO, image.get_size())
		_image_sizes[i] = image_used_rect.size + Vector2(margin, margin)
		
	var atlas = Geometry.make_atlas(_image_sizes)
	
	var atlas_size := atlas.size as Vector2
	
	atlas_size.x = nearest_po2(atlas_size.x)
	atlas_size.y = nearest_po2(atlas_size.y)
	
	var output_image = Image.new()
	output_image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	
	var texture := ImageTexture.new()
	var atlas_textures = {}
	
	var atlas_data = {}
	
	for i in range(images.size()):
		var image := images.values()[i] as Image
		var image_name := images.keys()[i] as String
		var point = (atlas.points[i] as Vector2)
		var image_used_rect = image.get_used_rect()
		if not strip_transparent:
			image_used_rect = Rect2(Vector2.ZERO, image.get_size())
		output_image.blit_rect(image, image_used_rect, point + Vector2(margin, margin))
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.margin = Rect2(image_used_rect.position, image.get_size() - image_used_rect.size)
		atlas_texture.region = image_used_rect
		atlas_texture.region.position = point + Vector2(margin, margin)
		atlas_textures[image_name] = atlas_texture
		# hack af
		var atlas_entry = load("res://tools/resource_pack_editor/HBAtlasEntry.gd").new()
		atlas_entry.region = atlas_texture.region
		atlas_entry.margin = atlas_texture.margin
		atlas_data[image_name] = atlas_entry
		
	texture.create_from_image(output_image)
	
	var time_end = OS.get_ticks_usec()
	print("pack_images_turbo16 took %d microseconds" % [(time_end - time_start)])
	
	return {
		"texture": texture,
		"atlas_textures": atlas_textures,
		"atlas_data": atlas_data
	}

static func is_gui_directional_press(action: String, event):
	var gui_press = false
	
	# This is so the d-pad doesn't trigger the order by list
	for mapped_event in InputMap.get_action_list(action):
		if mapped_event.device == event.device:
			if mapped_event is InputEventKey and event is InputEventKey:
				if mapped_event.scancode == event.scancode:
					gui_press = true
					break
			if mapped_event is InputEventJoypadButton and event is InputEventJoypadButton:
				if mapped_event.button_index == event.button_index:
					gui_press = true
					break
	return gui_press

static func sj2utf(input: PoolByteArray) -> PoolByteArray:
	var output = PoolByteArray()
	output.resize(input.size()*3)
	
	var index_input = 0
	var index_output = 0
	
	while index_input < input.size():
		var array_section = input[index_input] >> 4
		
		var array_offset
		if array_section == 0x8:
			array_offset = 0x100
		elif array_section == 0x9:
			array_offset = 0x1100
		elif array_section == 0xE:
			array_offset = 0x2100
		else:
			array_offset = 0
		
		if array_offset:
			array_offset += (input[index_input] & 0xF) << 8
			index_input += 1
			if index_input >= input.size():
				break
		
		array_offset += input[index_input]
		index_input += 1
		array_offset = array_offset << 1
		
		var unicode_value = (ShiftJISTable.conv_table[array_offset] << 8) | ShiftJISTable.conv_table[array_offset + 1]

		if unicode_value < 0x80:
			output[index_output] = unicode_value
			index_output += 1
		elif unicode_value < 0x800:
			output[index_output] = 0xC0 | (unicode_value >> 6)
			index_output += 1
			output[index_output] = 0x80 | (unicode_value & 0x3F)
			index_output += 1
		else:
			output[index_output] = 0xE0 | (unicode_value >> 12)
			index_output += 1
			output[index_output] = 0x80 | ((unicode_value & 0xFFF) >> 6)
			index_output += 1
			output[index_output] = 0x80 | (unicode_value & 0x3F)
			index_output += 1
	output.resize(index_output)
	return output

static func remove_recursive(path):
	var directory = Directory.new()
	
	# Open directory
	var error = directory.open(path)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				directory.remove(file_name)
			file_name = directory.get_next()
		
		# Remove current path
		directory.remove(path)
	else:
		print("Error removing " + path)

static func copy_recursive(from, to):
	var directory = Directory.new()
	
	# If it doesn't exists, create target directory
	if not directory.dir_exists(to):
		directory.make_dir_recursive(to)
	
	# Open directory
	var error = directory.open(from)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				copy_recursive(from + "/" + file_name, to + "/" + file_name)
			else:
				directory.copy(from + "/" + file_name, to + "/" + file_name)
			file_name = directory.get_next()
	else:
		print("Error copying " + from + " to " + to)

## Fits a given image to a certain size, compensating for aspect ratio
## if [code]crop[/code] is true then the image will be cropped as needed
## to fit the given size
static func fit_image(base_image: Image, size: Vector2, cover := false) -> Image:
	var base_image_size := base_image.get_size()
	
	var scale_factor := min(size.x / base_image_size.x, size.y / base_image_size.y)
	
	if cover:
		scale_factor = max(size.x / base_image_size.x, size.y / base_image_size.y)
	
	var base_image_copy := Image.new()
	
	base_image_copy.copy_from(base_image)
	
	base_image_copy.resize(base_image_size.x * scale_factor, base_image_size.y * scale_factor, Image.INTERPOLATE_LANCZOS)
	var blit_image_size = base_image_copy.get_size()
	
	var final_image := Image.new()
	
	var final_image_format = base_image_copy.get_format()
	
	# Since cover images get completely covered, there's no need to check if we have alpha
	# if we did have alpha it would be already set in final_image_format by this point
	if not cover:
		# If the image doesn't have alpha we have to convert it to a format that does
		if base_image_copy.detect_alpha() == Image.ALPHA_NONE:
			final_image_format = Image.FORMAT_RGBA8
			if base_image_copy.is_compressed():
				base_image_copy.decompress()
			base_image_copy.convert(final_image_format)
	
	final_image.create(size.x, size.y, false, final_image_format)
	
	var target_pos := Vector2(size.x / 2.0 - blit_image_size.x / 2.0, size.y / 2.0 - blit_image_size.y / 2.0)
	final_image.blit_rect(base_image_copy, Rect2(Vector2.ZERO, blit_image_size), target_pos)
	return final_image
	
	
static func align(value: int, alignment: int):
	return ( value + ( alignment - 1 ) ) & ~( alignment - 1 )

static func wrap_text(text: String, length: int = 25) -> String:
	var lines := [""]
	for word in text.split(" "):
		if lines[-1].length() > length:
			lines[-1].trim_prefix(" ")
			lines.append("")
		else:
			lines[-1] += " "
		
		lines[-1] += word
	
	var new_text := ""
	for line in lines:
		new_text += line
		new_text += "\n"
	
	return new_text.trim_suffix("\n")

# HACK: We have to move this here to prevent a cyclic reference,
# since EditConverter only has static stuff. I think godot 4 has
# first-class functions, so this will not be needed then.
static func _sort_by_bar(a, b) -> bool:
	return a.bar < b.bar

static func get_event_text(event: InputEvent) -> String:
	var text = "None"
	
	if event is InputEventKey:
		text = event.as_text() if not "Physical" in event.as_text() else "None"
		if "Kp " in text:
			text = text.replace("Kp ", "Keypad ")
	elif event is InputEventMouseButton:
		var modifier = ""
		
		if event.alt:
			modifier += "Alt+"
		if event.shift:
			modifier += "Shift+"
		if event.control:
			modifier += "Control+"
		if event.meta:
			modifier += "Meta+"
		
		text = modifier + MOUSE_BUTTON_NAMES[event.button_index]
	
	return text

# From cppreference
# Binary search, but always returns index of element that is above our search
static func bsearch_upper(array: Array, value: int) -> int:
	var count = array.size() - 1
	var idx = 0
	
	while count > 0:
		var step = count / 2
		
		if value >= array[idx + step]:
			idx += step + 1
			count -= step + 1
		else:
			count = step
	
	return idx

# Binary search, but always returns index of closest element to our search
static func bsearch_closest(array: Array, value: int) -> int:
	var idx: int = min(array.bsearch(value), array.size() - 1)
	
	if idx == 0 or abs(array[idx] - value) < abs(array[idx - 1] - value):
		return idx
	else:
		return idx - 1

# Binary search, but returns a linear interpolation for our search instead of an index
static func bsearch_linear(array: Array, value: int) -> float:
	var idx := array.bsearch(value)
	
	if idx + 1 >= array.size() or array[idx] == value or array[idx] == array[idx + 1]:
		return float(idx)
	
	var decimal = float(value - array[idx]) / float(array[idx + 1] - array[idx])
	return idx + decimal
