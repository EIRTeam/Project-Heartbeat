extends HBEditorModule

@onready var grid_resolution_option_button: OptionButton
@onready var average_bpm_lineedit := get_node("%AverageBPMLineEdit")
@onready var whole_bpm_lineedit := get_node("%WholeBPMLineEdit")
@onready var bpm_spinbox := get_node("%BPMSpinBox")
@onready var time_sig_numerator_spinbox := get_node("%TimeSigNumSpinBox")
@onready var time_sig_denominator_spinbox := get_node("%TimeSigDenSpinBox")
@onready var create_timing_change_button := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxRatioContainer/HBEditorButton")
@onready var offset_spinbox := get_node("%OffsetSpinBox")
@onready var offset_notes_only_checkbox := get_node("%OffsetNotesOnlyCheckbox")

var bpm := 150.0
var offset := 0
var resolution := 16.0
var signature := 4

var resolutions = [
	4,
	6,
	8,
	12,
	16,
	24,
	32
]

var signatures = [
	4,
	3,
	2,
	1
]

var original_resolution_tooltip := ""

func _ready():
	super._ready()
	add_shortcut("editor_increase_resolution", "increase_resolution_by", [1])
	add_shortcut("editor_decrease_resolution", "increase_resolution_by", [-1])
	
	for i in range(resolutions.size()):
		add_shortcut("editor_resolution_" + str(resolutions[i]), "set_resolution_shortcut", [i])
	
	update_shortcuts()

func set_editor(_editor: HBEditor):
	super.set_editor(_editor)
	grid_resolution_option_button = _editor.get_node("%GridResolutionOptionButton")
	
	grid_resolution_option_button.add_item("1/4 (Fourths)")
	grid_resolution_option_button.add_item("1/6 (Sixths)")
	grid_resolution_option_button.add_item("1/8 (Eights)")
	grid_resolution_option_button.add_item("1/12 (Twelfths)")
	grid_resolution_option_button.add_item("1/16 (Sixteenths)")
	grid_resolution_option_button.add_item("1/24 (Twentyfourths)")
	grid_resolution_option_button.add_item("1/32 (Thirtyseconds)")
	grid_resolution_option_button.add_item("Custom")
	original_resolution_tooltip = grid_resolution_option_button.tooltip_text
	
	_editor.sync_module = self
	_editor.connect("paused", Callable(self, "_on_editor_paused"))
	
	update_shortcuts()

func song_editor_settings_changed(settings: HBPerSongEditorSettings):
	var resolution_idx = resolutions.find(settings.note_resolution)
	grid_resolution_option_button.select(resolution_idx)
	
	if resolution_idx == -1:
		grid_resolution_option_button.select(resolutions.size())
	
	bpm = settings.bpm
	offset = settings.offset * 1000.0
	resolution = settings.note_resolution
	signature = settings.beats_per_bar
	timing_information_changed()

func update_shortcuts():
	super.update_shortcuts()
	
	if not grid_resolution_option_button:
		return
	
	var action_list = InputMap.action_get_events("editor_increase_resolution")
	var event = action_list[0] if action_list else InputEventKey.new()
	var increase_resolution_text = get_event_text(event)
	
	action_list = InputMap.action_get_events("editor_decrease_resolution")
	event = action_list[0] if action_list else InputEventKey.new()
	var decrease_resolution_text = get_event_text(event)
	
	grid_resolution_option_button.tooltip_text = original_resolution_tooltip + "\nShortcut (Increase): " + increase_resolution_text
	grid_resolution_option_button.tooltip_text += "\nShortcut (Decrease): " + decrease_resolution_text


func increase_resolution_by(amount: int):
	var index = resolutions.bsearch(resolution)
	if resolution in resolutions:
		index += amount
		index = clamp(index, 0, resolutions.size()-1)
	else:
		if amount < 0 and index - 1 > 0:
			index -= 1
		else:
			index = -1
	
	grid_resolution_option_button.select(index)
	
	if index == -1:
		grid_resolution_option_button.select(resolutions.size())
	else:
		set_resolution(index)

func set_resolution_shortcut(index: int):
	grid_resolution_option_button.select(index)
	set_resolution(index)


var dts := []
var last_pressed_time = 0
func calculator_pressed():
	if not visible:
		return
	
	editor.game_playback.game.play_note_sfx()
	
	var time = Time.get_ticks_usec() / 1000.0
	var dt = time - last_pressed_time
	
	if dt > 2000:
		dts.clear()
		average_bpm_lineedit.text = "0 BPM"
		whole_bpm_lineedit.text = "0 BPM"
	elif dt > 0:
		dts.append(dt)
		var dt_sum = 0
		for delta in dts:
			dt_sum += delta
		
		var average_dt = dt_sum / float(dts.size())
		var average_bpm = snapped(60.0 / average_dt * 1000.0, 0.01)
		average_bpm_lineedit.text = String(average_bpm) + " BPM"
		whole_bpm_lineedit.text = String(round(average_bpm)) + " BPM"
	
	last_pressed_time = time

