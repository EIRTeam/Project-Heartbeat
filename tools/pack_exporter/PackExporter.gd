extends PanelContainer

var songs_to_export: Array[HBSong]

@onready var song_list: ItemList = get_node("%SongList")
@onready var out_song_list: ItemList = get_node("%SongOutList")
@onready var search_line_edit: LineEdit = get_node("%SearchLineEdit")
@onready var add_selected_button: Button = get_node("%AddSelectedButton")
@onready var remove_selected_button: Button = get_node("%RemoveSelectedButton")
@onready var save_file_dialog: FileDialog = get_node("%SavePackageFileDialog")
@onready var status_progress: ProgressBar = get_node("%StatusProgress")
@onready var status_label: Label = get_node("%StatusLabel")
@onready var status_dialog: AcceptDialog = get_node("%StatusDialog")

var song_thumbnails: Dictionary[HBSong, Texture2D]

func reload_songs(filter: String):
	song_list.clear()
	for song_id in SongLoader.songs:
		var song: HBSong = SongLoader.songs[song_id]
		if song is HBPPDSong or song is HBPPDSong:
			continue
		var visible_title := song.get_visible_title()
		if filter.is_empty() or filter in visible_title.to_lower():
			var item_idx := add_song_item_to_list(song_list, song)
			if song in songs_to_export:
				song_list.set_item_disabled(item_idx, true)
				
			
func check_song_has_uncached_media(song: HBSong) -> bool:
	for variant_idx in [-1] + range(song.song_variants.size()):
		var variant := song.get_variant_data(variant_idx)
		if variant.variant_url.is_empty():
			continue
		if not variant.is_cached(true):
			return true
	return false
			
func check_song_has_uncached_main_media(song: HBSong) -> bool:
	for variant_idx in [-1]:
		var variant := song.get_variant_data(variant_idx)
		if variant.variant_url.is_empty():
			continue
		if not variant.is_cached(true):
			return true
	return false
			
func add_song_item_to_list(list: ItemList, song: HBSong) -> int:
	var title := song.get_visible_title()
	var item_idx := list.add_item(title)
	if check_song_has_uncached_main_media(song):
		list.set_item_text(item_idx, title + " (MISSING MEDIA)")
		list.set_item_disabled(item_idx, true)
	elif check_song_has_uncached_media(song):
		list.set_item_text(item_idx, title + " (MISSING VARIANT(s))")
	list.set_item_metadata(item_idx, song)
	return item_idx
			
func add_selected_songs():
	for idx in song_list.get_selected_items():
		var song := song_list.get_item_metadata(idx) as HBSong
		song_list.set_item_disabled(idx, true)
		if not song in songs_to_export:
			songs_to_export.push_back(song)
			add_song_item_to_list(out_song_list, song)
			
func remove_selected_output_songs():
	var selected_items := out_song_list.get_selected_items()
	selected_items.sort()
	selected_items.reverse()
	for idx in selected_items:
		var song := out_song_list.get_item_metadata(idx) as HBSong
		songs_to_export.erase(song)
		out_song_list.remove_item(idx)
		for item_idx in range(song_list.item_count):
			if song_list.get_item_metadata(item_idx) as HBSong == song:
				song_list.set_item_disabled(item_idx, false)
			
func _ready() -> void:
	if not SongLoader.initial_load_done:
		await SongLoader.all_songs_loaded
	search_line_edit.text_submitted.connect(reload_songs)
	song_list.item_activated.connect(func(_i: int): add_selected_songs())
	out_song_list.item_activated.connect(func(_i: int): remove_selected_output_songs())
	reload_songs("")
	add_selected_button.pressed.connect(add_selected_songs)
	remove_selected_button.pressed.connect(remove_selected_output_songs)
	%ReturnButton.pressed.connect(func():
		get_tree().change_scene_to_packed(load("res://menus/MainMenu3D.tscn"))
	)
	
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	
	%ExportButton.pressed.connect(_on_export_button_pressed)
	
	save_file_dialog.file_selected.connect(_on_export_file_selected)
	
	status_dialog.get_ok_button().hide()
	
func _on_export_file_selected(path: String):
	var writer := HBPackArchiveWriter.new(path)
	export_songs(writer)
	
	
func show_error(error: String):
	var dialog := AcceptDialog.new()
	dialog.dialog_text = error
	add_child(dialog)
	dialog.popup_centered()
	await dialog.visibility_changed
	dialog.queue_free()
	status_dialog.hide()
	
