extends HBScrollList

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")
signal song_hovered(song)
signal song_selected(song)
func _ready():

	connect("option_hovered", self, "_on_option_hovered")
	# HACK: Not entirely sure why but we have to wait two frames for _set_opacities to work
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	._set_opacities(true)
#	MouseTrap.difficulty_select_dialog.connect("popup_hide", self, "grab_focus")
func _on_option_hovered(option):
	emit_signal("song_hovered", option.song)
		
func _on_focus_entered():
	._on_focus_entered()
func _on_song_selected(song: HBSong):
	emit_signal("song_selected", song)
func select_song_by_id(song_id: String):
	# HACK HACK: If we don't wait to idle frame the song isn't reselected when it
	# should be
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	for child in vbox_container.get_children():
		if child.song.id == song_id:
			select_child(child, true)
			emit_signal("song_hovered", child.song)
			break
func set_songs(songs: Array, difficulty: String):
	var previously_selected_song_id = null
	if selected_child:
		previously_selected_song_id = selected_child.song.id
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	for song in songs:
		var item = SongListItem.instance()
		vbox_container.add_child(item)
		item.set_song(song, difficulty)
		item.connect("song_selected", self, "_on_song_selected")
	select_child(vbox_container.get_children()[0])
	if previously_selected_song_id:
		for child in vbox_container.get_children():
			if child.song.id == previously_selected_song_id:
				select_child(child)
	emit_signal("option_hovered", selected_child)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	_set_opacities(true)
