extends AcceptDialog
onready var song_selector = get_node("SongSelector")

enum SELECTOR_MODE {
	CHART,
	SONG
}

enum SAVE_MODE {
	LOAD,
	SAVE
}

export(SELECTOR_MODE) var mode = SELECTOR_MODE.CHART
export (SAVE_MODE) var save_mode = SAVE_MODE.LOAD
signal chart_selected(song_id, difficulty)
signal song_selected(song_id)

func _ready():
	song_selector.mode = mode
	if save_mode == SAVE_MODE.LOAD: 
		get_ok().text = "Load"
	else:
		get_ok().text = "Save"
	get_ok().connect("pressed", self, "_on_OK_pressed")


func _on_OK_pressed():
	if song_selector.selected_song:
		if mode == SELECTOR_MODE.CHART:
			emit_signal("chart_selected", song_selector.selected_song, song_selector.selected_difficulty)
		elif mode == SELECTOR_MODE.SONG:
			emit_signal("song_selected", song_selector.selected_song)
		hide()
