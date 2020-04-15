extends HBListContainer
const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

signal song_hovered(song)
signal song_selected(song)

func _ready():
	connect("selected_option_changed", self, "_on_selected_option_changed")
	
func _on_selected_option_changed():
	emit_signal("song_hovered", selected_option.song)

func _on_song_selected(song: HBSong):
	emit_signal("song_selected", song)
	
func select_song_by_id(song_id: String):
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	for child_i in range(get_child_count()):
		var child = get_child(child_i)
		if child.song.id == song_id:
			select_option(child_i)
			hard_arrange_all()
			break
func set_songs(songs: Array, difficulty: String):
	var previously_selected_song_id = null
	var vbox_container = self
	if selected_option:
		previously_selected_song_id = selected_option.song.id
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	for song in songs:
		var item = SongListItem.instance()
		vbox_container.add_child(item)
		item.set_song(song, difficulty)
		item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
		item.connect("song_selected", self, "_on_song_selected")
	select_option(0)
	if previously_selected_song_id:
		for child_i in range(vbox_container.get_child_count()):
			var child = vbox_container.get_child(child_i)
			if child.song.id == previously_selected_song_id:
				select_option(child_i)
	emit_signal("option_hovered", selected_option)

func _input(event):
	if event.is_action_pressed("free_friends"):
		hard_arrange_all()
		print(rect_size.y)
