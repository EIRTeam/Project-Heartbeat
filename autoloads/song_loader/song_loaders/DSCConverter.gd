const DSCOpcodeMap = preload("DSCOpcodeMap.gd")

class Opcode:
	var opcode: int
	var params = []

const MAX_31B = 1 << 31
const MAX_32B = 1 << 32

static func unsigned32_to_signed(unsigned):
	return (unsigned + MAX_31B) % MAX_32B - MAX_31B

static func load_dsc_file(path: String):
	var file = File.new()
	file.open(path, File.READ)
	var opcodes = []
	while !file.eof_reached():
		var opcode = unsigned32_to_signed(file.get_32())
		var param_count = DSCOpcodeMap.get_opcode_parameter_count(opcode)
		var params = []
		for _i in range(param_count):
			if not file.eof_reached():
				var param = file.get_32()
				params.append(unsigned32_to_signed(param))
			else:
				return null
		var opcode_obj = Opcode.new()
		opcode_obj.opcode = opcode
		opcode_obj.params = params
		opcodes.append(opcode_obj)
	return opcodes

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
	CHAIN_R = 0x10
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
	AFTButtons.CHAIN_L: HBBaseNote.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
	AFTButtons.CHAIN_R: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE,
}

static func is_hold(button: int):
	return button > 3 and button < 8


static func convert_dsc_to_chart(path: String) -> HBChart:
	var r = load_dsc_file(path)
	if not r:
		return null
	var curr_time = 0.0
	var current_BPM = 0.0
	var target_flying_time = 0.0
	var chart = HBChart.new()
	var curr_chain_starter = null
	for opcode in r:
		if opcode.opcode == DSCOpcodeMap.AFT_OPCODES.TIME:
			curr_time = float(opcode.params[0])
		if opcode.opcode == DSCOpcodeMap.AFT_OPCODES.BAR_TIME_SET:
			current_BPM = float(opcode.params[0])
			target_flying_time = int((60.0  / current_BPM * (1 + 3) * 1000.0))
		if opcode.opcode == DSCOpcodeMap.AFT_OPCODES.TARGET_FLYING_TIME:
			target_flying_time = int(opcode.params[0])
		if opcode.opcode == DSCOpcodeMap.AFT_OPCODES.TARGET:
			if opcode.params[0] in AFTButtons.values():
				
				var note_d := HBNoteData.new()
				note_d.position = Vector2(opcode.params[1] / 250.0, opcode.params[2] / 250.0)
				note_d.time = int(curr_time / 100.0)
				note_d.time += target_flying_time
				
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
				note_d.time_out = target_flying_time
					
					
				note_d.auto_time_out = false
				var search_type = note_d.note_type
				if note_d.is_slide_hold_piece():
					if note_d.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE:
						search_type = HBBaseNote.NOTE_TYPE.SLIDE_LEFT
					else:
						search_type = HBBaseNote.NOTE_TYPE.SLIDE_RIGHT
				chart.layers[chart.get_layer_i(HBUtils.find_key(HBNoteData.NOTE_TYPE, search_type))].timing_points.append(note_d)
	return chart
