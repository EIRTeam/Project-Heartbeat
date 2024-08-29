extends HBUniversalScrollList

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")
const SongListItemFolder = preload("res://menus/song_list/SongListFolder.tscn")
const SongListItemFolderBack = preload("res://menus/song_list/SongListFolderBack.tscn")

const RANDOM_SELECT_BUTTON_SCENE = preload("res://menus/song_list/SongListItemRandom.tscn")

var folder_stack = []

var song_difficulty_items_map = {}

var songs = []

var filter_settings: HBSongSortFilterSettings:
	set(val):
		filter_settings = val

signal updated_folders(folder_stack)
signal create_new_folder(parent)
signal start_loading
signal end_loading
signal hover_nonsong
signal song_hovered(song)
signal difficulty_selected(song, difficulty)
signal show_no_folder_label
signal hide_no_folder_label
signal unsubscribe_requested(song: HBSong)

var filtered_song_items = {}

var selected_index_stack = []

# How many elements to skip on a page change
const PAGE_CHANGE_COUNT := 8

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
	super._ready()
	
	connect("selected_item_changed", Callable(self, "_on_selected_item_changed"))
	focus_mode = Control.FOCUS_ALL

var item_visibility_update_queued := false

func _on_selected_item_changed():
	var selected_item = get_selected_item()
	if selected_item:
		if selected_item is HBSongListItem:
			emit_signal("song_hovered", selected_item.song)
		else:
			emit_signal("hover_nonsong")
	
	if selected_index_stack:
		selected_index_stack[-1] = current_selected_item

func navigate_folder(folder: HBFolder):
	folder_stack.append(folder)
	selected_index_stack.append(0)
	update_folder_items()

func navigate_back():
	selected_index_stack.pop_back()
	folder_stack.pop_back()
	update_folder_items()

func go_to_root():
	folder_stack = []
	selected_index_stack = []
	navigate_folder(UserSettings.user_settings.root_folder)

func _on_song_item_pressed(control: Control):
	pass

func _create_song_item(song: HBSong):
	var item = SongListItem.instantiate()
	item.use_parent_material = true
	item.set_song(song)
	assert(song)
	item.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	item.pressed.connect(self.smooth_scroll_to.bind(0.0))
	item.pressed.connect(self._on_song_selected.bind(song, item))
	item.ready.connect(item._become_visible)
	item.difficulty_selected.connect(self._on_difficulty_selected)
	item.unsubscribe_requested.connect(unsubscribe_requested.emit)
	return item
func update_folder_items():
	if folder_stack.size() == 0:
		return
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
		var back_item = SongListItemFolderBack.instantiate()
		back_item.connect("pressed", Callable(self, "navigate_back"))
		back_item.connect("pressed", Callable(self, "update_folder_items"))
		item_container.add_child(back_item)
	
	var rand = RANDOM_SELECT_BUTTON_SCENE.instantiate()
	rand.connect("pressed", Callable(self, "_on_random_pressed"))
	item_container.add_child(rand)
	
	for subfolder in current_folder.subfolders:
		var item = SongListItemFolder.instantiate()
		item.connect("pressed", Callable(self, "navigate_folder").bind(subfolder))
		item.set_folder(subfolder)
		item_container.add_child(item)
		
	var folder_songs = []
	
	for song_id in current_folder.songs:
		if song_id in SongLoader.songs:
			folder_songs.append(SongLoader.songs[song_id])
	folder_songs.sort_custom(Callable(self, "sort_array"))
	for song in folder_songs:
		if UserSettings.user_settings.sort_filter_settings.filter_has_media_only and not song.is_cached():
			continue
		for field in [song.title.to_lower(), song.original_title.to_lower(), song.romanized_title.to_lower()]:
			if filter_settings.search_term.is_empty() or filter_settings.search_term in field:
				var item = _create_song_item(song)
				item_container.add_child(item)
				break
	
	var prev_selected_item := 0
	if selected_index_stack:
		prev_selected_item = selected_index_stack[-1]
	
	select_item(min(prev_selected_item, item_container.get_child_count()-1))
	force_scroll()
#	hard_arrange_all()
	UserSettings.user_settings.last_folder_path = []
	for f in folder_stack:
		UserSettings.user_settings.last_folder_path.append(f.folder_name)
	UserSettings.save_user_settings()
	emit_signal("updated_folders", folder_stack)
	emit_signal("hide_no_folder_label")

func _on_song_selected(song: HBSong, item: Control):
	if item and current_selected_item != item.get_index():
		select_item(item.get_index())

static func _sort_by_difficulty(a, b):
	return a["stars"] > b["stars"]

func select_song_by_id(song_id: String, difficulty=null):
	for child_i in range(item_container.get_child_count()):
		var child = item_container.get_child(child_i)
		var song: HBSong
		if child is HBUniversalScrollList.DummyItem:
			song = child.get_meta(&"song") as HBSong
		elif child is HBSongListItem:
			song = child.song
		else:
			continue
		if song:
			if song.id == song_id:
				select_item(child_i)

