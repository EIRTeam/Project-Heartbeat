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
	print(signature)
	var u = 0
	var marks = []
	var right_rotation = false
	while file.get_position() < file_offset + file_len:
		var time = file.get_float()
		if is_nan(time):
			right_rotation = false

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
						if xml.get_named_attribute_value("Key") == "#RightRotation":
							if xml.get_named_attribute_value("Value") == "1":
								right_rotation = true

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
			"right_rotation": right_rotation,
			"end_time": end_time
		}
		# TODO: Use data sector in PPD file
		if is_nan(time):
			break

		marks.append(note_data)
	return marks

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
		PPDButtons.Left: HBNoteData.NOTE_TYPE.LEFT,
		PPDButtons.Down: HBNoteData.NOTE_TYPE.DOWN,
		PPDButtons.Right: HBNoteData.NOTE_TYPE.RIGHT,
		PPDButtons.Up: HBNoteData.NOTE_TYPE.UP,
		PPDButtons.R: HBNoteData.NOTE_TYPE.SLIDE_RIGHT,
		PPDButtons.L: HBNoteData.NOTE_TYPE.SLIDE_LEFT
	}
	var chart = HBChart.new()
	var layer = {"timing_points": [], "name": "New Layer"}
	var marks = _get_marks_from_ppd_pack(path)
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
		note_data.position.x = note.position.x / 800.0
		note_data.position.y = note.position.y / 450
		note_data.entry_angle = 180-rad2deg(note.rotation)
		# Simulataneous notes have no amplitude
		var is_simultaneous = false
		if i > 0 and note.time == marks[i-1].time:
			is_simultaneous = true
		if i < marks.size()-1 and note.time == marks[i+1].time:
			is_simultaneous = true
		if is_simultaneous:
			note_data.oscillation_amplitude = 0
			
		if note.right_rotation:
			print(str(i)+": ",note.right_rotation)
				
		note_data.note_type = PPDButton2HBNoteType[note.type]
		layer.timing_points.append(note_data)
	chart.layers.append(layer)
	return chart
