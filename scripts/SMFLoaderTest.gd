extends Control

func _ready():
	var smf_loader = SMFLoader.new()
	
	var smf = smf_loader.read_file("res://243.mid")
	var BPM = 120
	var chart := HBChart.new()
	for track in smf.tracks:
		for event in track.events:
			if event.event.type == SMFLoader.MIDIEventType.system_event:
				if event.event.args.type == SMFLoader.MIDISystemEventType.set_tempo:
					BPM = 60000000/float(event.event.args.bpm)
			if event.event.type == SMFLoader.MIDIEventType.note_on:
				var tick_time = 60000 / float(BPM * (smf.timebase / 10.0))
				var timing_point = HBNoteData.new()
				timing_point.time = (event.time * tick_time) / 10.0
				chart.layers[HBNoteData.NOTE_TYPE.RIGHT].timing_points.append(timing_point)
	
	var editor_scene = preload("res://tools/editor/Editor.tscn").instance()
	
	var file := File.new()
	print(file.open("user://songs/miditest/normal.json", File.WRITE))
	file.store_string(JSON.print(chart.serialize(), "  "))
