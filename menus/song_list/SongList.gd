extends Control

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

onready var vbox_container = get_node("HBoxContainer/VBoxContainer")
func _ready():
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		var item = SongListItem.instance()
		vbox_container.add_child(item)
		item.song = song
		#button.connect("button_down", self, "_on_song_selected", [song_id])
