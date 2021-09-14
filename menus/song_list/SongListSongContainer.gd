extends HBUniversalScrollList

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")
const SongListItemFolder = preload("res://menus/song_list/SongListFolder.tscn")
const SongListItemFolderBack = preload("res://menus/song_list/SongListFolderBack.tscn")
const SongListItemDifficulty = preload("res://menus/song_list/SongListItemDifficulty.tscn")

var folder_stack = []

var song_difficulty_items_map = {}

var sort_by_prop = "title" # title, chart creator, difficulty
var filter_by = "" # choices are: all, official, community and ppd
var songs = []
var search_term = ""

signal updated_folders(folder_stack)
signal create_new_folder(parent)
signal start_loading
signal end_loading
signal hover_nonsong
signal song_hovered(song)
signal difficulty_selected(song, difficulty)
signal show_no_folder_label
signal hide_no_folder_label

var filtered_song_items = {}

class DummySongListEntry:
	extends HBUniversalListItem

	signal dummy_sighted
	
	var song: HBSong

	func _init():
		set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
		rect_min_size.y = 100
	func hover():
		pass
	func stop_hover():
		pass
	func _become_visible():
		emit_signal("dummy_sighted")

func get_starting_folder(starting_folders: Array, path: Array) -> Array:
	if path.size() == 0:
		return starting_folders
	for folder in starting_folders.back().subfolders:
		if folder.folder_name == path[0]:
			path.pop_front()
			starting_folders = get_starting_folder(starting_folders + [folder], path)
			break
	return starting_folders
func _ready():
	sort_by_prop = UserSettings.user_settings.sort_mode
	connect("selected_item_changed", self, "_on_selected_item_changed")
	focus_mode = Control.FOCUS_ALL

func _on_selected_item_changed():
	var selected_item = get_selected_item()
	if selected_item:
		if selected_item is DummySongListEntry:
			pass
		elif selected_item is HBSongListItem or selected_item is HBSongListItemDifficulty:
			emit_signal("song_hovered", selected_item.song)
		else:
			emit_signal("hover_nonsong")
func navigate_folder(folder: HBFolder):
	folder_stack.append(folder)
	update_items()
		
func navigate_back():
	folder_stack.pop_back()
	update_items()
	
func go_to_root():
	folder_stack = []
	navigate_folder(UserSettings.user_settings.root_folder)

func _create_song_item(song: HBSong):
	var item = SongListItem.instance()
	item.use_parent_material = true
	item.set_song(song)
	item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
	item.connect("pressed", self, "_on_song_selected", [song])
	return item
func update_items():
	for i in item_container.get_children():
		item_container.remove_child(i)
		i.queue_free()
	
	if folder_stack.size() == 1 and folder_stack[0].songs.size() == 0 and folder_stack[0].subfolders.size() == 0:
		emit_signal("show_no_folder_label")
		current_selected_item = -1
		emit_signal("updated_folders", folder_stack)
		return

	song_difficulty_items_map = {}
	var current_folder = folder_stack[folder_stack.size()-1] as HBFolder
	
	if folder_stack.size() > 1:
		var back_item = SongListItemFolderBack.instance()
		back_item.connect("pressed", self, "navigate_back")
		back_item.connect("pressed", self, "update_items")
		item_container.add_child(back_item)
	
	for subfolder in current_folder.subfolders:
		var item = SongListItemFolder.instance()
		item.connect("pressed", self, "navigate_folder", [subfolder])
		item.set_folder(subfolder)
		item_container.add_child(item)
		
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
		if not search_term or (search_term in song.title.to_lower() or search_term in song.romanized_title.to_lower()):
			var item = _create_song_item(song)
			item_container.add_child(item)
		
		
	# TODO: HARD ARRANGE
	select_item(0)
	force_scroll()
#	hard_arrange_all()
	UserSettings.user_settings.last_folder_path = []
	for f in folder_stack:
		UserSettings.user_settings.last_folder_path.append(f.folder_name)
	UserSettings.save_user_settings()
	emit_signal("updated_folders", folder_stack)
	emit_signal("hide_no_folder_label")

func _on_song_selected(song: HBSong):
	if song_difficulty_items_map.has(song):
		for difficulty in song_difficulty_items_map[song]:
			var item = song_difficulty_items_map[song][difficulty]
			item_container.remove_child(item)
			item.queue_free()
			
		song_difficulty_items_map.erase(song)
	else:
		var vals = song_difficulty_items_map.values()
		for i in range(song_difficulty_items_map.size() - 1, -1, -1):
			for difficulty in vals[i]:
				var item = vals[i][difficulty]
				item_container.remove_child(item)
				item.queue_free()
		select_song_by_id(song.id, null)

		song_difficulty_items_map = {}
		song_difficulty_items_map[song] = {}
		var selected_item = get_selected_item()
		var pos = selected_item.get_position_in_parent()
		#prevent_hard_arrange = true
		
		
		var difficulty_map = []
		for difficulty in song.charts:
			difficulty_map.append({"diff": difficulty, "stars": song.charts[difficulty]["stars"]})
		
		difficulty_map.sort_custom(self, "_sort_by_difficulty")
		
		for entry in difficulty_map:
			
			var item = SongListItemDifficulty.instance()
			item_container.add_child(item)
			pos += 1
			item_container.move_child(item, pos)
			item.rect_position = selected_item.rect_position
			# TODO: ITEM SCALES!
#			item.rect_scale = Vector2(scale_factor, scale_factor)
			item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
			item.set_song_difficulty(song, entry["diff"])
			if selected_item is HBSongListItem:
				if song.is_chart_note_usage_known_all():
					item.show_note_usage()
				else:
					if selected_item.task:
						selected_item.task.connect("assets_loaded", item, "_on_note_usage_loaded")
					else:
						print("Error connecting note usage task, BUG?")
			item.connect("pressed", self, "_on_difficulty_selected", [song, entry["diff"]])
			song_difficulty_items_map[song][entry["diff"]] = item

