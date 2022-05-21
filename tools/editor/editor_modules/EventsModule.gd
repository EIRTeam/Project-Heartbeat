extends HBEditorModule

onready var lyric_dialog = get_node("LyricDialog")
onready var lyric_dialog_line_edit = get_node("LyricDialog/MarginContainer/LineEdit")
onready var phrase_start_button = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2/VBoxContainer/Button")
onready var phrase_end_button = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/Button")
onready var lyric_button = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer3/VBoxContainer/Button")

func _ready():
	add_shortcut("editor_quick_phrase_start", "create_phrase_start", phrase_start_button)
	add_shortcut("editor_quick_phrase_end", "create_phrase_end", phrase_end_button)
	add_shortcut("editor_quick_lyric", "popup_lyric_dialog", lyric_button)
	update_shortcuts()

func add_event_timing_point(timing_point_class: GDScript):
	var timing_point := timing_point_class.new() as HBTimingPoint
	timing_point.time = get_playhead_position()
	
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
	timeline_item.connect("phrases_changed", self, "sync_lyrics")
	
	create_timing_point(ev_layer, timeline_item)
	editor.sync_lyrics()


func create_bpm_change():
	add_event_timing_point(HBBPMChange)

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

func create_chart_section():
	var timing_point := HBChartSection.new()
	timing_point.time = get_playhead_position()
	
	var section_layer = null
	for layer in get_layers():
		if layer.layer_name == "Sections":
			section_layer = layer
			break
		
	create_timing_point(section_layer, timing_point.get_timeline_item())

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
