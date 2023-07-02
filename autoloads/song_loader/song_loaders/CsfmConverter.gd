##################################
#       METADATA STRUCTURE       #
##################################
#
#	Data start (0x00000150)
#	├── Metadata
#	│   ├── Song file name: String
#	│   ├── Movie file name: String
#	│   ├── Artist: String
#	│   ├── Track number: String
#	│   ├── Disk number: String
#	│   └── Song title: String
#	├── Chart
#	│   ├── Scale
#	│   │   └── Seems to have an entry in an array for each note type. I dont quite understand what it does tho ¯\_(ツ)_/¯
#	│   ├── Time
#	│   │   ├── Song offset: f64
#	│   │   ├── Movie offset: f64
#	│   │   ├── Duration: f64
#	│   │   ├── Song preview start: f64
#	│   │   └── Song preview duration: f64
#	│   ├── Targets (+ target count)
#	│   │   ├── Tick: Pointer with size and total size
#	│   │   ├── Type: Pointer with size and total size
#	│   │   ├── Properties: Pointer with size and total size ("Use preset")
#	│   │   ├── Hold: Pointer with size and total size
#	│   │   ├── Chain: Pointer with size and total size
#	│   │   ├── Chance: Pointer with size and total size
#	│   │   ├── Position: Pointer with size and total size
#	│   │   ├── Angle: Pointer with size and total size
#	│   │   ├── Frequency: Pointer with size and total size
#	│   │   ├── Amplitude: Pointer with size and total size
#	│   │   └── Distance: Pointer with size and total size
#	│   ├── Tempo maps (+ tempo map count)
#	│   │   ├── Tempo: Pointer with size and total size
#	│   │   ├── Flying distance factor: Pointer with size and total size
#	│   │   ├── Time signature: Pointer with size and total size
#	│   │   └── Flags: Pointer with size and total size
#	│   ├── Button sounds (Everything here is in an array)
#	│   │   ├── Button: u32
#	│   │   ├── Slide: u32
#	│   │   ├── Chain slide: u32
#	│   │   └── Slider touch: u32
#	│   └── Difficulty (Everything here is in an array)
#	│       ├── Difficulty index: u8
#	│       ├── Padding: u8
#	│       ├── Whole stars: u8
#	│       └── Decimal stars: u8
#	└── Debug (Reserved)

extends Object

const NOTE_TYPE = {
	"TRIANGLE": 0x00,
	"SQUARE": 0x01,
	"CROSS": 0x02,
	"CIRCLE": 0x03,
	"SLIDE_LEFT": 0x04,
	"SLIDE_RIGHT": 0x05,
}

const note_types_to_hb = {
	NOTE_TYPE.TRIANGLE: HBBaseNote.NOTE_TYPE.UP,
	NOTE_TYPE.SQUARE: HBBaseNote.NOTE_TYPE.LEFT,
	NOTE_TYPE.CROSS: HBBaseNote.NOTE_TYPE.DOWN,
	NOTE_TYPE.CIRCLE: HBBaseNote.NOTE_TYPE.RIGHT,
	NOTE_TYPE.SLIDE_LEFT: HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
	NOTE_TYPE.SLIDE_RIGHT: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
}

const property_types = {
	"Tick": "u32",
	"Type": "u8",
	"Properties": "b8",
	"Hold": "b8",
	"Chain": "b8",
	"Chance": "b8",
	"Position": "vector2",
	"Angle": "f32",
	"Frequency": "f32",
	"Amplitude": "f32",
	"Distance": "f32",
	"Tempo": "f32",
	"Flying Time Factor": "f32",
	"Time Signature": "ratio",
	"Flags": "bitfield"
}

