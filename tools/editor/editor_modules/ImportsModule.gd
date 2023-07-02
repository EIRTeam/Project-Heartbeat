extends HBEditorModule

const DOWN_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_down.svg")
const RIGHT_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_right.svg")

@onready var importer_option_button := get_node("%ImporterOptionButton")
@onready var file_dialog := get_node("%FileDialog")
@onready var offset_spinbox := get_node("%OffsetSpinBox")
@onready var link_stars_checkbox := get_node("%LinkStarsCheckBox")
@onready var replace_chart_checkbox := get_node("%ReplaceChartCheckBox")
@onready var advanced_options_button := get_node("%AdvancedOptionsButton")
@onready var tempo_map_hbox_container := get_node("%TempoMapHBoxContainer")
@onready var tempo_map_option_button := get_node("%TempoMapOptionButton")

class HBEditorImporter:
	extends VBoxContainer
	
	# warning-ignore:unused_signal
	signal finished_processing
	
	var last_dir
	var filter : get = get_filter
	var chart: HBChart
	var timing_changes: Array
	
	func get_filter():
		return filter
	
	func file_selected(path: String, editor: HBEditor, offset: int, vargs: Dictionary = {}):
		return null
	
	static func build_timing_map(_timing_changes: Array, end_t: int) -> Array:
		var timing_changes_inv = _timing_changes.duplicate()
		timing_changes_inv.reverse()
		
		var timing_map := []
		for timing_change in timing_changes_inv:
			var diff = end_t - timing_change.time
			var ms_per_eight: float = (60.0 / timing_change.bpm) * 1000.0 * 4 / 8.0
			
			for i in range(diff / ms_per_eight + 1, 0, -1):
				timing_map.append(int(timing_change.time + (i - 1) * ms_per_eight))
		
		timing_map.reverse()
		return timing_map
	
	static func autoplace(data: HBBaseNote, timing_map: Array) -> HBBaseNote:
		var new_data = data.clone() as HBBaseNote
		
		var time_as_eight = HBUtils.bsearch_linear(timing_map, data.time)
		time_as_eight = fmod(time_as_eight, 15.0)
		if time_as_eight < 0:
			time_as_eight = fmod(15.0 - abs(time_as_eight), 15.0)
		
		new_data.position.x = 242 + 96 * time_as_eight
		new_data.position.y = 918
		
		new_data.oscillation_amplitude = abs(new_data.oscillation_amplitude)
		new_data.oscillation_frequency = -2
		new_data.entry_angle = -90
		
		return new_data

class DSCImporter:
	extends HBEditorImporter
	
	enum DSC_OPTIONS {
		FT,
		F,
		F2
	}
	
	const DSC_LOADER = preload("res://autoloads/song_loader/song_loaders/DSCConverter.gd")
	
	var offset_spinbox: HBEditorSpinBox
	var options_button: OptionButton
	
	func _ready():
		last_dir = "last_dsc_dir"
		filter = ["*.dsc ; DSC chart"]
		
		options_button = OptionButton.new()
		options_button.add_item("Future Tone/M39s")
		options_button.add_item("F/DT2")
		options_button.add_item("F2nd")
		
		add_child(options_button)
	
	func get_filter():
		var game: String
		match options_button.get_selected_id():
			DSC_OPTIONS.FT:
				game = "FT/MM/MM+"
			DSC_OPTIONS.F:
				game = "F/DT2"
			DSC_OPTIONS.F2:
				game = "F2nd"
		
		return ["*.dsc ; Project DIVA %s chart" % game]
	
	func file_selected(path: String, editor: HBEditor, offset: int, vargs: Dictionary = {}):
		UserSettings.user_settings.last_dsc_dir = path.get_base_dir()
		UserSettings.save_user_settings()
		
		var game: String
		match options_button.get_selected_id():
			DSC_OPTIONS.FT:
				game = "FT"
			DSC_OPTIONS.F:
				game = "f"
			DSC_OPTIONS.F2:
				game = "F2"
		
		var opcode_map = DSCOpcodeMap.new("res://autoloads/song_loader/song_loaders/dsc_opcode_db.json", game)
		
		var result = DSC_LOADER.convert_dsc_to_chart_and_tempo_map(path, opcode_map, offset)
		
		chart = result[0] as HBChart
		timing_changes = result[1]

