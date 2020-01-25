extends Tree

signal song_selected(song)

func _ready():
	create_item()
	connect("item_selected", self, "_on_item_selected")

func add_song(song: HBSong):
	var song_item := create_item()
	song_item.set_text(0, song.get_visible_title())
	song_item.set_meta("song", song)
	
func _on_item_selected():
	var song = get_selected().get_meta("song")
	emit_signal("song_selected", song)

func get_selected_song():
	return get_selected().get_meta("song")


func _on_SongMetaEditor_song_meta_saved():
	var song = get_selected().get_meta("song") as HBSong
	get_selected().set_text(0, song.get_visible_title())

func clear_songs():
	clear()
	create_item()
