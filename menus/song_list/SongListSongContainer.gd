extends HBListContainer
const SongListItem = preload("res://menus/song_list/SongListItem.tscn")
const SongListItemDifficulty = preload("res://menus/song_list/SongListItemDifficulty.tscn")
signal song_hovered(song)
signal song_selected(song)
signal difficulty_selected(song, difficulty)

var song_items_map = {}

func _ready():
	connect("selected_option_changed", self, "_on_selected_option_changed")
	
func _on_selected_option_changed():
	emit_signal("song_hovered", selected_option.song)

func _on_song_selected(song: HBSong):
	if song_items_map.has(song):
		for difficulty in song_items_map[song]:
			var item = song_items_map[song][difficulty]
			remove_child(item)
			item.queue_free()
		song_items_map.erase(song)
	else:
		var vals = song_items_map.values()
		for i in range(song_items_map.size() - 1, -1, -1):
			for difficulty in vals[i]:
				var item = vals[i][difficulty]
				remove_child(item)
				item.queue_free()
		song_items_map = {}
		song_items_map[song] = {}
		var first = true
		var first_item_position
		var pos = selected_option.get_position_in_parent()
		prevent_hard_arrange = true
		for difficulty in song.charts:
			
			var item = SongListItemDifficulty.instance()
			add_child(item)
			pos += 1
			move_child(item, pos)
			item.rect_position = selected_option.rect_position
			item.rect_scale = Vector2(scale_factor, scale_factor)
			item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
			item.set_song(song, difficulty)
			item.connect("pressed", self, "_on_difficulty_selected", [song, difficulty])
			song_items_map[song][difficulty] = item
			print("APPENDING ", item)
		prevent_hard_arrange = false
#	emit_signal("song_selected", song)

func select_song_by_id(song_id: String, difficulty=null):
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	for child_i in range(get_child_count()):
		var child = get_child(child_i)
		if child.song.id == song_id:
			select_option(child_i)
			if difficulty:
				var song = SongLoader.songs[song_id]
				_on_song_selected(song)
				select_option(song_items_map[song][difficulty].get_position_in_parent())
			hard_arrange_all()
			break
func set_songs(songs: Array):
	var previously_selected_song_id = null
	var previously_selected_difficulty = null

	var vbox_container = self
	if selected_option:
		previously_selected_song_id = selected_option.song.id
		if selected_option is HBSongListItemDifficulty:
			print("DIFF")
			previously_selected_difficulty = selected_option.difficulty
			
	song_items_map = {}
			
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	for song in songs:
		var item = SongListItem.instance()
		vbox_container.add_child(item)
		item.set_song(song)
		item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
		item.connect("pressed", self, "_on_song_selected", [song])

	if previously_selected_song_id:
		for child_i in range(vbox_container.get_child_count()):
			var child = vbox_container.get_child(child_i)
			if child.song.id == previously_selected_song_id:
				select_option(child_i)
	else:
		select_option(0)

func _on_difficulty_selected(song, difficulty):
	print("DARK AND CRUEL")
	emit_signal("difficulty_selected", song, difficulty)

func _input(event):
	if event.is_action_pressed("free_friends"):
		hard_arrange_all()