func reset_pressed():
	dts.clear()
	last_pressed_time = 0
	
	average_bpm_lineedit.text = "0 BPM"
	whole_bpm_lineedit.text = "0 BPM"


var sound_players = []
func toggle_metronome():
	if sound_players:
		if editor.game_playback.is_playing():
			editor._on_PauseButton_pressed()
		
		sound_players = []
		return
	
	if not editor.game_playback.is_playing():
		editor._on_PlayButton_pressed()
	
	var current_time = Shinobu.get_dsp_time()
	var song_start = current_time - editor.playhead_position
	
	for time in get_metronome_map():
		if time < editor.playhead_position:
			continue
		
		var sound := UserSettings.user_sfx["note_hit"].instantiate(HBGame.sfx_group) as ShinobuSoundPlayer
		
		sound.schedule_start_time(song_start + time)
		sound.start()
		sound_players.append(sound)
	
	Shinobu.set_dsp_time(current_time)

func _on_editor_paused():
	for sound in sound_players:
		sound.stop()
	
	sound_players = []


func show_timing_change_dialog():
	var timing_change := get_timing_info_at_time(get_playhead_position())
	if not timing_change:
		timing_change = HBTimingChange.new()
	
	var calculated_bpm = int(whole_bpm_lineedit.text.split(" ")[0])
	bpm_spinbox.value = calculated_bpm if calculated_bpm else timing_change.bpm
	
	time_sig_numerator_spinbox.value = timing_change.time_signature.numerator
	time_sig_denominator_spinbox.value = timing_change.time_signature.denominator
	
	$TempoDialog.popup_centered()

func add_timing_change():
	for layer in get_layers():
		if layer.layer_name == "Tempo Map":
			var timing_change = HBTimingChange.new()
			timing_change.time = get_playhead_position()
			timing_change.bpm = bpm_spinbox.value
			timing_change.time_signature.numerator = time_sig_numerator_spinbox.value
			timing_change.time_signature.denominator = time_sig_denominator_spinbox.value
			
			if get_timing_map():
				timing_change.time = snap_time_to_timeline(timing_change.time)
			
			create_timing_point(layer, timing_change.get_timeline_item(), true)
			break


func set_resolution(index):
	if index == resolutions.size():
		editor._toggle_settings_popup()
		editor.settings_editor.tab_container.current_tab = 1
		editor.song_settings_editor.tree.scroll_to_item(editor.song_settings_editor.note_resolution_item)
		editor.song_settings_editor.note_resolution_item.select(1)
		editor.song_settings_editor.tree.edit_selected()
		
		return
	
	resolution = resolutions[index]
	get_song_settings().set("note_resolution", resolution)
	timing_information_changed()

func get_resolution():
	return resolution

func offset_notes():
	var offset = offset_spinbox.value
	
	if offset == 0:
		return
	
	undo_redo.create_action("Offset all timing points by " + str(offset) + "ms")
	
	for item in get_timeline_items():
		var timing_point = item.data as HBTimingPoint
		if offset_notes_only_checkbox.pressed and not timing_point is HBBaseNote:
			continue
		
		var new_time = max(timing_point.time + offset, 0)
		
		undo_redo.add_do_property(timing_point, "time", new_time)
		undo_redo.add_undo_property(timing_point, "time", timing_point.time)
		
		if timing_point is HBSustainNote:
			var length = timing_point.end_time - timing_point.time
			
			undo_redo.add_do_property(timing_point, "end_time", new_time + length)
			undo_redo.add_undo_property(timing_point, "end_time", timing_point.end_time)
			
			undo_redo.add_do_method(item.sync_value.bind("end_time"))
			undo_redo.add_undo_method(item.sync_value.bind("end_time"))
		
		undo_redo.add_do_method(item._layer.place_child.bind(item))
		undo_redo.add_undo_method(item._layer.place_child.bind(item))
	
	undo_redo.add_do_method(self.sync_inspector_values)
	undo_redo.add_undo_method(self.sync_inspector_values)
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.timing_information_changed)
	undo_redo.add_undo_method(self.timing_information_changed)
	
	undo_redo.add_do_method(self.force_game_process)
	undo_redo.add_undo_method(self.force_game_process)
	
	undo_redo.add_do_method(self.sync_lyrics)
	undo_redo.add_undo_method(self.sync_lyrics)
	
	undo_redo.commit_action()