func sort_array(a: HBSong, b: HBSong):
	var prop = filter_settings.sort_prop
	var a_prop = a.get(prop)
	var b_prop = b.get(prop)
	
	match prop:
		"title":
			a_prop = a.get_visible_title()
			b_prop = b.get_visible_title()
		"artist":
			a_prop = a.get_artist_sort_text()
			b_prop = b.get_artist_sort_text()
		"score":
			a_prop = b.get_max_score()
			b_prop = a.get_max_score()
		"_times_played":
			a_prop = HBGame.song_stats.get_song_stats(a.id).times_played
			b_prop = HBGame.song_stats.get_song_stats(b.id).times_played
	
	if a_prop is String:
		a_prop = a_prop.to_lower()
	if b_prop is String:
		b_prop = b_prop.to_lower()
	
	if filter_settings.sort_prop != "_added_time":
		return a_prop < b_prop
	else:
		return b_prop < a_prop

var last_filter = ""

func on_filter_changed(song_id_to_select: String = ""):
	last_filter = filter_settings.filter_mode
	if filter_settings.filter_mode == "folders":
		var path = UserSettings.user_settings.last_folder_path.duplicate()
		path.pop_front()
		var starting_folders = get_starting_folder([UserSettings.user_settings.root_folder], path)
		folder_stack = []
		
		for folder in starting_folders:
			navigate_folder(folder)
	else:
		emit_signal("hide_no_folder_label")
		if songs.size() > 0:
			var s = null
			if not song_id_to_select.is_empty():
				s = song_id_to_select
			set_songs(songs, s, null, true)
#				hard_arrange_all()
		
func _on_dummy_sighted(song: HBSong):
	var dummy = filtered_song_items[song] as Control
	var item = _create_song_item(song)
	replace_dummy(dummy, item)
	filtered_song_items[song] = item
	if item.get_index() == current_selected_item:
		force_scroll()
		_on_selected_item_changed()
		
func _on_songs_filtered(filtered_songs: Array, song_id_to_select=null, song_difficulty_to_select=null):
	var previously_selected_song_id = null
	var previously_selected_difficulty = null
	var selected_item = get_selected_item()
	var is_song_selected = selected_item is HBSongListItem
	
	if selected_item and is_song_selected:
		previously_selected_song_id = selected_item.song.id
		
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

	if filter_settings.search_term.is_empty():
		var rand = RANDOM_SELECT_BUTTON_SCENE.instantiate()
		rand.connect("pressed", Callable(self, "_on_random_pressed"))
		item_container.add_child(rand)

	const PLACEHOLDER_SCENE := preload("res://menus/song_list/SongListPlaceholder.tscn")

	for song in filtered_songs:
		var dummy := add_dummy()
		dummy.set_meta(&"song", song)
		dummy.custom_minimum_size.y = 125
		dummy.sighted.connect(self._on_dummy_sighted.bind(song))
		var placeholder := PLACEHOLDER_SCENE.instantiate()
		dummy.add_child(placeholder)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		filtered_song_items[song] = dummy
	

	select_item(0)
	if previously_selected_song_id:
		var found_child = false
		for child_i in range(item_container.get_child_count()):
			var child = item_container.get_child(child_i)
			if child is HBSongListItemRandom:
				continue
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
		select_song_by_id.call_deferred(song_id_to_select, song_difficulty_to_select)
		
		
	emit_signal("end_loading")
	
func _on_random_pressed():
	select_item(1 + (randi() % item_container.get_child_count()-1))
		
var current_filter_task: HBFilterSongsTask
		
func remove_song(song: HBSong):
	var song_item: HBSongListItem = filtered_song_items.get(song, null)
	if song_item:
		var idx := song_item.get_index()
		filtered_song_items.erase(song)
		item_container.remove_child(song_item)
		song_item.queue_free()
		select_item(min(idx, item_container.get_child_count()-1))
func set_songs(_songs: Array, select_song_id=null, select_difficulty=null, force_update=false):
	songs = _songs

	if filter_settings.filter_mode == "folders":
		if select_song_id:
			select_song_by_id(select_song_id, select_difficulty)
		return
	
	if filter_settings.filter_mode == last_filter and not force_update:
		if select_song_id:
			select_song_by_id(select_song_id, select_difficulty)
		return

	for i in item_container.get_children():
		item_container.remove_child(i)
		i.queue_free()
	current_filter_task = HBFilterSongsTask.new(filter_settings, songs, select_song_id, select_difficulty)
	current_filter_task.queue()
	emit_signal("start_loading")
	
	last_filter = filter_settings.filter_mode
	
	var filter_task := current_filter_task
	var cb_data := await current_filter_task.songs_filtered as Array
	if current_filter_task == filter_task:
		_on_songs_filtered.callv(cb_data)

	
func _on_difficulty_selected(song, difficulty):
	emit_signal("difficulty_selected", song, difficulty)

func _unhandled_input(event: InputEvent):
	super._input(event)
	if event is InputEventKey and event.shift_pressed:
		var c = char(event.unicode)
		if c.length() == 1:
			for song in songs:
				if song.get_visible_title().begins_with(c):
					select_song_by_id(song.id)
					break
	if has_focus():
		if event.is_action_pressed("gui_page_down"):
			get_viewport().set_input_as_handled()
			select_item(min(current_selected_item+PAGE_CHANGE_COUNT, item_container.get_child_count()-1))
		elif event.is_action_pressed("gui_page_up"):
			get_viewport().set_input_as_handled()
			select_item(max(current_selected_item-PAGE_CHANGE_COUNT, 0))

func _on_create_new_folder():
	var parent = folder_stack[folder_stack.size()-1]
	emit_signal("create_new_folder", parent)