static func _sort_by_difficulty(a, b):
	return a["stars"] > b["stars"]

func select_song_by_id(song_id: String, difficulty=null):
	for child_i in range(item_container.get_child_count()):
		var child = item_container.get_child(child_i)
		if "song" in child:
			if child.song.id == song_id:
				if difficulty:
					var song = SongLoader.songs[song_id]
					select_item(child_i)
					if not song in song_difficulty_items_map:
						_on_song_selected(song)
					select_item(song_difficulty_items_map[song][difficulty].get_position_in_parent())
				else:
					select_item(child_i)

func sort_array(a: HBSong, b: HBSong):
	var prop = sort_by_prop
	var a_prop = a.get(prop)
	var b_prop = b.get(prop)
	if prop == "title":
		a_prop = a.get_visible_title()
		b_prop = b.get_visible_title()
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

var last_filter = ""

func set_filter(filter_name: String):
	if filter_name == "folders":
		filter_by = filter_name
		last_filter = "folders"
		var path = UserSettings.user_settings.last_folder_path.duplicate()
		path.pop_front()
		var starting_folders = get_starting_folder([UserSettings.user_settings.root_folder], path)
		folder_stack = []

		for folder in starting_folders:
			navigate_folder(folder)
	else:
		emit_signal("hide_no_folder_label")
		last_filter = filter_by
		if filter_by != filter_name:
			filter_by = filter_name
			if songs.size() > 0:
				set_songs(songs)
#				hard_arrange_all()
		
func _on_dummy_sighted(song: HBSong):
	var dummy = filtered_song_items[song]
	var item = _create_song_item(song)
	item_container.add_child_below_node(dummy, item)
	item_container.remove_child(dummy)
	dummy.queue_free()
	item.rect_position = dummy.rect_position
	filtered_song_items[song] = item
	if item.get_position_in_parent() == current_selected_item:
		force_scroll()
		
func _on_songs_filtered(filtered_songs: Array, song_id_to_select=null, song_difficulty_to_select=null):
	var previously_selected_song_id = null
	var previously_selected_difficulty = null
	var selected_item = get_selected_item()
	var is_song_selected = selected_item is HBSongListItem or selected_item is HBSongListItemDifficulty
	
	if selected_item and is_song_selected:
		previously_selected_song_id = selected_item.song.id
		if selected_item is HBSongListItemDifficulty:
			previously_selected_difficulty = selected_item.difficulty
		
	song_difficulty_items_map = {}
			
	for child in item_container.get_children():
		item_container.remove_child(child)
		child.queue_free()
#	filtered_song_items = song_items
#	for song in song_items:
#		var item = song_items[song]
#		item_container.add_child(item)
#		item.update_scale(item.get_scale(), true)
#		item.use_parent_material = true
#		item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
#		item.connect("pressed", self, "_on_song_selected", [song])
#	selected_option = null

	filtered_song_items = {}

	var base_dummy := DummySongListEntry.new()
	for song in filtered_songs:
		var dummy := base_dummy.duplicate()
		item_container.add_child(dummy)
		dummy.song = song
		dummy.connect("dummy_sighted", self, "_on_dummy_sighted", [song])
		filtered_song_items[song] = dummy
	

	select_item(0)
	if previously_selected_song_id:
		var found_child = false
		for child_i in range(item_container.get_child_count()):
			var child = item_container.get_child(child_i)
			if child.song.id == previously_selected_song_id:
				select_item(child_i)
				found_child = true
				break
		if not found_child:
			select_item(0)
		else:
			if previously_selected_difficulty:
				select_song_by_id(previously_selected_song_id, previously_selected_difficulty)
	else:
		if filtered_songs.size() <= 3:
			if filtered_songs.size() > 0:
				select_item(ceil((filtered_songs.size()-1)/2.0))
		else:
			var initial_item = clamp(3, 0, get_child_count())
			select_item(initial_item)
#	hard_arrange_all()
		
		
	if song_id_to_select:
		call_deferred("select_song_by_id", song_id_to_select, song_difficulty_to_select)
		
		
	emit_signal("end_loading")
		
var current_filter_task: HBTask
		
func set_songs(_songs: Array, select_song_id=null, select_difficulty=null, force_update=false):
	songs = _songs

	if filter_by == "folders":
		if select_song_id:
			select_song_by_id(select_song_id, select_difficulty)
		return
	
	if filter_by == last_filter and not force_update:
		if select_song_id:
			select_song_by_id(select_song_id, select_difficulty)
		return

	for i in item_container.get_children():
		item_container.remove_child(i)
		i.queue_free()
	
	if current_filter_task:
		AsyncTaskQueueLight.abort_task(current_filter_task)
		
	current_filter_task = HBFilterSongsTask.new(songs, filter_by, sort_by_prop, select_song_id, select_difficulty, search_term)
	current_filter_task.connect("songs_filtered", self, "_on_songs_filtered")

#	selected_option = null
	
	emit_signal("start_loading")
	AsyncTaskQueueLight.queue_task(current_filter_task)
	
func _on_difficulty_selected(song, difficulty):
	emit_signal("difficulty_selected", song, difficulty)

func _input(event):
	if event is InputEventKey and event.shift:
		var c = char(event.unicode)
		if c.length() == 1:
			for song in songs:
				if song.get_visible_title().begins_with(c):
					select_song_by_id(song.id)
					break

func _gui_input(event):
	pass

func _on_create_new_folder():
	var parent = folder_stack[folder_stack.size()-1]
	emit_signal("create_new_folder", parent)
