extends HBListContainer
const SongListItem = preload("res://menus/song_list/SongListItem.tscn")
const SongListItemDifficulty = preload("res://menus/song_list/SongListItemDifficulty.tscn")
signal song_hovered(song)
signal song_selected(song)
signal difficulty_selected(song, difficulty)

var song_items_map = {}

var songs

var sort_by_prop = "title" # title, chart creator, difficulty
var filter_by = "all" # choices are: all, official, community and ppd
func _ready():
	sort_by_prop = UserSettings.user_settings.sort_mode
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
		prevent_hard_arrange = false
#	emit_signal("song_selected", song)

func select_song_by_id(song_id: String, difficulty=null):
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

func sort_array(a: HBSong, b: HBSong):
	var prop = sort_by_prop
	var a_prop = a.get(prop)
	var b_prop = b.get(prop)
	if prop == "title" and a.romanized_title:
		a_prop = a.romanized_title
	elif prop == "title" and b.romanized_title:
		b_prop = b.romanized_title
	elif prop == "artist":
		a_prop = a.get_artist_sort_text()
		b_prop = b.get_artist_sort_text()
	return a_prop < b_prop

func sort_and_filter_songs():
	songs.sort_custom(self, "sort_array")
	if filter_by != "all":
		var filtered_songs = []
		for song in songs:
			var should_add_song = false
			match filter_by:
				"ppd":
					should_add_song = song is HBPPDSong
				"official":
					should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN
				"community":
					should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER and not song is HBPPDSong
			if should_add_song:
				filtered_songs.append(song)
		return filtered_songs
	else:
		return songs
func set_filter(filter_name: String):
	if filter_by != filter_name:
		filter_by = filter_name
		set_songs(songs)
		hard_arrange_all()
	
		
func set_songs(songs: Array):
	self.songs = songs
	var filtered_songs = sort_and_filter_songs()
	var previously_selected_song_id = null
	var previously_selected_difficulty = null

	var vbox_container = self
	if selected_option:
		previously_selected_song_id = selected_option.song.id
		if selected_option is HBSongListItemDifficulty:
			previously_selected_difficulty = selected_option.difficulty
			
	song_items_map = {}
			
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	for song in filtered_songs:
		var item = SongListItem.instance()
		vbox_container.add_child(item)
		item.set_song(song)
		item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
		item.connect("pressed", self, "_on_song_selected", [song])
	if previously_selected_song_id:
		var found_child = false
		for child_i in range(vbox_container.get_child_count()):
			var child = vbox_container.get_child(child_i)
			if child.song.id == previously_selected_song_id:
				select_option(child_i)
				found_child = true
				break
		if not found_child:
			select_option(0)
		
	else:
		select_option(0)

func _on_difficulty_selected(song, difficulty):

	emit_signal("difficulty_selected", song, difficulty)

func _input(event):
	if event.is_action_pressed("free_friends"):
		hard_arrange_all()
