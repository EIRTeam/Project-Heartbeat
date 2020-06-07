# unused but left here for historic purposes...
extends Control

enum PPDEventType {
	ChangeVolume = 0,
	ChangeBPM = 1,
	RapidChangeBPM = 2,
	ChangeSoundPlayMode = 3,
	ChangeDisplayState = 4,
	ChangeMoveState = 5,
	ChangeReleaseSound = 6,
	ChangeNoteType = 7,
	ChangeInitializeOrder = 8,
	ChangeSlideScale = 9
}

onready var window_dialog = get_node("WindowDialog")
onready var browse_button = get_node("WindowDialog/MarginContainer/VBoxContainer/HBoxContainer/BrowseButton")
onready var file_dialog = get_node("FileDialog")

onready var marks_text_edit = get_node("WindowDialog/MarginContainer/VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer/MarksTextEdit")
onready var params_text_edit = get_node("WindowDialog/MarginContainer/VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer2/ParamsTextEdit")
onready var evd_text_edit = get_node("WindowDialog/MarginContainer/VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer3/EVDTextEdit")
func _ready():
	window_dialog.popup_centered_ratio(0.75)
	browse_button.connect("pressed", file_dialog, "popup_centered_ratio", [0.75])
	file_dialog.connect("file_selected", self, "_on_file_selected")
	# var chart = PPDLoader.PPD2HBChart("user://Easy.ppd", 100)
	# var file := File.new()
	# print(file.open("user://test.json", File.WRITE))
	# file.store_string(JSON.print(chart.serialize(), "  "))
#	extract_pack("user://resource.pak")

func _on_file_selected(path: String):
	var marks = PPDLoader._get_marks_from_ppd_pack(path)
	
	marks_text_edit.text = JSON.print(marks.marks, "	")
	params_text_edit.text = JSON.print(marks.params, "	")
	evd_text_edit.text = JSON.print(marks.evd_file.evd_events, "	")