class PPDImporter:
	extends HBEditorImporter
	
	func _ready():
		filter = ["*.ppd ; PPD chart"]
		last_dir = "last_ppd_dir"
	
	func file_selected(path: String, editor: HBEditor, offset: int, vargs: Dictionary = {}):
		UserSettings.user_settings.last_ppd_dir = path.get_base_dir()
		UserSettings.save_user_settings()
		
		var bpm := 120.0
		var meta_path = HBUtils.join_path(path.get_base_dir(), "data.ini")
		
		var file: FileAccess
		if FileAccess.file_exists(meta_path):
			file = FileAccess.open(meta_path, FileAccess.READ)
		if file and FileAccess.get_open_error() == OK:
			var song = HBPPDSong.from_ini(file.get_as_text(), "")
			bpm = song.bpm
		
		chart = PPDLoader.PPD2HBChart(path, bpm, offset)
		timing_changes = []

class ComfyImporter:
	extends HBEditorImporter
	
	var CSFM_LOADER = preload("res://autoloads/song_loader/song_loaders/CsfmConverter.gd").new()
	
	func _ready():
		last_dir = "last_csfm_dir"
		filter = ["*.csfm ; Comfy Studio chart"]
	
	func file_selected(path: String, editor: HBEditor, offset: int, vargs: Dictionary = {}):
		UserSettings.user_settings.last_csfm_dir = path.get_base_dir()
		UserSettings.save_user_settings()
		
		var result = CSFM_LOADER.convert_comfy_chart(path, offset)
		chart = result[0]
		timing_changes = result[1]

class EditImporter:
	extends HBEditorImporter
	
	const EDIT_LOADER = preload("res://autoloads/song_loader/song_loaders/EditConverter.gd")
	
	func _ready():
		last_dir = "last_edit_dir"
		filter = ["SECURE.BIN ; Edit data"]
	
	func file_selected(path: String, editor: HBEditor, offset: int, vargs: Dictionary = {}):
		UserSettings.user_settings.last_edit_dir = path.get_base_dir()
		UserSettings.save_user_settings()
		
		var result = EDIT_LOADER.convert_edit_to_chart(path, offset, vargs.custom_link_stars)
		chart = result[0]
		timing_changes = result[1]

