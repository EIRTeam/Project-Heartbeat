# Utlity PPD loader class
class_name PPDLoader

const SIGNATURE = "PPD"

static func _get_marks_from_ppd_pack(path: String):
	var pack := PPDPack.new(path)
	if not pack.valid:
		return null
	var index = pack.get_file_index("ppd")
	var data = _get_data_from_ppd_file(pack.file, pack.file_sizes[index], pack.file_offsets[index], pack)
	return data
	
# obtains notes and parameters from a ppd file
static func _get_data_from_ppd_file(file: FileAccess, file_len, file_offset, pack: PPDPack):
	file.seek(file_offset)
	var _signature = file.get_buffer(SIGNATURE.length()).get_string_from_utf8()
	#var u = 0
	var marks = []
	
	var params = {}
	var prev_time = null
	while file.get_position() < file_offset + file_len:
		var time = file.get_float()
		if is_nan(time):

			var count = file.get_32()
			# TODO, make engine load EVDs
			var index = 0
			
			while file.get_position() < file_offset + file_len:
				var mark_id
				mark_id = file.get_32()
				var length = file.get_32()
				var temp = file.get_buffer(length)
				
				var xml = XMLParser.new()
				
				# Because PPD downloader is bad
				if file_offset + file_len > file.get_length():
					# Guard against incomplete downloads
					return
				
				if xml.open_buffer(temp) != OK:
					# Something clearly went south
					return
			

				while xml.read() == OK:
					if xml.has_attribute("Key"):
#						var VALUES_TO_OBTAIN = ["#RightRotation", "Distance", "Amplitude", "Frequency"]
#						for value in VALUES_TO_OBTAIN:
						
						if xml.has_attribute("Key") and xml.has_attribute("Value"):
