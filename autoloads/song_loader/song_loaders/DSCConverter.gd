class Opcode:
	var opcode: int
	var params = []

const MAX_31B = 1 << 31
const MAX_32B = 1 << 32

static func unsigned32_to_signed(unsigned):
	return (unsigned + MAX_31B) % MAX_32B - MAX_31B

static func load_dsc_file_from_buff(spb: StreamPeerBuffer, opcode_map: DSCOpcodeMap):
	spb.seek(4)
	var opcodes = []
	while spb.get_available_bytes() > 0:
		var opcode = spb.get_u32()
		var param_count = opcode_map.get_opcode_parameter_count(opcode)
		var params = []
		for _i in range(param_count):
			if not spb.get_available_bytes() == 0:
				var param = spb.get_32()
				params.append(unsigned32_to_signed(param))
			else:
				return null
		var opcode_obj = Opcode.new()
		opcode_obj.opcode = opcode
		opcode_obj.params = params
		opcodes.append(opcode_obj)
	return opcodes
static func load_dsc_file(path: String, opcode_map: DSCOpcodeMap):
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return []
	var spb := StreamPeerBuffer.new()
	spb.data_array = file.get_buffer(file.get_len())

	return load_dsc_file_from_buff(spb, opcode_map)

enum AFTButtons {
	TRIANGLE = 0x0,
	CIRCLE = 0x1,
	CROSS = 0x2,
	SQUARE = 0x3,
	TRIANGLE_HOLD = 0x4,
	CIRCLE_HOLD = 0x5,
	CROSS_HOLD = 0x6,
	SQUARE_HOLD = 0x7,
	SLIDE_L = 0x0C,
	SLIDE_R = 0x0D,
	CHAIN_L = 0x0F,
	CHAIN_R = 0x10,
	RAINBOW_TRIANGLE = 0x12,
	RAINBOW_CIRCLE = 0x13,
	RAINBOW_CROSS = 0x14,
	RAINBOW_SQUARE = 0x15,
	# Skip???
	RAINBOW_SLIDE_L = 0x17,
	RAINBOW_SLIDE_R = 0x18
}

enum FButtons {
	TRIANGLE = 0x0,
	CIRCLE = 0x1,
	CROSS = 0x2,
	SQUARE = 0x3,
	TRIANGLE_DOUBLE = 0x4,
	CIRCLE_DOUBLE = 0x5,
	CROSS_DOUBLE = 0x6,
	SQUARE_DOUBLE = 0x7,
	TRIANGLE_HOLD = 0x8,
	CIRCLE_HOLD = 0x9,
	CROSS_HOLD = 0xA,
	SQUARE_HOLD = 0xB,
	STAR = 0xC,
	STAR_DOUBLE = 0xD,
	CHANCE_STAR = 0xE,
	LINKED_STAR = 0xF,
	LINKED_STAR_END = 0x10
}

const F2PHButtonMap = {
	FButtons.TRIANGLE: HBBaseNote.NOTE_TYPE.UP,
	FButtons.CIRCLE: HBBaseNote.NOTE_TYPE.RIGHT,
	FButtons.CROSS: HBBaseNote.NOTE_TYPE.DOWN,
	FButtons.SQUARE: HBBaseNote.NOTE_TYPE.LEFT,
	FButtons.TRIANGLE_DOUBLE: HBBaseNote.NOTE_TYPE.UP,
	FButtons.CIRCLE_DOUBLE: HBBaseNote.NOTE_TYPE.RIGHT,
	FButtons.CROSS_DOUBLE: HBBaseNote.NOTE_TYPE.DOWN,
	FButtons.SQUARE_DOUBLE: HBBaseNote.NOTE_TYPE.LEFT,
	FButtons.TRIANGLE_HOLD: HBBaseNote.NOTE_TYPE.UP,
	FButtons.CIRCLE_HOLD: HBBaseNote.NOTE_TYPE.RIGHT,
	FButtons.CROSS_HOLD: HBBaseNote.NOTE_TYPE.DOWN,
	FButtons.SQUARE_HOLD: HBBaseNote.NOTE_TYPE.LEFT,
	FButtons.STAR: HBBaseNote.NOTE_TYPE.HEART,
	FButtons.STAR_DOUBLE: HBBaseNote.NOTE_TYPE.HEART,
	FButtons.CHANCE_STAR: HBBaseNote.NOTE_TYPE.HEART,
	FButtons.LINKED_STAR: HBBaseNote.NOTE_TYPE.HEART,
	FButtons.LINKED_STAR_END: HBBaseNote.NOTE_TYPE.HEART,
}

