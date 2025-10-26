class_name HBTutorialChartGenerator

var chart: HBChart
var cursor := 0
var note_layers: Array[Dictionary]
var events_layer: Dictionary

func _init(timing_ref_time: int, timing_ref_bpm: float) -> void:
	var layer_i := 0
	chart = HBChart.new()
	chart.init()
	for i in range(HBBaseNote.NOTE_TYPE.size()):
		if i in [HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT or HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT]:
			continue
			
		note_layers.push_back(chart.layers[layer_i])
			
		layer_i += 1
	# Add the two extra slide layers
	note_layers.push_back(chart.layers[layer_i+1])
	note_layers.push_back(chart.layers[layer_i+2])
	# Add the events layer
	events_layer = chart.layers[layer_i+3]
	
	# Now add the timing ref
	var ref := HBTimingChange.new()
	ref.bpm = timing_ref_bpm
	ref.time = timing_ref_time
	events_layer.timing_points.push_back(ref)

func seek_to(time: int):
	cursor = time

func advance_time(time_to_advance: int):
	cursor += time_to_advance

func add_section(name: String):
	var section := HBChartSection.new()
	section.name = name
	section.time = cursor
	events_layer.timing_points.push_back(section)

func add_note(note_type: int, position := Vector2(960, 540), hold := false) -> HBNoteData:
	var note := HBNoteData.new()
	note.position = position
	note.time = cursor
	note.note_type = note_type
	note.hold = hold
	note_layers[note_type].timing_points.push_back(note)
	return note

func add_sustain_note(note_type: int, duration_msec: int, position := Vector2(960, 540)) -> HBSustainNote:
	var note := HBSustainNote.new()
	note.position = position
	note.time = cursor
	note.end_time = cursor + duration_msec
	note.note_type = note_type
	note_layers[note_type].timing_points.push_back(note)
	return note

func add_double_note(note_type: int, position := Vector2(960, 540)):
	var note := HBDoubleNote.new()
	note.position = position
	note.time = cursor
	note.note_type = note_type
	note_layers[note_type].timing_points.push_back(note)

func finish():
	chart.get_timing_points(true)
