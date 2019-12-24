extends Tree

enum SELECTOR_MODE {
	CHART,
	SONG
}

export(SELECTOR_MODE) var mode = SELECTOR_MODE.CHART

signal chart_selected(song_id, difficulty)
signal song_selected(song_id)

var selected_song
var selected_difficulty

func _ready():
	popullate_tree()
	
func popullate_tree():
	clear()
	create_item()
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if not song is HBPPDSong:
			var item := create_item()
			item.set_text(0, song.title)
			
			if mode == SELECTOR_MODE.CHART:
				item.set_selectable(0, false)
				for chart in song.charts:
					var chart_item := create_item(item)
					chart_item.set_text(0, chart.capitalize())
					chart_item.set_meta("song_id", song_id)
					chart_item.set_meta("difficulty", chart)

func _on_SongSelector_item_selected():
	selected_song = get_selected().get_meta("song_id")
	
	if mode == SELECTOR_MODE.CHART:
		emit_signal("chart_selected", get_selected().get_meta("song_id"), get_selected().get_meta("difficulty"))
		selected_difficulty = get_selected().get_meta("difficulty")
	elif mode == SELECTOR_MODE.SONG:
		emit_signal("song_selected", get_selected().get_meta("song_id"))
