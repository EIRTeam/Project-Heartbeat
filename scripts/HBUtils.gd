class_name HBUtils

enum TimeFormat {
	FORMAT_HOURS   = 1 << 0,
	FORMAT_MINUTES = 1 << 1,
	FORMAT_SECONDS = 1 << 2,
	FORMAT_MILISECONDS = 1 << 3,
	FORMAT_DEFAULT = 1 << 1 | 1 << 2 | 1 << 3
}

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


# Interpolates from a to b along a sine wave
static func sin_pos_interp(from: Vector2, to: Vector2, amplitude: float, frequency: float, value: float, phase_shift_angle: float = 0.0) -> Vector2:
	var dist = (from - to).length()
	value = clamp(value, 0, 1)
	var period = 1/frequency
	var phase_shift = (phase_shift_angle/180.0)*(period)
	if dist != 0:
		var t = value * dist
		var x = t
		var angle = from.angle_to_point(to)
		var y = amplitude * sin((((t/dist) + phase_shift)*(PI*frequency)))
		var xp = (x * cos(angle)) - (y * sin(angle))
		var yp = (x * sin(angle)) + (y * cos(angle))
		return from-Vector2(xp, yp)
	else:
		return to

# Converts a string from being complex to snake case
static func get_valid_filename(value: String):
	# Convert to ascii to strip most characters
	value = value.strip_edges().replace(' ', '_')
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	return regex.sub(value, "", true).to_lower()
	
static func load_ogg(path: String) -> AudioStreamOGGVorbis:
	var ogg_file = File.new()
	ogg_file.open(path, File.READ)
	var bytes = ogg_file.get_buffer(ogg_file.get_len())
	var stream = AudioStreamOGGVorbis.new()
	stream.data = bytes
	ogg_file.close()
	return stream
