const REGION = {
	"JPN": 0x13121505,
	"ENG": 0x14062614,
}

const TIME_SIGNATURE = {
	"DUPLE": 0x01,
	"TRIPLE": 0x02,
	"QUADRUPLE": 0x03,
}

const NOTE_TYPE = {
	"TRIANGLE": 0x00,
	"CIRCLE": 0x01,
	"CROSS": 0x02,
	"SQUARE": 0x03,
	"DOUBLE_TRIANGLE": 0x04,
	"DOUBLE_CIRCLE": 0x05,
	"DOUBLE_CROSS": 0x06,
	"DOUBLE_SQUARE": 0x07,
	"TRIANGLE_SUSTAIN": 0x08,
	"CIRCLE_SUSTAIN": 0x09,
	"CROSS_SUSTAIN": 0x0A,
	"SQUARE_SUSTAIN": 0x0B,
	"STAR": 0x0C,
	"DOUBLE_STAR": 0x0E,
	"CHANCE_STAR": 0x0F,
	"EDIT_CHANCE_STAR": 0x10,
	"LINK_STAR": 0x16,
	"LINK_STAR_END": 0x17,
}

const normal_notes = {
	NOTE_TYPE.SQUARE: HBBaseNote.NOTE_TYPE.LEFT,
	NOTE_TYPE.CIRCLE: HBBaseNote.NOTE_TYPE.RIGHT,
	NOTE_TYPE.CROSS: HBBaseNote.NOTE_TYPE.DOWN,
	NOTE_TYPE.TRIANGLE: HBBaseNote.NOTE_TYPE.UP,
	NOTE_TYPE.STAR: HBBaseNote.NOTE_TYPE.HEART,
	NOTE_TYPE.LINK_STAR: HBBaseNote.NOTE_TYPE.HEART,
	NOTE_TYPE.LINK_STAR_END: HBBaseNote.NOTE_TYPE.HEART,
	NOTE_TYPE.CHANCE_STAR: HBBaseNote.NOTE_TYPE.HEART,
	NOTE_TYPE.EDIT_CHANCE_STAR: HBBaseNote.NOTE_TYPE.HEART,
}

const double_notes = {
	NOTE_TYPE.DOUBLE_SQUARE: HBBaseNote.NOTE_TYPE.LEFT,
	NOTE_TYPE.DOUBLE_CIRCLE: HBBaseNote.NOTE_TYPE.RIGHT,
	NOTE_TYPE.DOUBLE_CROSS: HBBaseNote.NOTE_TYPE.DOWN,
	NOTE_TYPE.DOUBLE_TRIANGLE: HBBaseNote.NOTE_TYPE.UP,
	NOTE_TYPE.DOUBLE_STAR: HBBaseNote.NOTE_TYPE.HEART,
}

const sustain_notes = {
	NOTE_TYPE.SQUARE_SUSTAIN: HBBaseNote.NOTE_TYPE.LEFT,
	NOTE_TYPE.CIRCLE_SUSTAIN: HBBaseNote.NOTE_TYPE.RIGHT,
	NOTE_TYPE.CROSS_SUSTAIN: HBBaseNote.NOTE_TYPE.DOWN,
	NOTE_TYPE.TRIANGLE_SUSTAIN: HBBaseNote.NOTE_TYPE.UP,
}

const MAX_31B = 1 << 31
const MAX_32B = 1 << 32

static func unsigned32_to_signed(unsigned):
	return (unsigned + MAX_31B) % MAX_32B - MAX_31B

static func pv_time_to_ms(pv_time: int):
	# 72k pv time units: 20 mins
	return (pv_time * 20.0) / 72000.0

static func swap_endianness(src: PackedByteArray):
	var out = src
	
	var i = 0
	while i < src.size():
		out[i] = src[i+1]
		out[i+1] = src[i]
		i += 2
	
	return out