#							print("Obtained key %s with value %s" % [xml.get_named_attribute_value("Key"), xml.get_named_attribute_value("Value")])
							if not params.has(mark_id):
								params[mark_id] = {}
							params[mark_id][xml.get_named_attribute_value("Key")] = xml.get_named_attribute_value("Value")

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
		#u+=1
		if prev_time:
			if abs(prev_time - time) < 0.010:
				time = prev_time
		var note_data = {
			"position": Vector2(x, y),
			"time": time,
			"rotation": rotation,
			"ex": is_EX,
			"id": id,
			"type": type,
			"end_time": end_time
		}
		
		prev_time = time
		
		if is_nan(time) or note_data.end_time > 7587993123566621:
			break

		marks.append(note_data)
	# read EVD file


	var index = pack.get_file_index("evd")
	var evd_file = PPDEVDFile.new()
	evd_file.from_file(pack.file, pack.file_sizes[index], pack.file_offsets[index])
	return {
		"marks": marks,
		"params": params,
		"evd_file": evd_file
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

enum PPDNoteType {
	NORMAL,
	AC,
	ACFT
}

const PPDButtonsMapACFT = {
		PPDButtons.Square: HBNoteData.NOTE_TYPE.LEFT,
		PPDButtons.Cross: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Circle: HBNoteData.NOTE_TYPE.RIGHT,
		PPDButtons.Triangle: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.Left: HBNoteData.NOTE_TYPE.LEFT,
		PPDButtons.Down: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Right: HBNoteData.NOTE_TYPE.RIGHT,
		PPDButtons.Up: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.R: HBNoteData.NOTE_TYPE.SLIDE_RIGHT,
		PPDButtons.L: HBNoteData.NOTE_TYPE.SLIDE_LEFT
	}

const PPDButtonsMapDefault = {
		PPDButtons.Square: HBNoteData.NOTE_TYPE.LEFT,
		PPDButtons.Cross: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Circle: HBNoteData.NOTE_TYPE.RIGHT,
		PPDButtons.Triangle: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.Left: HBNoteData.NOTE_TYPE.LEFT,
		PPDButtons.Down: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Right: HBNoteData.NOTE_TYPE.RIGHT,
		PPDButtons.Up: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.R: HBNoteData.NOTE_TYPE.HEART,
		PPDButtons.L: HBNoteData.NOTE_TYPE.HEART
	}

const PHButtonToPPDDirection = {
	HBNoteData.NOTE_TYPE.LEFT: PPDButtons.Left,
	HBNoteData.NOTE_TYPE.UP: PPDButtons.Up,
	HBNoteData.NOTE_TYPE.DOWN: PPDButtons.Down,
	HBNoteData.NOTE_TYPE.RIGHT: PPDButtons.Right,
}

static func _apply_note_params(note_data: HBBaseNote, note_params: Dictionary) -> HBBaseNote:
	if note_params.has("Distance"):
		note_data.distance = float(note_params.Distance)/(300000.0) * 1200
	if note_params.has("Amplitude"):
		note_data.oscillation_amplitude = float(note_params.Amplitude)
	if note_params.has("Frequency"):
		if fmod(float(note_params.Frequency), 2) == 0:
			note_data.oscillation_frequency = -float(note_params.Frequency)
		else:
			note_data.oscillation_frequency = float(note_params.Frequency)
	if note_params.has("#RightRotation"):
		note_data.oscillation_frequency = -note_data.oscillation_frequency
	return note_data

static func PPD2HBChart(path: String, base_bpm: int, offset = 0) -> HBChart:
	var bpm = base_bpm
	# PPD button map to PH buttons
	var PPDButton2HBNoteType = PPDButtonsMapDefault
	
	var chart = HBChart.new()
	var data = _get_marks_from_ppd_pack(path)
	if not data:
		return chart
	var marks = data.marks
	var params = data.params
	var prev_note
	
	var evd_file = data.evd_file as PPDEVDFile

	var i = 0
	while i < marks.size():
		var note = marks[i]
		var note_data : HBBaseNote
		var note_type = PPDNoteType.NORMAL
		if evd_file.get_note_type_at_time(note.time) >= PPDNoteType.AC:
			PPDButton2HBNoteType = PPDButtonsMapACFT
			note_type = PPDNoteType.ACFT
		else:
			PPDButton2HBNoteType = PPDButtonsMapDefault
		
#		if note.ex:
#			note_data = HBHoldNoteData.new() as HBHoldNoteData
#			note_data.duration = int((note.end_time*1000.0) - (note.time*1000.0))
#		else:
#			note_data = HBNoteData.new()
		note_data = HBNoteData.new()
		if note.type > PPDButtons.Triangle and note.type < PPDButtons.R and note_type == PPDNoteType.NORMAL:
			note_data = HBDoubleNote.new()
		elif note_type == PPDNoteType.NORMAL and note.end_time != 0.0 and not note.type == PPDButtons.L and not note.type == PPDButtons.R:
			note_data = HBSustainNote.new()
			note_data.end_time = int(note.end_time*1000.0) + int(offset)
		
		var is_multi_note = false
		var had_double_note = false
		
		# PPD is stupid and in some chart double notes are marked by Triangle+Up for example.
		if note_type == PPDNoteType.NORMAL:
			if prev_note and (prev_note.note_type < 4 or prev_note.note_type == HBBaseNote.NOTE_TYPE.HEART):
				var prev_type = prev_note.note_type
				var current_type = PPDButton2HBNoteType[note.type]
				var current_time = int(note.time*1000.0) + int(offset)
				if current_type == prev_type and current_time == prev_note.time:
					note_data = note_data.convert_to_type("DoubleNote")
					var type = HBUtils.find_key(HBNoteData.NOTE_TYPE, prev_note.note_type)
					chart.layers[chart.get_layer_i(type)].timing_points.pop_back()
					is_multi_note = false
					had_double_note = true
		
		note_data.oscillation_frequency = -note_data.oscillation_frequency
		
		note_data.time = int(note.time*1000.0) + int(offset)
		note_data.auto_time_out = true
		
		note_data.position.x = (note.position.x / 800.0) * 1920
		note_data.position.y = (note.position.y / 450.0) * 1080
		note_data.entry_angle = 360 - rad_to_deg(note.rotation)
		
		note_data.pos_modified = true
		
		var is_second_slider = false
		
		note_data.note_type = PPDButton2HBNoteType[note.type]
		
		if not had_double_note and i > 0 and note.time == marks[i-1].time:
			is_multi_note = true
			# Checking for two sliders of the same direction
			if note_data.note_type == HBNoteData.NOTE_TYPE.UP:
				if PPDButton2HBNoteType[marks[i-1].type] == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
					note_data.note_type = HBNoteData.NOTE_TYPE.SLIDE_LEFT
					is_second_slider = true
			if note_data.note_type == HBNoteData.NOTE_TYPE.RIGHT:
				if PPDButton2HBNoteType[marks[i-1].type] == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
					note_data.note_type = HBNoteData.NOTE_TYPE.SLIDE_RIGHT
					is_second_slider = true
		if not had_double_note and i < marks.size()-1 and note.time == marks[i+1].time:
			is_multi_note = true
			if note_data.note_type == HBNoteData.NOTE_TYPE.UP:
				if PPDButton2HBNoteType[marks[i+1].type] == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
					note_data.note_type = HBNoteData.NOTE_TYPE.SLIDE_LEFT
					is_second_slider = true
			if note_data.note_type == HBNoteData.NOTE_TYPE.RIGHT:
				if PPDButton2HBNoteType[marks[i+1].type] == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
					note_data.note_type = HBNoteData.NOTE_TYPE.SLIDE_RIGHT
					is_second_slider = true
		
		# Simulataneous notes have no amplitude
		if is_multi_note:
			note_data.oscillation_amplitude = 0
			note_data.distance = note_data.distance * (2.2/3.0)

		if params.has(note.id):
			var note_params = params[note.id]
			_apply_note_params(note_data, note_params)
		if note_type <= PPDNoteType.AC:
			is_second_slider = false
		if is_second_slider:
			chart.editor_settings.set_layer_visibility(true, HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type) + "2")
		
		# We add the note to the layer
		for l in chart.layers:
			if l.name == HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type):
				if is_second_slider:
					chart.layers[chart.get_layer_i(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type) + "2")].timing_points.append(note_data)
				else:
					var type = HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)
					chart.layers[chart.get_layer_i(type)].timing_points.append(note_data)
		
		# Chain slides
		if note_type == PPDNoteType.ACFT and note_data is HBNoteData and note.has("end_time") and note_data.is_slide_note():
			var ppd_scale = evd_file.get_slide_scale_at_time(note.time)
			
			# This thing right here was provided by Blizzin, all issues caused by it should be forwarded
			# to him, he's available at Blizzin#4483
			var note_scale = ppd_scale / (bpm / 180.0)
			
			var beats = (bpm / 60.0) * (note.end_time - note.time)
			var pieces_per_note = 32.0 * note_scale
			# Asuming chain slide pieces are done to the 32th
			var time_interval = (7500 / float(bpm)) / note_scale
			var initial_x_offset = 48
			var interval_x_offset = 32
			var notes_to_create = round(beats * (pieces_per_note/4.0))
			var starting_time = note_data.time
			for ii in range(notes_to_create):
				var note_time = starting_time + ((ii+1) * time_interval)
				var note_position = note_data.position
				var position_increment = initial_x_offset + interval_x_offset * ii
				var new_note_type = HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
				if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
					position_increment *= -1
					new_note_type = HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT
				note_position.x += position_increment
				var new_note = note_data.clone()
				new_note.note_type = new_note_type
				new_note.time = note_time
				new_note.position = note_position
				chart.layers[note_data.note_type].timing_points.append(new_note)
		elif note.ex and note_type == PPDNoteType.ACFT and not note_data.is_slide_note():
			note_data.hold = true
			
		prev_note = note_data
		i += 1
	return chart
