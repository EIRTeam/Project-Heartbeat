extends WindowDialog

onready var use_youtube_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/UseYouTube")
onready var file_dialog = get_node("../PPDFileDialog")
signal youtube_url_selected(url)

signal file_selected(file_path)
signal file_selector_hidden
func _ready():
	use_youtube_button.connect("pressed", self, "_on_use_youtube_button_pressed")
	file_dialog.connect("file_selected", self, "_on_file_selected")
	file_dialog.connect("popup_hide", self, "emit_signal", ["file_selector_hidden"])
func _on_use_youtube_button_pressed():
	emit_signal("youtube_url_selected", $MarginContainer/VBoxContainer/HBoxContainer/LineEdit.text)
	hide()
func _on_file_selected(file):
	emit_signal("file_selected", file)
	hide()

func ask_for_file():
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.ogg ; OGG"]
	popup_centered()
