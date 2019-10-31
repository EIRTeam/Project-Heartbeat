extends HBListContainer

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

signal song_hovered(song)
func _ready():
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		var item = SongListItem.instance()
		add_child(item)
		item.song = song
	selected_option = get_child(0)
	connect("selected_option_changed", self, "_on_hovered_song_changed")
	# For making song play when focused for the first time
	connect("focus_entered", self, "_on_hovered_song_changed", [], CONNECT_ONESHOT)

func _on_hovered_song_changed():
	emit_signal("song_hovered", selected_option.song)