static func diva_pos_to_pixels(x, y):
	var diva_width = 500_000.0
	var diva_height = 250_000.0
	var diva_ratio = diva_height / diva_width
	
	var position = Vector2((x/ (500_000.0)) * 1920.0, (y / (diva_height)) * (1920.0 * diva_ratio))
	
	return position

static func get_bpm_at_bar(bar, bpm_changes):
	var bpm = bpm_changes[0].bpm
	for bpm_change in bpm_changes:
		if bpm_change.bar > bar:
			break
		else:
			bpm = bpm_change.bpm
	
	return float(bpm)

static func get_signature_at_bar(bar, sig_changes):
	var sig = sig_changes[0].sig
	for sig_change in sig_changes:
		if sig_change.bar > bar:
			break
		else:
			sig = sig_change.sig
	
	return float(sig + 1)

static func edit_time_to_ms(bar: int, beat: int, bpm_changes: Array, signature_changes: Array):
	if not bpm_changes or not signature_changes:
		print("ERROR: Missing BPM or signature changes.")
		return
	
	var bpm = float(bpm_changes[0].bpm)
	var sig = float(signature_changes[0].sig + 1)
	var time = 0
	
	for i in range(bar):
		bpm = get_bpm_at_bar(i, bpm_changes)
		sig = get_signature_at_bar(i, signature_changes)
		
		time += (60.0 / bpm) * sig
	
	if beat:
		bpm = get_bpm_at_bar(bar, bpm_changes)
		sig = get_signature_at_bar(bar, signature_changes)
		
		# In ScriptEditor, this 4.0 is replaced by sig. However, this messes up the timings of
		# sections with a time signature other than 4. Using 4 fixes it, somehow. Dont ask me why tho.
		time += (60.0 / bpm) / 192.0 * 4.0 * beat
	
	return round(time * 1000.0)


