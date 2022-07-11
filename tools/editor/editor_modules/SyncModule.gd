extends HBEditorModule

onready var bpm_spinbox := get_node("%BPMSpinBox")
onready var offset_spinbox := get_node("%OffsetSpinBox")
onready var grid_resolution_option_button := get_node("%GridResolutionOptionButton")
onready var signature_option_button := get_node("%SignatureOptionButton")
onready var average_bpm_lineedit := get_node("%AverageBPMLineEdit")
onready var whole_bpm_lineedit := get_node("%WholeBPMLineEdit")

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
	
	signature_option_button.add_item("4 beats per bar (4/4)")
	signature_option_button.add_item("3 beats per bar (3/4)")
	signature_option_button.add_item("2 beats per bar (2/4)")
	signature_option_button.add_item("1 beat per bar (1/4)")

func set_editor(_editor: HBEditor):
	.set_editor(_editor)
	
	_editor.sync_module = self
	_editor.connect("paused", self, "_on_editor_paused")

func song_editor_settings_changed(settings: HBPerSongEditorSettings):
	bpm_spinbox.value = settings.bpm
	offset_spinbox.value = settings.offset * 1000.0
	
	var resolution_idx = resolutions.find(settings.note_resolution)
	grid_resolution_option_button.select(resolution_idx)
	
	if resolution_idx == -1:
		grid_resolution_option_button.select(resolutions.size())
	
	var signature_idx = signatures.find(settings.beats_per_bar)
	signature_option_button.select(signature_idx)
	
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
	
	var interval = get_timing_interval(1.0/4.0)
	var song_end = editor.game_playback.game.audio_playback.get_length_msec() + editor.game_playback.game.audio_playback.offset
	
	if not editor.game_playback.is_playing():
		editor._on_PlayButton_pressed()
	var song_start = ShinobuGodot.get_dsp_time() - editor.playhead_position
	
	var next_beat = offset_spinbox.value
	while next_beat < song_end:
		if next_beat < editor.playhead_position:
			next_beat += interval
			continue
		
		var player := ShinobuGodot.instantiate_sound("note_hit", "sfx")
		player.schedule_start_time(song_start + next_beat)
		player.start()
		sound_players.append(player)
		
		next_beat += interval

func _on_editor_paused():
	sound_players = []


func set_offset_at_playhead():
	offset_spinbox.value = editor.playhead_position

func set_bpm(value):
	bpm = value
	get_song_settings().set("bpm", bpm)
	timing_information_changed()

func set_offset(value):
	offset = value
	get_song_settings().set("offset", offset / 1000.0)
	timing_information_changed()

func set_resolution(index):
	resolution = resolutions[index]
	get_song_settings().set("note_resolution", resolution)
	timing_information_changed()

func set_signature(index):
	signature = signatures[index]
	get_song_settings().set("beats_per_bar", signature)
	timing_information_changed()

func get_bpm():
	return bpm

func get_offset():
	return offset / 1000.0

func get_resolution():
	return resolution

func get_signature():
	return signature
