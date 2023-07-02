extends AcceptDialog
@onready var song_selector = get_node("%SongSelector")

enum SELECTOR_MODE {
	CHART,
	SONG
}

enum SAVE_MODE {
	LOAD,
	SAVE
}

@export var from_ppd_allowed: bool = false

@export var selector_mode: SELECTOR_MODE = SELECTOR_MODE.CHART
@export var save_mode: SAVE_MODE = SAVE_MODE.LOAD
signal chart_selected(song_id, difficulty)
signal song_selected(song_id)
signal ppd_chart_selected(path)

func _ready():
	song_selector.mode = selector_mode
	if save_mode == SAVE_MODE.LOAD: 
		get_ok_button().text = "Load"
	else:
		get_ok_button().text = "Save"
	
	get_ok_button().connect("pressed", Callable(self, "_on_OK_pressed"))
	
	if from_ppd_allowed and save_mode == SAVE_MODE.LOAD:
		var ppd_button = add_button("From PPD")
		ppd_button.connect("pressed", Callable(self, "_on_ppd_button_pressed"))
	
	$PPDFileDialog.connect("file_selected", Callable(self, "_on_ppd_file_selected"))

func _on_ppd_button_pressed():
	$PPDImportConfirmationDialog.popup_centered()

func _on_OK_pressed():
	if song_selector.selected_song:
		if mode == SELECTOR_MODE.CHART:
			emit_signal("chart_selected", song_selector.selected_song, song_selector.selected_difficulty)
		elif mode == SELECTOR_MODE.SONG:
			emit_signal("song_selected", song_selector.selected_song)
		hide()

func _on_PPDImportConfirmationDialog_confirmed():
	$PPDFileDialog.popup_centered_ratio(0.5)
	
func _on_ppd_file_selected(path):
	emit_signal("ppd_chart_selected", path)

func _on_search_text_changed(new_text: String):
	song_selector.search = new_text.to_lower()
	song_selector.populate_tree()

func _popup():
	song_selector.populate_tree()
	popup_centered_ratio(0.35)