class MIDIImporter:
	extends HBEditorImporter
	
	const TEMPO_OPTIONS = {
		"round_and_snap": "Round BPMs and snap notes",
		"round": "Just round BPMs",
		"bare": "Import file as-is",
	}
	
	var midi_loader_popup = preload("res://tools/editor/editor_modules/MIDILoader/MIDILoaderPopup.tscn").instantiate()
	var midi_loader_popup_gh = preload("res://tools/editor/editor_modules/MIDILoader/MIDILoaderPopupGH.tscn").instantiate()
	var options_button: OptionButton
	var editor: HBEditor
	var offset: int
	var tempo_mode: String
	
	# mix multiple tracks to single track
	# taken from the midi player code, by Yui Kinomoto @arlez80
	# how this works is beyond me, I am not a musician
	func merge_tracks(smf: SMFLoader.SMF, allowed_tracks=[]):
		var track_events = []
		if smf.tracks.size() == 1:
			track_events = smf.tracks[0].events
		else:
			var tracks:Array = []
			var i = 0
			for track in smf.tracks:
				tracks.append({"track_i": i, "pointer":0, "events":track.events, "length": track.events.size()})
				
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
	
	func _ready():
		last_dir = "last_midi_dir"
		
		midi_loader_popup.connect("track_import_accepted", Callable(self, "track_import_accepted"))
		add_child(midi_loader_popup)
		
		midi_loader_popup_gh.connect("track_import_accepted", Callable(self, "track_import_accepted"))
		add_child(midi_loader_popup_gh)
		
		options_button = OptionButton.new()
		options_button.add_item("Standard MIDI")
		options_button.add_item("Guitar Hero MIDI")
		add_child(options_button)
	
	func get_filter():
		if options_button.get_selected_id() == 1:
			return ["*.mid ; Guitar Hero MIDI File"]
		else:
			return ["*.mid ; Standard MIDI File"]
	
	func file_selected(path: String, _editor: HBEditor, _offset: int, vargs: Dictionary = {}):
		UserSettings.user_settings.last_midi_dir = path.get_base_dir()
		UserSettings.save_user_settings()
		
		var popup = midi_loader_popup if options_button.get_selected_id() == 0 else midi_loader_popup_gh
		popup.load_smf(path)
		popup.popup_centered_ratio(0.25)
		
		editor = _editor
		offset = _offset
		tempo_mode = vargs.tempo_mode
	
	func track_import_accepted(smf: SMFLoader.SMF, note_range=[0, 255], tracks=[]):
		chart = HBChart.new()
		timing_changes.clear()
		
		var found_times = []
		
		var events = merge_tracks(smf, tracks)
		
		var microseconds = 0
		var ticks_per_beat = smf.timebase
		var last_event_ticks = 0
		var tempo = 500000
		var bpm = 120.0
		var time_sig = {"numerator": 4, "denominator": 4}
		var timing_map = []
		
		for event in events:
			var delta_ticks = event.time - last_event_ticks
			last_event_ticks = event.time
			
			var delta_microseconds = tempo * delta_ticks / float(ticks_per_beat)
			microseconds += delta_microseconds
			
			# MIDI tempo is kinda unintuitive
			# Further reading for future me:
			# midi.teragonaudio.com/tech/midifile/ppqn.htm
			if event.event.type == SMFLoader.MIDIEventType.system_event:
				if event.event.args.type == SMFLoader.MIDISystemEventType.set_tempo:
					tempo = event.event.args.bpm
					bpm = 60_000_000.0 / tempo
					
					if tempo_mode == "round" or tempo_mode == "round_and_snap":
						bpm = snapped(bpm, 0.01)
					
					if tempo_mode == "round_and_snap":
						tempo = 60_000_000.0 / bpm
					
					var event_time_ms = microseconds * 0.001
					
					if timing_changes and timing_changes[-1].time == event_time_ms:
						# Edit last timing change
						timing_changes[-1].bpm = bpm
					else:
						var timing_point = HBTimingChange.new()
						timing_point.time = event_time_ms
						timing_point.bpm = bpm
						timing_point.time_signature = time_sig
						
						timing_changes.append(timing_point)
					
					timing_map = build_timing_map(timing_changes, editor.get_song_length() * 1000)
			
			# Time sigs are sligthly less weird if you only need the simple stuff
			# http://midi.teragonaudio.com/tech/midifile/time.htm
			if event.event.type == SMFLoader.MIDIEventType.system_event:
				if event.event.args.type == SMFLoader.MIDISystemEventType.beat:
					time_sig.numerator = event.event.args.numerator
					time_sig.denominator = pow(2, event.event.args.denominator)
					
					var event_time_ms = microseconds * 0.001
					
					if timing_changes and timing_changes[-1].time == event_time_ms:
						# Edit last timing change
						timing_changes[-1].time_signature = time_sig
					else:
						var timing_point = HBTimingChange.new()
						timing_point.time = event_time_ms
						timing_point.bpm = bpm
						timing_point.time_signature = time_sig
						
						timing_changes.append(timing_point)
					
					timing_map = build_timing_map(timing_changes, editor.get_song_length() * 1000)
			
			if event.event.type == SMFLoader.MIDIEventType.note_on:
				var event_time_ms = microseconds * 0.001
				
				if not event_time_ms in found_times:
					if note_range[0] <= event.event.note and event.event.note <= note_range[1]:
						var timing_point = HBNoteData.new()
						timing_point.time = event_time_ms + offset
						
						if UserSettings.user_settings.editor_auto_place:
							timing_point = autoplace(timing_point, timing_map)
						
						chart.layers[HBNoteData.NOTE_TYPE.RIGHT].timing_points.append(timing_point)
						
						found_times.append(event_time_ms)
		
		emit_signal("finished_processing")