static func musical_time_to_ms(beat: int, timing_changes: Array):
	if not timing_changes:
		print("ERROR: Missing timing changes.")
		return
	
	var time = 0
	for i in range(timing_changes.size()):
		var timing_change = timing_changes[i]
		
		if timing_change.time < beat:
			var range_end := beat
			if i + 1 < timing_changes.size():
				range_end = min(range_end, timing_changes[i + 1].time)
			
			var bpm = timing_change.bpm
			var dt = range_end - timing_change.time
			
			# Note to future me: Time sig isnt used.
			# BPMs assume a 4/4 sig (Hence the 4).
			time += (60.0 / bpm) / 192.0 * 4.0 * dt
	
	return round(time * 1000.0)

static func get_count_and_pointer(file: FileAccess, address: int = 0):
	var original_address = file.get_position()
	if address:
		file.seek(address)
	
	var count := file.get_64()
	var data_address := file.get_64()
	file.get_buffer(16) # Padding
	
	if address:
		file.seek(original_address)
	return {"count": count, "address": data_address}

static func get_entry_count_field_count_and_pointer(file: FileAccess, address: int = 0):
	var original_address = file.get_position()
	if address:
		file.seek(address)
	
	var entry_count := file.get_64()
	var field_count := file.get_64()
	var data_address := file.get_64()
	file.get_buffer(8) # Padding
	
	if address:
		file.seek(original_address)
	return {"entry_count": entry_count, "field_count": field_count, "address": data_address}

static func get_string(file: FileAccess, address: int):
	var original_address = file.get_position()
	file.seek(address)
	
	var data := []
	var byte = 1
	while byte != 0:
		byte = file.get_8()
		data.append(byte)
	
	file.seek(original_address)
	return PackedByteArray(data).get_string_from_ascii()

static func get_data(file: FileAccess):
	var name_address := file.get_64()
	var name = get_string(file, name_address)
	var data := {"name": name.to_lower().replace(" ", "_"), "data": null}
	
	match name:
		"Metadata", "Chart", "Time":
			data.data = {}
			var address := file.get_64()
			var array_info = get_count_and_pointer(file, address)
			
			var original_address = file.get_position()
			file.seek(array_info.address)
			for _i in range(array_info.count):
				var entry = get_data(file)
				
				data.data[entry.name] = entry.data
			
			file.seek(original_address)
		"Song File Name", "Movie File Name", "Cover File Name", "Logo File Name", "Background File Name", "Track Number", "Disk Number", "Song Title", "Album", "Artist", "Lyricist", "Arranger", "Creator Name", "Creator Comment":
			var address = file.get_64()
			data.data = get_string(file, address)
		"Extra Info Key 0", "Extra Info Value 0", "Extra Info Key 1", "Extra Info Value 1", "Extra Info Key 2", "Extra Info Value 2", "Extra Info Key 3", "Extra Info Value 3":
			var address = file.get_64()
			data.data = get_string(file, address)
		"Song Offset", "Movie Offset", "Duration", "Song Preview Start", "Song Preview Duration":
			data.data = file.get_double()
		"Button Sounds":
			data.data = []
			var address := file.get_64()
			var array_info = get_count_and_pointer(file, address)
			
			var original_address = file.get_position()
			file.seek(array_info.address)
			for _i in range(array_info.count):
				data.data.append(file.get_32())
			
			file.seek(original_address)
		"Difficulty":
			var address := file.get_64()
			var original_address = file.get_position()
			file.seek(address)
			
			var diff_index := file.get_16()
			var whole_stars := file.get_8()
			var decimal_stars := file.get_8()
			
			file.seek(original_address)
			
			var stars := whole_stars + decimal_stars / 10.0
			data.data = {"difficulty": diff_index, "stars": stars}
		"Scale":
			file.get_64() # Lol not touching that shit
		"Targets", "Tempo Map":
			var address := file.get_64()
			var array_info = get_entry_count_field_count_and_pointer(file, address)
			data.data = {"entry_count": array_info.entry_count}
			
			var original_address = file.get_position()
			file.seek(array_info.address)
			for _i in range(array_info.field_count):
				var entry = get_data(file)
				
				data.data[entry.name] = entry.data
			
			file.seek(original_address)
		"Tick", "Type", "Properties", "Hold", "Chain", "Chance", "Position", "Angle", "Frequency", "Amplitude", "Distance", "Tempo", "Flying Time Factor", "Time Signature", "Flags":
			data.data = []
			var byte_size := file.get_64()
			var total_size := file.get_64()
			var address := file.get_64()
			
			var original_address = file.get_position()
			file.seek(address)
			
			# warning-ignore:integer_division
			for _i in range(total_size / byte_size):
				var entry
				match property_types[name]:
					"u8":
						entry = file.get_8()
					"b8":
						entry = bool(file.get_8())
					"bitfield":
						var bitfield = file.get_32()
						
						entry = []
						for i in range(32):
							var mask = 1 << i
							entry.append(bitfield & mask != 0)
					"ratio":
						entry = {"numerator": file.get_16(), "denominator": file.get_16()}
					"u32":
						entry = file.get_32()
					"f32":
						entry = file.get_float()
					"vector2":
						entry = Vector2(file.get_float(), file.get_float())
				
				data.data.append(entry)
			
			file.seek(original_address)
		"Debug":
			var address := file.get_64()
			data.data = get_string(file, address)
		_:
			file.get_64()
			print("WARNING: Unimplemented field %s" % name)
	
	file.get_buffer(16) # Padding
	return data

