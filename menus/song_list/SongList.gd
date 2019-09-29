extends HBListContainer

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

signal song_selected(song)
func _ready():
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		var item = SongListItem.instance()
		add_child(item)
		item.song = song
	connect("selected_option_changed", self, "_on_selected_option_changed")
	connect("focus_entered", self, "_on_selected_option_changed")

func _on_selected_option_changed():
	emit_signal("song_selected", selected_option.song)