var importers = [
	{"name": "DSC file", "importer": DSCImporter},
	{"name": "PPD chart", "importer": PPDImporter},
	{"name": "Comfy Studio chart", "importer": ComfyImporter},
	{"name": "F2nd edit", "importer": EditImporter},
	{"name": "MIDI file", "importer": MIDIImporter},
]
var current_importer_idx := 0

func _ready():
	super._ready()
	for item in importers:
		importer_option_button.add_item(item.name)
		
		var instance = item.importer.new()
		instance.visible = false
		item.instance = instance
		$MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/VBoxContainer2.add_child(instance)
	
	importer_selected(0)
	
	for i in range(MIDIImporter.TEMPO_OPTIONS.size()):
		tempo_map_option_button.add_item(MIDIImporter.TEMPO_OPTIONS.values()[i], i)
		tempo_map_option_button.set_item_metadata(i, MIDIImporter.TEMPO_OPTIONS.keys()[i])
	
	tempo_map_option_button.select(0)
	
	if UserSettings.user_settings.editor_import_warning_accepted:
		$MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer.visible = true
		$MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.visible = false

func import_warning_accepted():
	UserSettings.user_settings.editor_import_warning_accepted = true
	UserSettings.save_user_settings()
	$MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer.visible = true
	$MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer2.visible = false


func importer_selected(idx: int):
	var current_importer = importers[current_importer_idx]
	current_importer.instance.visible = false
	
	var new_importer = importers[idx]
	new_importer.instance.visible = true
	file_dialog.current_dir = UserSettings.user_settings.get(new_importer.instance.last_dir)
	file_dialog.current_file = ""
	
	current_importer_idx = idx
	
	link_stars_checkbox.visible = (new_importer.name == "F2nd edit")
	tempo_map_hbox_container.visible = (new_importer.name == "MIDI file")

func _on_open_file_button_pressed():
	file_dialog.filters = importers[current_importer_idx].instance.filter
	file_dialog.popup_centered_ratio(0.75)

func _on_file_selected(path: String):
	var importer = importers[current_importer_idx]
	
	var vargs = {}
	if importer.name == "F2nd edit":
		vargs.custom_link_stars = link_stars_checkbox.pressed
	if importer.name == "MIDI file":
		vargs.tempo_mode = tempo_map_option_button.get_selected_metadata()
	
	importer.instance.file_selected(path, editor, offset_spinbox.value, vargs)
	
	if importer.name == "MIDI file":
		await importer.instance.finished_processing
	var chart = importer.instance.chart
	var timing_changes = importer.instance.timing_changes
	
	if chart:
		undo_redo.create_action("Import " + importer.name)
		
		undo_redo.add_do_method(self.deselect_all)
		undo_redo.add_undo_method(self.deselect_all)
		
		if replace_chart_checkbox.pressed:
			if timing_changes:
				undo_redo.add_do_property(editor.current_song, "timing_changes", timing_changes)
				undo_redo.add_undo_property(editor.current_song, "timing_changes", editor.current_song.timing_changes)
			
			undo_redo.add_do_method(editor.from_chart.bind(chart, true, true))
			undo_redo.add_undo_method(editor.from_chart.bind(editor.get_chart(), true, true))
		else:
			undo_redo.add_do_method(editor.from_chart.bind(chart, true, true, true))
			undo_redo.add_undo_method(editor.from_chart.bind(editor.get_chart(), true, true))
		
		undo_redo.commit_action()

func _select(item: EditorTimelineItem):
	item.select()
	editor.selected.append(item)

func _finish_selecting():
	editor.selected.sort_custom(Callable(self, "_sort_current_items_impl"))
	editor.inspector.inspect(editor.selected)
	editor.release_owned_focus()
	editor.notify_selected_changed()

var advanced_options_visible := false
func toggle_advanced_options():
	advanced_options_visible = not advanced_options_visible
	$MarginContainer/ScrollContainer/VBoxContainer/VBoxContainer/VBoxContainer.visible = advanced_options_visible
	advanced_options_button.icon = DOWN_ICON if advanced_options_visible else RIGHT_ICON
