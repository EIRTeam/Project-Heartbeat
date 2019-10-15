extends AcceptDialog
onready var song_selector = get_node("SongSelector")

enum SELECTOR_MODE {
	CHART,
	SONG
}

export(SELECTOR_MODE) var mode = SELECTOR_MODE.CHART

signal chart_selected(song_id, difficulty)
signal song_selected(song_id)

func _ready():
	song_selector.mode = mode
	get_ok().text = "Load"
	get_ok().connect("pressed", self, "_on_OK_pressed")


func _on_OK_pressed():
	if song_selector.selected_song:
		if mode == SELECTOR_MODE.CHART:
			emit_signal("chart_selected", song_selector.selected_song, song_selector.selected_difficulty)
		elif mode == SELECTOR_MODE.SONG:
			emit_signal("song_selected", song_selector.selected_song)
		hide()
