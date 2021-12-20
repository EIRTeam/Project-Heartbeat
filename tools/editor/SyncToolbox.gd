extends WindowDialog

onready var average_bpm_lineedit = get_node("MarginContainer/VBoxContainer/ResultsHBoxContainer/AverageBPMLineEdit")
onready var whole_bpm_lineedit = get_node("MarginContainer/VBoxContainer/ResultsHBoxContainer/WholeBPMLineEdit")
onready var bpm_spinbox = get_node("MarginContainer/VBoxContainer/ParamsHBoxContainer/BPMSpinBox")
onready var offset_spinbox = get_node("MarginContainer/VBoxContainer/ParamsHBoxContainer/OffsetSpinBox")
onready var resolution_spinbox = get_node("MarginContainer/VBoxContainer/ResolutionHBoxContainer/ResolutionSpinBox")
onready var toggle_metronome_button = get_node("MarginContainer/VBoxContainer/MetronomeButtonsHBoxContainer/ToggleMetronomeButton")


var _editor: HBEditor setget set_editor
func set_editor(editor):
	_editor = editor


var dts := []
var last_pressed_time = 0
func _on_calculator_pressed():
	_editor.game_playback.game.play_note_sfx()
	
	var time = OS.get_ticks_usec() / 1000.0
	var dt = time - last_pressed_time
	
	if dt > 2000:
		dts.clear()
		average_bpm_lineedit.text = "0"
		whole_bpm_lineedit.text = "0"
	elif dt > 0:
		dts.append(dt)
		var dt_sum = 0
		for delta in dts:
			dt_sum += delta
		
		var average_dt = dt_sum / float(dts.size())
		var average_bpm = stepify(60.0 / average_dt * 1000.0, 0.01)
		average_bpm_lineedit.text = String(average_bpm)
		whole_bpm_lineedit.text = String(round(average_bpm))
	
	last_pressed_time = time

func _on_ResetButton_pressed():
	dts.clear()
	last_pressed_time = 0
	
	average_bpm_lineedit.text = "0"
	whole_bpm_lineedit.text = "0"


var metronome_enabled := false
func _on_ToggleMetronomeButton_pressed():
	var bars_per_minute = bpm_spinbox.value / 4.0
	var seconds_per_bar = 60.0/bars_per_minute
	
	var beat_length = seconds_per_bar / 4.0
	var note_length = 1.0/4.0 # a quarter of a beat
	var interval = beat_length / (resolution_spinbox.value * note_length) * 1000.0
	
	_editor.game_playback.toggle_metronome(offset_spinbox.value, interval)
	
	metronome_enabled = not metronome_enabled
	if metronome_enabled:
		toggle_metronome_button.text = "Disable metronome"
		
		bpm_spinbox.editable = false
		offset_spinbox.editable = false
		resolution_spinbox.editable = false
	else:
		toggle_metronome_button.text = "Enable metronome"
		
		bpm_spinbox.editable = true
		offset_spinbox.editable = true
		resolution_spinbox.editable = true

func _on_ApplyButton_pressed():
	_editor.BPM_spinbox.value = bpm_spinbox.value
	_editor.offset_box.value = float(offset_spinbox.value) / 1000.0


func _popup():
	rect_global_position = (Vector2(1920, 1080) - rect_size) / 2.0 
	visible = true

func _reset(bpm, offset):
	_on_ResetButton_pressed()
	bpm_spinbox.value = bpm
	offset_spinbox.value = offset * 1000.0
	
	_editor.game_playback.metronome_enabled = false
	toggle_metronome_button.text = "Enable metronome"
	
	bpm_spinbox.editable = true
	offset_spinbox.editable = true
	resolution_spinbox.editable = true
	visible = false