func _sort_by_note_type(a, b):
	return a.note_type < b.note_type


func convert_comfy_chart(file_path: String, offset: int):
	var file := FileAccess.open(file_path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		print("ERROR: Invalid file.")
		return null
	
	# Header data
	var magic_bytes = 0x4d465343 # CSFM
	if file.get_32() != magic_bytes:
		print("ERROR: Invalid header.")
		return null
	
	# Build the data tree
	file.seek(336) # Skip to 0x00000150
	var data_tree := {}
	for _i in range(3):
		var entry = get_data(file)
		
		data_tree[entry.name] = entry.data
	
	# Build the chart
	var timing_changes = []
	var last_timing_change = {
		"time": 0,
		"bpm": 160.0,
		"flying_time": 1.0,
		"signature": {"numerator": 4, "denominator": 4},
		"flags": []
	}
	for i in range(data_tree.chart.tempo_map.entry_count):
		var timing_change = last_timing_change.duplicate()
		timing_change.time = data_tree.chart.tempo_map.tick[i]
		
		var flags = data_tree.chart.tempo_map.flags[i]
		timing_change.flags = flags
		
		# Change the BPM
		if flags[0]:
			timing_change.bpm = data_tree.chart.tempo_map.tempo[i]
		
		# Change the flying time factor
		if flags[1]:
			timing_change.flying_time = data_tree.chart.tempo_map.flying_time_factor[i]
		
		# Change the time signature
		if flags[2]:
			timing_change.signature = data_tree.chart.tempo_map.time_signature[i]
		
		timing_changes.append(timing_change)
		last_timing_change = timing_change
	
	var ingame_timing_changes := []
	var ingame_bpm_changes := []
	for timing_change in timing_changes:
		var time = musical_time_to_ms(timing_change.time, timing_changes) + data_tree.chart.time.song_offset * 1000.0 + offset
		
		var beat_length = (60.0 / timing_change.bpm) * 4.0 * 1000.0
		while time < 0:
			time += beat_length
		
		if timing_change.flags[0] or timing_change.flags[2]:
			var ingame_timing_change := HBTimingChange.new()
			ingame_timing_change.time = time
			ingame_timing_change.bpm = timing_change.bpm
			ingame_timing_change.time_signature.numerator = timing_change.signature.numerator
			ingame_timing_change.time_signature.denominator = timing_change.signature.denominator
			
			ingame_timing_changes.append(ingame_timing_change)
		
		if timing_change.flags[1]:
			var bpm_change := HBBPMChange.new()
			bpm_change.time = time
			bpm_change.speed_factor = timing_change.flying_time * 100.0
			
			ingame_bpm_changes.append(bpm_change)
	
	var notes = []
	var time_groups = {}
	var previous_slide = -1
	for i in range(data_tree.chart.targets.entry_count):
		var note_data := HBNoteData.new()
		
		note_data.time = max(musical_time_to_ms(data_tree.chart.targets.tick[i], timing_changes) + data_tree.chart.time.song_offset * 1000.0 + offset, 0)
		note_data.note_type = note_types_to_hb[data_tree.chart.targets.type[i]]
		note_data.hold = data_tree.chart.targets.hold[i]
		
		if note_data.is_slide_note() and data_tree.chart.targets.chain[i]:
			if previous_slide == note_data.note_type:
				note_data.note_type += 2 # Makes it a slide chain piece
			else:
				previous_slide = note_data.note_type
		else:
			previous_slide = -1
		
		note_data.position = data_tree.chart.targets.position[i]
		note_data.pos_modified = data_tree.chart.targets.properties[i]
		
		note_data.entry_angle = data_tree.chart.targets.angle[i] - 90
		note_data.oscillation_frequency = data_tree.chart.targets.frequency[i]
		note_data.oscillation_amplitude = data_tree.chart.targets.amplitude[i]
		note_data.distance = data_tree.chart.targets.distance[i]
		
		if not note_data.pos_modified:
			var time_as_eight = fmod(data_tree.chart.targets.tick[i] / 24.0, 15.0)
			if time_as_eight < 0:
				time_as_eight = fmod(15.0 - abs(time_as_eight), 15.0)
			
			note_data.position.x = 242 + 96 * time_as_eight
		
		notes.append(note_data)
		
		if not time_groups.has(note_data.time):
			time_groups[note_data.time] = []
		time_groups[note_data.time].append(note_data)
	
	for time in time_groups:
		time_groups[time].sort_custom(Callable(self, "_sort_by_note_type"))
		
		for note_data in time_groups[time]:
			if note_data.pos_modified:
				continue
			
			note_data.oscillation_frequency = -2
			
			if time_groups[time].size() == 1:
				note_data.entry_angle = -90
				note_data.distance = 1200
				note_data.oscillation_amplitude = 500
				
				note_data.position.y = 918
			else:
				note_data.distance = 880
				note_data.oscillation_amplitude = 0
				
				note_data.position.y = 918 - (3 - note_data.note_type) * 96
			
			if time_groups[time].size() == 2:
				var index = time_groups[time].find(note_data)
				
				note_data.entry_angle = -45.0 if index == 0 else 45.0
			elif time_groups[time].size() > 2:
				note_data.entry_angle = -45.0 if note_data.note_type < 2 else 45.0
	
	# Populate the chart
	var chart := HBChart.new()
	var note_type_to_layers_map = {}
	var events_layer
	for layer in chart.layers:
		if not layer.name in ["Events", "Lyrics", "Sections"] and not "2" in layer.name:
			note_type_to_layers_map[HBBaseNote.NOTE_TYPE[layer.name]] = chart.layers.find(layer)
		elif layer.name == "Events":
			events_layer = layer
	
	note_type_to_layers_map[HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT] = note_type_to_layers_map[HBBaseNote.NOTE_TYPE.SLIDE_LEFT]
	note_type_to_layers_map[HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT] = note_type_to_layers_map[HBBaseNote.NOTE_TYPE.SLIDE_RIGHT]
	
	for note_data in notes:
		var layer_idx = note_type_to_layers_map[note_data.note_type]
		chart.layers[layer_idx].timing_points.append(note_data)
	
	for timing_point in ingame_bpm_changes:
		events_layer.timing_points.append(timing_point)
	
	return [chart, ingame_timing_changes]
