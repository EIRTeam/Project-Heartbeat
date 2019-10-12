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
static func sin_pos_interp(from: Vector2, to: Vector2, amplitude: float, frequency: float, value: float) -> Vector2:
	var dist = (from - to).length()
	value = clamp(value, 0, 1)
	if dist != 0:
		var t = value * dist
		var x = t
		var angle = from.angle_to_point(to)
		var y = amplitude * sin((t/dist)*PI*frequency)
		var xp = (x * cos(angle)) - (y * sin(angle))
		var yp = (x * sin(angle)) + (y * cos(angle))
		return from-Vector2(xp, yp)
	else:
		return to
