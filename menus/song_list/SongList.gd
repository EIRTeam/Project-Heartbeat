extends HBMenuContainer

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

func _ready():
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		var item = SongListItem.instance()
		add_child(item)
		item.song = song
