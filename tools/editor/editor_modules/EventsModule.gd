extends HBEditorModule

@onready var bpm_dialog = get_node("%SpeedChangeDialog")
@onready var bpm_dialog_spinbox = get_node("%SpeedChangeDialog/MarginContainer/HBoxContainer/HBEditorSpinBox")
@onready var lyric_dialog = get_node("%LyricDialog")
@onready var lyric_dialog_line_edit = get_node("%LyricDialog/MarginContainer/LineEdit")
@onready var section_dialog = get_node("%SectionDialog")
@onready var section_dialog_line_edit = get_node("%SectionDialog/MarginContainer/LineEdit")

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel", false, true):
		if bpm_dialog.visible:
			bpm_dialog_spinbox.release_focus()
			bpm_dialog.hide()
		
		if lyric_dialog.visible:
			lyric_dialog_line_edit.release_focus()
			lyric_dialog.hide()
		
		if section_dialog.visible:
			section_dialog_line_edit.release_focus()
			section_dialog.hide()

func add_event_timing_point(timing_point_class: GDScript, meta: Dictionary = {}):
	var timing_point := timing_point_class.new() as HBTimingPoint
	timing_point.time = get_playhead_position()
	
	for key in meta:
		timing_point.set(key, meta[key])
	
	# Event layer is the last one
	var ev_layer = null
	for layer in get_layers():
		if layer.layer_name == "Events":
			ev_layer = layer
			break
	
	create_timing_point(ev_layer, timing_point.get_timeline_item())
	return timing_point

func create_lyrics_event(event_obj: HBTimingPoint):
	var ev_layer = null
	for layer in get_layers():
		if layer.layer_name == "Lyrics":
			ev_layer = layer
			break
	
	var timeline_item = event_obj.get_timeline_item() as EditorLyricPhraseTimelineItem
	timeline_item.connect("phrases_changed", Callable(self, "sync_lyrics"))
	
	create_timing_point(ev_layer, timeline_item)
	editor.sync_lyrics()


func popup_speed_change():
	bpm_dialog.popup_centered()
	bpm_dialog_spinbox.get_line_edit().grab_focus()

func create_bpm_change():
	var t = editor.snap_time_to_timeline(get_playhead_position())
	add_event_timing_point(HBBPMChange, {"time": t, "speed_factor": bpm_dialog_spinbox.value})
	
	bpm_dialog_spinbox.release_focus()
	bpm_dialog.hide()

func create_intro_skip():
	add_event_timing_point(HBIntroSkipMarker)

func create_phrase_start():
	var obj = HBLyricsPhraseStart.new()
	obj.time = get_playhead_position()
	create_lyrics_event(obj)

func create_phrase_end():
	var obj = HBLyricsPhraseEnd.new()
	obj.time = get_playhead_position()
	create_lyrics_event(obj)

func popup_section_dialog():
	section_dialog.popup_centered()
	section_dialog_line_edit.grab_focus()
	section_dialog_line_edit.text = ""

func create_chart_section(section_name: String):
	var timing_point := HBChartSection.new()
	timing_point.time = get_playhead_position()
	timing_point.name = section_name
	
	var section_layer = null
	for layer in get_layers():
		if layer.layer_name == "Sections":
			section_layer = layer
			break
		
	create_timing_point(section_layer, timing_point.get_timeline_item())
	
	section_dialog_line_edit.release_focus()
	section_dialog.hide()

func popup_lyric_dialog():
	lyric_dialog.popup_centered()
	lyric_dialog_line_edit.grab_focus()
	lyric_dialog_line_edit.text = ""

func create_quick_lyric(lyric_text: String):
	var lyric := HBLyricsLyric.new()
	lyric.value = lyric_text
	lyric.time = get_playhead_position()
	create_lyrics_event(lyric)
	
	lyric_dialog_line_edit.release_focus()
	lyric_dialog.hide()

func _speed_change_rejected():
	bpm_dialog.hide()