const AFT2PHButtonMap = {
	AFTButtons.TRIANGLE: HBBaseNote.NOTE_TYPE.UP,
	AFTButtons.CIRCLE: HBBaseNote.NOTE_TYPE.RIGHT,
	AFTButtons.CROSS: HBBaseNote.NOTE_TYPE.DOWN,
	AFTButtons.SQUARE: HBBaseNote.NOTE_TYPE.LEFT,
	AFTButtons.TRIANGLE_HOLD: HBBaseNote.NOTE_TYPE.UP,
	AFTButtons.CIRCLE_HOLD: HBBaseNote.NOTE_TYPE.RIGHT,
	AFTButtons.CROSS_HOLD: HBBaseNote.NOTE_TYPE.DOWN,
	AFTButtons.SQUARE_HOLD: HBBaseNote.NOTE_TYPE.LEFT,
	AFTButtons.SLIDE_L: HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
	AFTButtons.SLIDE_R: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
	AFTButtons.CHAIN_L: HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
	AFTButtons.CHAIN_R: HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT,
	AFTButtons.RAINBOW_TRIANGLE: HBBaseNote.NOTE_TYPE.UP,
	AFTButtons.RAINBOW_CIRCLE: HBBaseNote.NOTE_TYPE.RIGHT,
	AFTButtons.RAINBOW_CROSS: HBBaseNote.NOTE_TYPE.DOWN,
	AFTButtons.RAINBOW_SQUARE: HBBaseNote.NOTE_TYPE.LEFT,
	AFTButtons.RAINBOW_SLIDE_L: HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
	AFTButtons.RAINBOW_SLIDE_R: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
}

static func is_hold(button: int):
	return button > 3 and button < 8

static func is_double(button: int):
	return (button >= FButtons.TRIANGLE_DOUBLE and button <= FButtons.SQUARE_DOUBLE) or button == FButtons.STAR_DOUBLE

static func is_sustain(button: int):
	return button >= FButtons.TRIANGLE_HOLD and button <= FButtons.SQUARE_HOLD

static func convert_dsc_buffer_to_chart(buffer: StreamPeerBuffer, opcode_map: DSCOpcodeMap) -> HBChart:
	var r = load_dsc_file_from_buff(buffer, opcode_map)
	if not r:
		return null
	return convert_dsc_opcodes_to_chart(r, opcode_map)

static func convert_dsc_to_chart(path: String, opcode_map: DSCOpcodeMap) -> HBChart:
	var r = load_dsc_file(path, opcode_map)
	if not r:
		return null
	return convert_dsc_opcodes_to_chart(r, opcode_map)