static func convert_edit_to_chart(file_path: String, offset: int, convert_link_stars: bool) -> Array:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		print("ERROR: Invalid file.")
		return [null, []]
	file.big_endian = true
	
	# Header data
	var magic_bytes = 0x00000064
	if file.get_32() != magic_bytes:
		print("ERROR: Invalid header.")
		return [null, []]
	
	var region = file.get_32()
	var _checksum = file.get_32() # CRC 32 checksum data
	var _checksum_range = file.get_32()
	
	# Metadata
	var _region_2 = file.get_32() # Why 2 regions? TODO: Ask in modding 2nd
	var _size = file.get_32()
	
	var table_size = unsigned32_to_signed(file.get_32())
	if table_size != 1576:
		# ?????
		return [null, []]
	
	var _displayed_bpm = file.get_float()
	
	# We skip an u32 and 4 u16 fields
	for _i in range(3):
		file.get_32()
	
	var _stars = file.get_8() / 2.0
	
	# We skip a 35-byte undocumented chunk
	file.get_buffer(35)
	
	var _end_time = pv_time_to_ms(unsigned32_to_signed(file.get_32()))
	
	# We skip 13 u32 fields and 2 u32 undocumented fields
	for _i in range(15):
		file.get_32()
	
	# We skip a 24-byte undocumented chunk
	file.get_buffer(24)
	
	var _start_time = file.get_float() # Is this even needed?
	
	# We skip a 38-byte undocumented chunk
	file.get_buffer(38)
	
	var _charter_raw = swap_endianness(file.get_buffer(38))
	#var charter = charter_raw.get_string_from_utf16()
	
	# We skip a 182 byte field, a 194 byte one, a 62 byte field, 6 byte-sized fields, a 142 byte undocumented field, a 150 byte field and another 84 byte undocumented field
	# Phew, thats a lot
	file.get_buffer(182 + 194 + 64 + 6 + 140 + 150 + 84)
	
	var _name_raw = swap_endianness(file.get_buffer(74))
	#var name = name_raw.get_string_from_utf16()
	
	# 450 byte long undocumented crap
	file.get_buffer(450)
	
	var bpm_changes_size = unsigned32_to_signed(file.get_32())
	var bpm_changes = []
	for _i in range(bpm_changes_size):
		var bar = file.get_32()
		var bpm = file.get_float()
		bpm_changes.append({"bar": bar, "bpm": bpm})
	
	var time_signature_changes_size = unsigned32_to_signed(file.get_32())
	var time_signature_changes = []
	for _i in range(time_signature_changes_size):
		var bar = file.get_32()
		var signature = file.get_32()
		time_signature_changes.append({"bar": bar, "sig": signature})
	
	var markers_size = unsigned32_to_signed(file.get_32())
	var markers = []
	for _i in range(markers_size):
		var bar = file.get_32()
		var color = file.get_32()
		markers.append({"bar": bar, "color": color})
	
	var tuplets_size = unsigned32_to_signed(file.get_32())
	file.get_buffer(12 * tuplets_size)
	
	var pv_bases_size = unsigned32_to_signed(file.get_32())
	file.get_buffer(pv_bases_size)
	
	var layers_size = unsigned32_to_signed(file.get_32())
	file.get_buffer(layers_size)
	
	for _i in range(3):
		var show_module_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(8 * show_module_table_size)
	
	for _i in range(3):
		var show_misc_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(12 * show_misc_table_size)
		
	for _i in range(3):
		var show_shadow_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(8 * show_shadow_table_size)
	
	for _i in range(3):
		var position_table_size = unsigned32_to_signed(file.get_32())
		for _j in range(position_table_size):
			file.get_buffer(12)
			for _k in range(6):
				file.get_float()
			file.get_buffer(12)
	
	for _i in range(3):
		var motion_table_size = unsigned32_to_signed(file.get_32())
		for _j in range(motion_table_size):
			file.get_buffer(8)
			file.get_float()
			file.get_buffer(8)
			file.get_float()
			file.get_buffer(20)
	
	for _i in range(3):
		var expression_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(16 * expression_table_size)
	
	for _i in range(3):
		# POSSIBLE ISSUE
		var left_hand_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(16 * left_hand_table_size)
		var right_hand_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(16 * right_hand_table_size)
	
	for _i in range(3):
		var line_of_sight_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(16 * line_of_sight_table_size)
	
	for _i in range(3):
		var blink_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(16 * blink_table_size)
	
	for _i in range(3):
		var face_effect_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(12 * face_effect_table_size)
	
	for _i in range(3):
		var lipsync_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(16 * lipsync_table_size)
	
	for _i in range(3):
		var item_table_size = unsigned32_to_signed(file.get_32())
		file.get_buffer(32 * item_table_size)
	
	var camera_changes_size = unsigned32_to_signed(file.get_32())
	for _i in range(camera_changes_size):
		file.get_buffer(6)
		var camera_key_points_size = file.get_8()
		file.get_8()
		for _j in range(camera_key_points_size):
			for _k in range(20):
				file.get_float()
			file.get_buffer(8)
	
	var stage_changes_size = unsigned32_to_signed(file.get_32())
	file.get_buffer(20 * stage_changes_size)
	
	var lyrics_size = unsigned32_to_signed(file.get_32())
	if region == REGION.JPN:
		file.get_buffer(92 * lyrics_size)
	elif region == REGION.ENG:
		file.get_buffer(136 * lyrics_size)
	
	var fades_size = unsigned32_to_signed(file.get_32())
	for _i in range(fades_size):
		file.get_float()
		file.get_float()
		file.get_float()
		file.get_float()
		file.get_float()
	
	var effects_size = unsigned32_to_signed(file.get_32())
	for _i in range(effects_size):
		file.get_buffer(12)
		file.get_float()
		file.get_float()
		file.get_32()
	
	
	# Create notes and other timing points
	var notes_count = unsigned32_to_signed(file.get_32())
	var notes = []
	var previous_link_star = null
	for _i in range(notes_count):
		var bar = file.get_16()
		var beat = file.get_16()
		
		# Unknown
		file.get_buffer(4)
		
		var raw_type = file.get_32()
		
		var x_pos = file.get_float() * 362.5
		var y_pos = file.get_float() * 362.5
		
		var position = diva_pos_to_pixels(x_pos, y_pos)
		
		var entry_angle = file.get_float() + 270.0
		
		var sustain_end_bar = file.get_16()
		var sustain_end_beat = file.get_16()
		
		var time = edit_time_to_ms(bar, beat, bpm_changes, time_signature_changes)
		
		var note_data
		
		if raw_type in normal_notes:
			note_data = HBNoteData.new()
			note_data.note_type = normal_notes[raw_type]
		elif raw_type in double_notes:
			note_data = HBDoubleNote.new()
			note_data.note_type = double_notes[raw_type]
		elif raw_type in sustain_notes:
			note_data = HBSustainNote.new()
			note_data.note_type = sustain_notes[raw_type]
		else:
			continue
		
		note_data.pos_modified = true
		
		if raw_type in [NOTE_TYPE.LINK_STAR, NOTE_TYPE.LINK_STAR_END]:
			if previous_link_star:
				entry_angle = rad_to_deg(position.angle_to_point(previous_link_star.position)) + 90
				
				if convert_link_stars:
					entry_angle += 90
					note_data.oscillation_frequency = 0
					note_data.distance = position.distance_to(previous_link_star.position)
					note_data.auto_time_out = false
					note_data.time_out = time - previous_link_star.time
		
		note_data.time = time + offset
		note_data.position = position
		note_data.entry_angle = entry_angle
		if note_data is HBSustainNote:
			note_data.end_time = edit_time_to_ms(sustain_end_bar, sustain_end_beat, bpm_changes, time_signature_changes) + offset
		
		notes.append(note_data)
		
		if raw_type == NOTE_TYPE.LINK_STAR:
			previous_link_star = note_data.clone()
		elif raw_type == NOTE_TYPE.LINK_STAR_END:
			previous_link_star = null
	
	# HACK: This is a weird way to merge the tempo changes, but I dont think I can write
	# something thats more elegant.
	var tempo_changes = []
	var _tempo_changes = bpm_changes + time_signature_changes
	_tempo_changes.sort_custom(Callable(HBUtils, "_sort_by_bar"))
	
	var last_tempo_change
	for tempo_change in _tempo_changes:
		if not last_tempo_change:
			last_tempo_change = tempo_change
			
			continue
		
		if last_tempo_change.bar == tempo_change.bar:
			tempo_change = HBUtils.merge_dict(last_tempo_change, tempo_change)
			
			last_tempo_change = null
		
		tempo_changes.append(tempo_change)
	
	var ingame_timing_changes = []
	var current_bpm := 120.0
	var current_time_sig := 4.0
	
	for tempo_change in tempo_changes:
		if tempo_change.has("bpm"):
			current_bpm = tempo_change.bpm
		if tempo_change.has("sig"):
			current_time_sig = tempo_change.sig + 1
		
		var timing_point := HBTimingChange.new()
		timing_point.time = edit_time_to_ms(tempo_change.bar, 0, bpm_changes, time_signature_changes)
		timing_point.bpm = current_bpm
		timing_point.time_signature.numerator = current_time_sig
		
		ingame_timing_changes.append(timing_point)
	
	# Populate the chart
	var chart := HBChart.new()
	var note_type_to_layers_map = {}
	for layer in chart.layers:
		if not layer.name in ["Events", "Lyrics", "Sections"] and not "2" in layer.name:
			note_type_to_layers_map[HBBaseNote.NOTE_TYPE[layer.name]] = chart.layers.find(layer)
	
	for note_data in notes:
		var layer_idx = note_type_to_layers_map[note_data.note_type]
		chart.layers[layer_idx].timing_points.append(note_data)
	
	return [chart, ingame_timing_changes]
