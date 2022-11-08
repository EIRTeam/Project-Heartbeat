extends HBEditorModule

onready var grid_resolution_option_button := get_node("%GridResolutionOptionButton")
onready var average_bpm_lineedit := get_node("%AverageBPMLineEdit")
onready var whole_bpm_lineedit := get_node("%WholeBPMLineEdit")
onready var bpm_spinbox := get_node("%BPMSpinBox")
onready var time_sig_numerator_spinbox := get_node("%TimeSigNumSpinBox")
onready var time_sig_denominator_spinbox := get_node("%TimeSigDenSpinBox")

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
	grid_resolution_option_button.add_item("1/4 (Fourths)")
	grid_resolution_option_button.add_item("1/6 (Sixths)")
	grid_resolution_option_button.add_item("1/8 (Eights)")
	grid_resolution_option_button.add_item("1/12 (Twelfths)")
	grid_resolution_option_button.add_item("1/16 (Sixteenths)")
	grid_resolution_option_button.add_item("1/24 (Twentyfourths)")
	grid_resolution_option_button.add_item("1/32 (Thirtyseconds)")
	grid_resolution_option_button.add_item("Custom")
	grid_resolution_option_button.set_item_disabled(resolutions.size(), true)
	original_resolution_tooltip = grid_resolution_option_button.hint_tooltip
	
	add_shortcut("editor_increase_resolution", "increase_resolution_by", [1])
	add_shortcut("editor_decrease_resolution", "increase_resolution_by", [-1])
	
	for i in range(resolutions.size()):
		add_shortcut("editor_resolution_" + String(resolutions[i]), "set_resolution_shortcut", [i])
	
	update_shortcuts()

func set_editor(_editor: HBEditor):
	.set_editor(_editor)
	
	_editor.sync_module = self
	_editor.connect("paused", self, "_on_editor_paused")

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
	.update_shortcuts()
	
	if not grid_resolution_option_button:
		return
	
	var action_list = InputMap.get_action_list("editor_increase_resolution")
	var event = action_list[0] if action_list else InputEventKey.new()
	var increase_resolution_text = get_event_text(event)
	
	action_list = InputMap.get_action_list("editor_decrease_resolution")
	event = action_list[0] if action_list else InputEventKey.new()
	var decrease_resolution_text = get_event_text(event)
	
	grid_resolution_option_button.hint_tooltip = original_resolution_tooltip + "\nShortcut (Increase): " + increase_resolution_text
	grid_resolution_option_button.hint_tooltip += "\nShortcut (Decrease): " + decrease_resolution_text


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
	
	var time = OS.get_ticks_usec() / 1000.0
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
		var average_bpm = stepify(60.0 / average_dt * 1000.0, 0.01)
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
	print(calculated_bpm)
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
			
			create_timing_point(layer, timing_change.get_timeline_item())
			break


func set_resolution(index):
	resolution = resolutions[index]
	get_song_settings().set("note_resolution", resolution)
	timing_information_changed()

func get_resolution():
	return resolution