func _on_export_button_pressed():
	var has_uncached_songs := songs_to_export.any(check_song_has_uncached_media)
	
	if has_uncached_songs:
		var lines := PackedStringArray()
		lines.push_back("One or more songs you selected have variants that are missing their media! They cannot be exported.")
		lines.push_back("Would you like for the exported package to not include these variants?")
		lines.push_back("Affected variants are: \n")
		
		for song in songs_to_export:
			for variant_idx in range(song.song_variants.size()):
				var variant := song.get_variant_data(variant_idx)
				if variant.variant_url.is_empty():
					continue
				if not variant.is_cached(true):
					lines.append("{title} - Variant {variant_idx} ({variant_name})".format({
						"title": song.get_visible_title(),
						"variant_idx": variant_idx,
						"variant_name": variant.variant_name
					}))
		
		var accept_dialog := ConfirmationDialog.new()
		accept_dialog.ok_button_text = "Yes"
		accept_dialog.cancel_button_text = "No"
		accept_dialog.dialog_text = "\n".join(lines)
		add_child(accept_dialog)
		accept_dialog.popup_centered()
		accept_dialog.confirmed.connect(save_file_dialog.popup_centered)
		await accept_dialog.visibility_changed
		accept_dialog.queue_free()
		return
	save_file_dialog.popup_centered()
	
func song_uses_yt_urls(song: HBSong) -> bool:
	if not song.youtube_url.is_empty():
		return true
	for variant_idx in range(song.song_variants.size()):
		var variant_data := song.get_variant_data(variant_idx)
		if not variant_data.variant_url.is_empty():
			return true
	return false
	
func can_song_be_migrated(song: HBSong) -> bool:
	if song.get_fs_origin() != HBSong.SONG_FS_ORIGIN.USER:
		return false
	return song_uses_yt_urls(song)

func _show_status(message: String, progress: int, progress_max: int):
	status_label.text = message
	status_progress.max_value = progress_max
	status_progress.value = progress
	status_dialog.popup_centered()

func export_songs(packer: HBPackArchiveWriter):
	for song in songs_to_export:
		_show_status("Packing song %s..." % [song.get_visible_title()], songs_to_export.find(song), songs_to_export.size())
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN:
			return
		# Copy song dir so we can migrate it
		var temp := DirAccess.create_temp("song_migration")
		var temp_dir := temp.get_current_dir()

		var source_dir := DirAccess.open(song.path)
		source_dir.list_dir_begin()
		var file_name = source_dir.get_next()

		var song_meta_copy: HBSong = song.clone()

		while file_name != "":
			if not source_dir.current_is_dir():
				DirAccess.copy_absolute(song.path.path_join(file_name), temp_dir.path_join(file_name.to_lower()))
			file_name = source_dir.get_next()
		
		song_meta_copy.background_image = song_meta_copy.background_image.to_lower()
		song_meta_copy.preview_image = song_meta_copy.preview_image.to_lower()
		song_meta_copy.audio = song_meta_copy.audio.to_lower()
		song_meta_copy.video = song_meta_copy.video.to_lower()
		song_meta_copy.circle_image = song_meta_copy.circle_image.to_lower()
		song_meta_copy.circle_logo = song_meta_copy.circle_logo.to_lower()
		song_meta_copy.path = temp_dir
		song_meta_copy.id = song.id

		for variant: HBSongVariantData in song_meta_copy.song_variants:
			variant.variant_audio = variant.variant_audio.to_lower()
			variant.variant_video = variant.variant_video.to_lower()
		
		_show_status("Migrating song %s..." % [song.get_visible_title()], songs_to_export.find(song), songs_to_export.size())
		if can_song_be_migrated(song_meta_copy):
			var migrate_song_task := HBMigrateSongTask.new(song_meta_copy, true)
			migrate_song_task.run_migration()
			var migration_result := await migrate_song_task.migration_finished as HBMigrateSongTask.MigrationResult
			if migration_result.error != HBMigrateSongTask.MigrationError.OK:
				var message := migration_result.error_message
				message = "Error migrating song \"%s\":\n%s" % [song.get_visible_title(), message]
				show_error(message)
				return
		song_meta_copy.save_to_file(song_meta_copy.get_meta_path())
		var song_meta := HBPackItemSong.new()
		song_meta.title = song.title if not song._ugc_title.is_empty() else song._ugc_title
		song_meta.description = song._ugc_description if not song._ugc_description.is_empty() else ""
		song_meta.ugc_metadata = song._ugc_metadata
		packer.add_song(song_meta_copy, song_meta)
	packer.close()
	status_dialog.hide()
	
	var success := AcceptDialog.new()
	success.dialog_text = "Export completed succesfuly!"
	add_child(success)
	success.popup_centered()
	await success.visibility_changed
	success.queue_free()
