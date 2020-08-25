extends "SongListSongContainer.gd"

const SongListItemFolder = preload("res://menus/song_list/SongListFolder.tscn")
const SongListItemFolderBack = preload("res://menus/song_list/SongListFolderBack.tscn")

var folder_stack = []

signal updated_folders(folder_stack)
signal create_new_folder(parent)

func _ready():
	navigate_folder(UserSettings.user_settings.root_folder)
func _on_selected_option_changed():
	if selected_option is HBSongListItem:
		emit_signal("song_hovered", selected_option.song)
func navigate_folder(folder: HBFolder):
	if folder.songs.size() > 0 or folder.subfolders.size() > 0:
		folder_stack.append(folder)
		update_items()
		
func navigate_back():
	folder_stack.pop_back()
	update_items()
		
func go_to_root():
	folder_stack = []
	navigate_folder(UserSettings.user_settings.root_folder)
func update_items():
	for i in get_children():
		remove_child(i)
		i.queue_free()
	if folder_stack.size() == 0:
		return

	song_items_map = {}
	var current_folder = folder_stack[folder_stack.size()-1] as HBFolder
	
	if folder_stack.size() > 1:
		var back_item = SongListItemFolderBack.instance()
		back_item.connect("pressed", self, "navigate_back")
		back_item.connect("pressed", self, "update_items")
		add_child(back_item)
	
	for subfolder in current_folder.subfolders:
		var item = SongListItemFolder.instance()
		item.connect("pressed", self, "navigate_folder", [subfolder])
		item.set_folder(subfolder)
		add_child(item)
		
	sort_by_prop = current_folder.sort_mode
	
	var folder_songs = []
	
	for song_id in current_folder.songs:
		if song_id in SongLoader.songs:
			folder_songs.append(SongLoader.songs[song_id])
	var old_sort_by_mode = sort_by_prop
	sort_by_prop = current_folder.sort_mode
	folder_songs.sort_custom(self, "sort_array")
	sort_by_prop = old_sort_by_mode
		
	for song in folder_songs:
		_create_song_item(song)
		
	select_option(0)
	hard_arrange_all()
	emit_signal("updated_folders", folder_stack)

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

func _create_song_item(song: HBSong):
	var item = SongListItem.instance()
	add_child(item)
	item.set_song(song)
	item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
	item.connect("pressed", self, "_on_song_selected", [song])

func select_song_by_id(song_id: String, difficulty=null):
	for child_i in range(get_child_count()):
		var child = get_child(child_i)
		if child.song.id == song_id:
			if difficulty:
				var song = SongLoader.songs[song_id]
				select_option(child_i)
				if not song in song_items_map:
					_on_song_selected(song)
				select_option(song_items_map[song][difficulty].get_position_in_parent())
			else:
				select_option(child_i)
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
	elif prop == "score":
		a_prop = b.get_max_score()
		b_prop = a.get_max_score()
	if a_prop is String:
		a_prop = a_prop.to_lower()
	if b_prop is String:
		b_prop = b_prop.to_lower()
	return a_prop < b_prop

func sort_and_filter_songs():
	songs.sort_custom(self, "sort_array")
	Log.log(self, "Filtering by " + filter_by)

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
	if filter_name == "folders":
		filter_by = filter_name
		update_items()
	else:
		.set_filter(filter_name)
		
func set_songs(songs: Array):
	self.songs = songs
	if filter_by == "folders":
		return
	var filtered_songs = sort_and_filter_songs()
	var previously_selected_song_id = null
	var previously_selected_difficulty = null

	var vbox_container = self
	
	var is_song_selected = selected_option is HBSongListItem
	
	if selected_option and is_song_selected:
		previously_selected_song_id = selected_option.song.id
		if selected_option is HBSongListItemDifficulty:
			previously_selected_difficulty = selected_option.difficulty
			
	song_items_map = {}
			
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	for song in filtered_songs:
		_create_song_item(song)
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
			if previously_selected_difficulty:
				select_song_by_id(previously_selected_song_id, previously_selected_difficulty)
	else:
		if filtered_songs.size() <= items_visible_top:
			if filtered_songs.size() > 0:
				select_option(ceil((filtered_songs.size()-1)/2.0))
		else:
			var initial_item = clamp(items_visible_top, 0, get_child_count())
			select_option(initial_item)

func _on_difficulty_selected(song, difficulty):

	emit_signal("difficulty_selected", song, difficulty)

func _input(event):
	if event.is_action_pressed("free_friends"):
		hard_arrange_all()

func _on_create_new_folder():
	var parent = folder_stack[folder_stack.size()-1]
	emit_signal("create_new_folder", parent)
