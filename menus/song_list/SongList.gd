
extends HBScrollList
const SongListItem = preload("res://menus/song_list/SongListItem.tscn")
signal song_hovered(song)
func _ready():
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		var item = SongListItem.instance()
		vbox_container.add_child(item)
		item.song = song
		item.connect("song_selected", self, "_on_song_selected")
	connect("option_hovered", self, "_on_option_hovered")
	MouseTrap.difficulty_select_dialog.connect("popup_hide", self, "grab_focus")
func _on_option_hovered(option):
	if option.song.audio:
		emit_signal("song_hovered", option.song)
		
func _on_focus_entered():
	._on_focus_entered()
	if selected_child:
		emit_signal("song_hovered", selected_child.song)
func _on_song_selected(song: HBSong):
	MouseTrap.difficulty_select_dialog.load_song(song)
	MouseTrap.difficulty_select_dialog.popup_centered()