static func convert_dsc_opcodes_to_chart(r: Array, opcode_map: DSCOpcodeMap) -> HBChart:
	var curr_time = 0.0
	var current_BPM = 0.0
	var target_flying_time = 0.0
	var chart = HBChart.new()
	var curr_chain_starter = null
	var highest_height = 0
	for opcode in r:
		if opcode.opcode == opcode_map.opcode_names_to_id.TIME:
			curr_time = float(opcode.params[0])
		if opcode.opcode == opcode_map.opcode_names_to_id.BAR_TIME_SET:
			current_BPM = float(opcode.params[0])
			target_flying_time = int((60.0  / current_BPM * (1 + float(opcode.params[1])) * 1000.0))
		if opcode.opcode == opcode_map.opcode_names_to_id.TARGET_FLYING_TIME:
			target_flying_time = int(opcode.params[0])
		if opcode.opcode == opcode_map.opcode_names_to_id.TARGET:
			if (opcode_map.game == "FT" and opcode.params[0] in AFTButtons.values()) or \
				((opcode_map.game == "f" or opcode_map.game == "F2") and opcode.params[0] in FButtons.values()):
				
				var note_d: HBBaseNote = HBNoteData.new()
				if opcode_map.game == "FT":
					note_d.position = Vector2(opcode.params[1] / 250.0, opcode.params[2] / 250.0)
					note_d.time += target_flying_time
					note_d.time_out = target_flying_time
					if opcode.params[0] in [AFTButtons.CHAIN_L, AFTButtons.CHAIN_R] and curr_chain_starter:
						if curr_chain_starter.position.y != note_d.position.y:
							curr_chain_starter = null
						else:
							if opcode.params[0] == AFTButtons.CHAIN_L:
								if curr_chain_starter.note_type != HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
									curr_chain_starter = null
							else:
								if curr_chain_starter.note_type != HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
									curr_chain_starter = null
					else:
						curr_chain_starter = null
						
					if not curr_chain_starter and opcode.params[0] in [AFTButtons.CHAIN_L, AFTButtons.CHAIN_R]:
						if opcode.params[0] == AFTButtons.CHAIN_L:
							note_d.position.x -= 20
							note_d.note_type = HBBaseNote.NOTE_TYPE.SLIDE_LEFT
						else:
							note_d.position.x += 20
							note_d.note_type = HBBaseNote.NOTE_TYPE.SLIDE_RIGHT
						curr_chain_starter = note_d
						
					else:
						var note_type = int(AFT2PHButtonMap[opcode.params[0]])
						note_d.note_type = note_type
					note_d.hold = is_hold(opcode.params[0])
					note_d.entry_angle = (opcode.params[3] / 1000.0) - 90.0
					note_d.oscillation_frequency = opcode.params[6]
					note_d.oscillation_amplitude = opcode.params[5]
					note_d.distance = opcode.params[4] / 250.0
				elif opcode_map.game in ["f", "F2"]:
					var is_hold_end = opcode.params[2] != -1
					if is_hold_end:
						continue
					if is_double(opcode.params[0]):
						note_d = HBDoubleNote.new()
					elif is_sustain(opcode.params[0]):
						note_d = HBSustainNote.new()
						(note_d as HBSustainNote).end_time = (curr_time / 100.0) + opcode.params[9] + (opcode.params[1] / 100.0)
					# F note coords are in 50:15 aspect ratio
					var diva_width = 500_000.0
					var diva_height = 250_000.0
					var diva_ratio = diva_height / diva_width
					var diva_y_offset = (1080.0 - ((diva_height / diva_width) * 1920.0)) / 4.0
					note_d.position = Vector2((opcode.params[3] / (500_000.0)) * 1920.0, (opcode.params[4] / (diva_height)) * (1920.0 * diva_ratio))
					note_d.position.y += diva_y_offset
					note_d.oscillation_amplitude = opcode.params[8]
					note_d.oscillation_frequency = opcode.params[6]
					highest_height = max(highest_height, opcode.params[3])
					note_d.entry_angle = (opcode.params[5] / 1000.0) - 90.0
					var note_type = int(F2PHButtonMap[opcode.params[0]])
					note_d.note_type = note_type
					note_d.time_out = opcode.params[9]
					note_d.time += opcode.params[9]
				note_d.time += int(curr_time / 100.0)
				note_d.auto_time_out = false
				var search_type = note_d.note_type
				if opcode_map.game == "FT" and note_d.is_slide_hold_piece():
					if note_d.note_type == HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT:
						search_type = HBBaseNote.NOTE_TYPE.SLIDE_LEFT
					else:
						search_type = HBBaseNote.NOTE_TYPE.SLIDE_RIGHT
				chart.layers[chart.get_layer_i(HBUtils.find_key(HBNoteData.NOTE_TYPE, search_type))].timing_points.append(note_d)
	return chart
