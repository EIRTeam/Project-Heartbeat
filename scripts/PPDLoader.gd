class_name PPDLoader

const SIGNATURE = "PPD"

static func _get_marks_from_ppd_pack(path: String):
	var pack := PPDPack.new(path)
	var index = pack.get_file_index("ppd")
	var data = _get_data_from_ppd_file(pack.file, pack.file_sizes[index], pack.file_offsets[index])
	return data
static func _get_data_from_ppd_file(file: File, file_len, file_offset):
	file.seek(file_offset)
	var signature = file.get_buffer(SIGNATURE.length()).get_string_from_utf8()
	var u = 0
	var marks = []
	
	var params = {}
	
	while file.get_position() < file_offset + file_len:
		var time = file.get_float()
		if is_nan(time):

			var count = file.get_32()
			# TODO, make engine load 
			var index = 0
			
			while file.get_position() < file_offset + file_len:
				var mark_id
				mark_id = file.get_32()
				var length = file.get_32()
				var temp = file.get_buffer(length)
				
				var xml = XMLParser.new()
				xml.open_buffer(temp)
			

				while xml.read() == OK:
					if xml.has_attribute("Key"):
						var VALUES_TO_OBTAIN = ["#RightRotation", "Distance", "Amplitude", "Frequency"]
						for value in VALUES_TO_OBTAIN:
							if xml.get_named_attribute_value("Key") == value:
								if not params.has(mark_id):
									params[mark_id] = {}
								params[mark_id][value] = xml.get_named_attribute_value("Value")

				index += 1
				if index >= count:
					break
		var x = file.get_float()
		var y = file.get_float()
		var rotation = file.get_float()
		var type = file.get_8()
		var with_ID = type >= 40
		if with_ID:
			type -= 40
		var is_EX = type >= 20
		if is_EX:
			type -= 20
		var end_time = 0
		if is_EX:
			end_time = file.get_float()
		var id = 0
		if with_ID:
			id = file.get_32()
		u+=1

		var note_data = {
			"position": Vector2(x, y),
			"time": time,
			"rotation": rotation,
			"ex": is_EX,
			"id": id,
			"type": type,
			"end_time": end_time
		}
		# TODO: Use data sector in PPD file
		if is_nan(time):
			break

		marks.append(note_data)
	return {
		"marks": marks,
		"params": params
	}

enum PPDButtons {
	Square,
	Cross,
	Circle,
	Triangle,
	Left,
	Down,
	Right,
	Up,
	R,
	L
}

static func PPD2HBChart(path: String) -> HBChart:
	var PPDButton2HBNoteType = {
		PPDButtons.Square: HBNoteData.NOTE_TYPE.LEFT,
		PPDButtons.Cross: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Circle: HBNoteData.NOTE_TYPE.RIGHT,
		PPDButtons.Triangle: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.Left: HBNoteData.NOTE_TYPE.SLIDE_LEFT,
		PPDButtons.Down: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Right: HBNoteData.NOTE_TYPE.SLIDE_RIGHT,
		PPDButtons.Up: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.R: HBNoteData.NOTE_TYPE.SLIDE_RIGHT,
		PPDButtons.L: HBNoteData.NOTE_TYPE.SLIDE_LEFT
	}
	var chart = HBChart.new()
	var data = _get_marks_from_ppd_pack(path)
	var marks = data.marks
	var params = data.params
	var prev_note
	
	# For when multiple notes are on screen, to count how many layers
	# deep we are going to ensure they don't overlap
	var same_position_note_count = 0

	for i in range(marks.size()):
		var note = marks[i]
		var note_data : HBNoteData
		
#		if note.ex:
#			note_data = HBHoldNoteData.new() as HBHoldNoteData
#			note_data.duration = int((note.end_time*1000.0) - (note.time*1000.0))
#		else:
#			note_data = HBNoteData.new()
		note_data = HBNoteData.new()
		note_data.time = int(note.time*1000.0)
		note_data.time_out = (60.0  / 250.0 * (1.0 + 3.0) * 1000.0)
		note_data.auto_time_out = true
		
		note_data.position.x = (note.position.x / 800.0) * 1920
		note_data.position.y = (note.position.y / 450.0) * 1080
		note_data.entry_angle = rad2deg(note.rotation)
		# Simulataneous notes have no amplitude
		var is_multi_note = false
		if i > 0 and note.time == marks[i-1].time:
			is_multi_note = true
		if i < marks.size()-1 and note.time == marks[i+1].time:
			is_multi_note = true
				
		note_data.note_type = PPDButton2HBNoteType[note.type]
			
		if params.has(note.id):
			var note_params = params[note.id]
			if note_params.has("Distance"):
				note_data.distance = float(note_params.Distance)/(300000.0) * 1200
			if note_params.has("Amplitude"):
				note_data.oscillation_amplitude = float(note_params.Amplitude)
			if note_params.has("Frequency"):
				note_data.oscillation_frequency = float(note_params.Frequency)
			if note_params.has("#RightRotation"):
				note_data.oscillation_frequency = -note_data.oscillation_frequency
		for l in chart.layers:
			if l.name == HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type):
				chart.layers[note_data.note_type].timing_points.append(note_data)
		prev_note = note_data

	return chart
