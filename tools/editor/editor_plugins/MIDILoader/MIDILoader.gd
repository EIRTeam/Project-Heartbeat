extends HBEditorPlugin

var midi_loader_popup = preload("res://tools/editor/editor_plugins/MIDILoader/MIDILoaderPopup.tscn").instance()
var midi_loader_popup_gh = preload("res://tools/editor/editor_plugins/MIDILoader/MIDILoaderPopupGH.tscn").instance()
var file_dialog = FileDialog.new()
var file_dialog_gh = FileDialog.new()
func _init(editor).(editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var run_button = Button.new()
	run_button.text = "Import timing from MIDI..."
	run_button.clip_text = true
	run_button.connect("pressed", self, "_on_run_button_pressed")
	vbox_container.add_child(run_button)
	
	var gh_run_button = Button.new()
	gh_run_button.text = "Import timing from Guitar Hero MIDI..."
	gh_run_button.clip_text = true
	gh_run_button.connect("pressed", self, "_on_gh_run_button_pressed")
	vbox_container.add_child(gh_run_button)
	
	midi_loader_popup.connect("track_import_accepted", self, "_on_track_import_accepted")
	vbox_container.add_child(midi_loader_popup)
	
	midi_loader_popup_gh.connect("track_import_accepted", self, "_on_track_import_accepted")
	vbox_container.add_child(midi_loader_popup_gh)
	
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.mid ; Standard MIDI File"]
	file_dialog.connect("file_selected", self, "_on_mid_file_selected")
	vbox_container.add_child(file_dialog)
	
	file_dialog_gh.mode = FileDialog.MODE_OPEN_FILE
	file_dialog_gh.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog_gh.filters = ["*.mid ; Guitar Hero MIDI File"]
	file_dialog_gh.connect("file_selected", self, "_on_gh_mid_file_selected")
	vbox_container.add_child(file_dialog_gh)
	
	add_tool_to_tools_tab(vbox_container, "MIDI Import")
func _on_run_button_pressed():
	file_dialog.popup_centered_ratio()
	
func _on_gh_run_button_pressed():
	file_dialog_gh.popup_centered_ratio()
	
func _on_mid_file_selected(file_path: String):
	midi_loader_popup.load_smf(file_path)
	midi_loader_popup.popup_centered_ratio(0.25)
	
func _on_gh_mid_file_selected(file_path: String):
	midi_loader_popup_gh.load_smf(file_path)
	midi_loader_popup_gh.popup_centered_ratio(0.25)
	
# mix multiple tracks to single track
# taken from the midi player code, by Yui Kinomoto @arlez80
# how this works is beyond me, I am not a musician
func merge_tracks(smf: SMFLoader.SMF, allowed_tracks=[]):
	var allow_all_tracks = false
	if allowed_tracks.size() == 0:
		allow_all_tracks = true
		
	
	var track_events = []
	if smf.tracks.size() == 1:
		track_events = smf.tracks[0].events
	else:
		var tracks:Array = []
		var i = 0
		for track in smf.tracks:
			tracks.append({"track_i": i, "pointer":0, "events":track.events, "length": track.events.size()})
			if allow_all_tracks:
				allowed_tracks.append(i)
			i += 1
		var time:int = 0
		var finished:bool = false
		while not finished:
			finished = true
	
			var next_time:int = 0x7fffffff
			for track in tracks:
				var p = track.pointer
				if track.length <= p: continue
				finished = false
				
				var e = track.events[p]
				var e_time = e.time
				if e_time == time:
					track.pointer += 1
					next_time = e_time
					if e.event.type == SMFLoader.MIDIEventType.system_event \
						or track.track_i in allowed_tracks:
							track_events.append(e)

				elif e_time < next_time:
					next_time = e_time
			time = next_time
	return track_events

func _on_track_import_accepted(smf: SMFLoader.SMF, note_range=[0, 255], tracks=[]):
	var chart = HBChart.new()
	
	var found_times = []
	
	var events = merge_tracks(smf, tracks)
	
	var microseconds = 0
	var ticks_per_beat = smf.timebase
	var last_event_ticks = 0
	var tempo = 500000
	
	for event in events:
		var delta_ticks = event.time - last_event_ticks
		last_event_ticks = event.time
		var delta_microseconds = tempo * delta_ticks / float(ticks_per_beat)
		microseconds += delta_microseconds
		if event.event.type == SMFLoader.MIDIEventType.system_event:
			if event.event.args.type == SMFLoader.MIDISystemEventType.set_tempo:
				tempo = event.event.args.bpm
		if event.event.type == SMFLoader.MIDIEventType.note_on:
			var event_time_ms = microseconds * 0.001
			if not event_time_ms in found_times:
				if note_range[0] <= event.event.note and event.event.note <= note_range[1]:
					var timing_point = HBNoteData.new()
					timing_point.time = event_time_ms
					chart.layers[HBNoteData.NOTE_TYPE.RIGHT].timing_points.append(timing_point)
					found_times.append(event_time_ms)
	get_editor().from_chart(chart, true)
