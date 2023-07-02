extends ConfirmationDialog

@onready var tree = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Tree")
@onready var new_song_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/NewSongButton")
@onready var add_chart_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/AddDifficultyButton")
@onready var edit_data_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/EditDataButton")
@onready var song_meta_editor_dialog = get_node("SongMetaEditorDialog")
@onready var song_meta_editor = get_node("SongMetaEditorDialog/SongMetaEditor")
@onready var create_difficulty_dialog = get_node("CreateDifficultyDialog")
@onready var create_song_dialog = get_node("CreateSongDialog")
@onready var delete_chart_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/DeleteChartButton")
@onready var delete_confirmation_dialog = get_node("DeleteConfirmationDialog")
@onready var verify_song_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/VerifySongButton")
@onready var verify_song_popup = get_node("SongVerificationPopup")
@onready var upload_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/UploadToWorkshopButton")
@onready var workshop_upload_dialog = get_node("WorkshopUploadDialog")
@onready var search_line_edit: LineEdit = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SearchLineEdit")
signal chart_selected(song, difficulty, hidden)

const LOG_NAME = "EditorOpenChartPopup"

# If we should show songs in res://
var show_hidden = false

func _ready():
	connect("about_to_popup", Callable(self, "_on_about_to_show"))
	tree.connect("item_selected", Callable(self, "_on_item_selected"))
	edit_data_button.connect("pressed", Callable(self, "_show_meta_editor"))
	new_song_button.connect("pressed", Callable(create_song_dialog, "popup_centered"))
	create_song_dialog.connect("confirmed", Callable(self, "_on_CreateSongDialog_confirmed"))
#	call_deferred("popup_centered")
	connect("confirmed", Callable(self, "_on_confirmed"))
	add_chart_button.connect("pressed", Callable(create_difficulty_dialog, "popup_centered"))
	create_difficulty_dialog.connect("difficulty_created", Callable(self, "_on_difficulty_created"))
	delete_chart_button.connect("pressed", Callable(delete_confirmation_dialog, "popup_centered"))
	delete_confirmation_dialog.connect("confirmed", Callable(self, "_on_chart_deleted"))
	verify_song_button.connect("pressed", Callable(self, "_on_verify_button_pressed"))
	upload_button.connect("pressed", Callable(self, "_on_upload_to_workshop_pressed"))
	search_line_edit.connect("text_changed", Callable(self, "_on_search_text_changed"))
	
func _on_search_text_changed(_new_text: String):
	populate_tree()
	
func _on_upload_to_workshop_pressed():
	var item = tree.get_selected()
	var song = item.get_meta("song") as HBSong
	var verification = HBSongVerification.new()
	var errors = verification.verify_song(song)
	if not (song.youtube_url and song.use_youtube_for_audio) or song.audio:
		var error = {
			"type": -1,
			"string": "Workshop songs must not have an audio file, instead you should use a YouTube video.",
			"fatal": false,
			"warning": false,
			"fatal_ugc": true
		}
		errors["meta"].append(error)
	if verification.has_fatal_error(errors, true) and not HBGame.enable_editor_dev_mode:
		verify_song_popup.show_song_verification(errors, true, "Before you can upload your song, there are some issues you have to resolve:")
	else:
		workshop_upload_dialog.set_song(song)
		workshop_upload_dialog.popup_centered_ratio()
	
func _on_verify_button_pressed():
	var item = tree.get_selected()
	var song = item.get_meta("song") as HBSong
	var verification = HBSongVerification.new()
	verify_song_popup.show_song_verification(verification.verify_song(song), false)
func populate_tree():
	# Disable song-specific buttons
	add_chart_button.disabled = true
	edit_data_button.disabled = true
	delete_chart_button.disabled = true
	verify_song_button.disabled = true
	upload_button.disabled = true
	get_ok_button().disabled = true
	
	tree.clear()
	var _root = tree.create_item()
	
	for song in SongLoader.songs.values():
		# Only show editor and local songs by default, but allow opening everything as read-only
		var hidden = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN or \
			song.comes_from_ugc() or song is HBPPDSong or \
			song is SongLoaderDSC.HBSongMMPLUS or song is SongLoaderDSC.HBSongDSC
		if hidden and not show_hidden:
			continue
		
		var origin = ""
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN:
			origin = " (Official)"
		elif song.comes_from_ugc():
			origin = " (Workshop)"
		elif song is HBPPDSong:
			origin = " (PPD)"
		elif song is SongLoaderDSC.HBSongMMPLUS:
			origin = " (MegaMix+)"
		elif song is SongLoaderDSC.HBSongDSC:
			origin = " (DSC Loader)"
		
		for field in [song.title, song.romanized_title, song.original_title]:
			if search_line_edit.text.is_empty() or search_line_edit.text.to_lower() in (field + origin).to_lower():
				var item = tree.create_item()
				
				item.set_text(0, song.get_visible_title() + origin)
				
				item.set_meta("song", song)
				item.set_meta("hidden", hidden and not HBGame.enable_editor_dev_mode)
				
				for difficulty in song.charts:
					var diff_item = tree.create_item(item)
					
					diff_item.set_text(0, difficulty.capitalize())
					
					diff_item.set_meta("song", song)
					diff_item.set_meta("difficulty", difficulty)
					diff_item.set_meta("hidden", hidden and not HBGame.enable_editor_dev_mode)
				
				break
	
func _on_item_selected():
	var item = tree.get_selected()
	
	if item.has_meta("difficulty"):
		get_ok_button().disabled = false
		delete_chart_button.disabled = item.get_meta("hidden")
	else:
		get_ok_button().disabled = true
		delete_chart_button.disabled = true
	
	edit_data_button.disabled = false
	if item.get_meta("hidden"):
		edit_data_button.text = "Display song data"
	else:
		edit_data_button.text = "Edit song data"
	
	add_chart_button.disabled = item.get_meta("hidden")
	verify_song_button.disabled = item.get_meta("hidden")
	upload_button.disabled = item.get_meta("hidden")
	
func _on_about_to_show():
	populate_tree()

func _show_meta_editor():
	song_meta_editor.hidden = tree.get_selected().get_meta("hidden")
	song_meta_editor.song_meta = tree.get_selected().get_meta("song")
	
	song_meta_editor_dialog.size = Vector2.ZERO
	song_meta_editor_dialog.popup_centered_clamped(Vector2(500, 650))
	song_meta_editor_dialog.get_ok_button().disabled = tree.get_selected().get_meta("hidden")

func _on_CreateSongDialog_confirmed():
	if $CreateSongDialog/VBoxContainer/LineEdit.text != "":
		var song_name = HBUtils.get_valid_filename($CreateSongDialog/VBoxContainer/LineEdit.text)
		if song_name != "":
			var editor_song_folder = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs/%s")
			
			var song_meta = HBSong.new()
			song_meta.title = $CreateSongDialog/VBoxContainer/LineEdit.text
			song_meta.id = song_name
			song_meta.path = editor_song_folder % song_name
			song_meta.save_song()
			SongLoader.songs[song_meta.id] = song_meta
			populate_tree()

func show_error(error: String):
	$AcceptDialog.dialog_text = error
	$AcceptDialog.size = Vector2.ZERO
	$AcceptDialog.popup_centered(Vector2(500, 100))
func _on_confirmed():
	var item = tree.get_selected()
	
	var song = item.get_meta("song") as HBSong
	if not song.is_cached():
		MouseTrap.cache_song_overlay.show_download_prompt(song)
		return
	
	if not item.get_meta("hidden"):
		var verification = HBSongVerification.new()
		var errors = verification.verify_song(song)
		
		# We ignore file not found errors for charts
		for error_class in errors:
			if error_class.begins_with("chart_"):
				for i in range(errors[error_class].size()-1, -1, -1):
					var error = errors[error_class][i]
					if error.type == HBSongVerification.CHART_ERROR.FILE_NOT_FOUND:
						errors[error_class].remove_at(i)
		
		if verification.has_fatal_error(errors):
			var err = "Some errors need to be resolved before you can edit your chart, warnings don't need to be resolved but it's very recommended"
			verify_song_popup.show_song_verification(verification.verify_song(song), false, err)
			
			return
	
	emit_signal("chart_selected", song, item.get_meta("difficulty"), item.get_meta("hidden"))
	hide()

func _on_SongMetaEditorDialog_confirmed():
	song_meta_editor.save_meta()
	populate_tree()

func _on_difficulty_created(difficulty: String, stars, uses_console_style = false):
	var song = tree.get_selected().get_meta("song") as HBSong
	var diff = HBUtils.get_valid_filename(difficulty.strip_edges())
	if diff.to_lower() in song.charts:
		show_error("A chart with that name already exists")
		populate_tree()
		return
	if diff:
		song.charts[difficulty.to_lower()] = {
			"file": diff.to_lower() + ".json",
			"stars": stars,
			"note_usage": []
		}
		song.save_song()
		
		var chart = HBChart.new()
		if not uses_console_style:
			chart.editor_settings.hidden_layers.erase("SLIDE_LEFT2")
			chart.editor_settings.hidden_layers.erase("SLIDE_RIGHT2")
		else:
			chart.editor_settings.hidden_layers.append("SLIDE_LEFT")
			chart.editor_settings.hidden_layers.append("SLIDE_RIGHT")
			chart.editor_settings.hidden_layers.erase("HEART")
		var json = JSON.stringify(chart.serialize(), "  ")
		
		var f = FileAccess.open(song.get_chart_path(difficulty.to_lower()), FileAccess.WRITE)
		f.store_string(json)
		
		populate_tree()
	else:
		show_error("Invalid difficulty name!")

func _unhandled_input(event):
	if event.is_action_pressed("show_hidden"):
		show_hidden = not show_hidden
		
		title = "Select a song to edit / display" if show_hidden else "Select a song to edit"
		
		populate_tree()

func _on_chart_deleted():
	var song = tree.get_selected().get_meta("song") as HBSong
	var difficulty = tree.get_selected().get_meta("difficulty")
	var chart_path = song.get_chart_path(difficulty)
	if FileAccess.file_exists(chart_path):
		DirAccess.remove_absolute(chart_path)
	else:
		Log.log(self, "Attempted to remove chart %s from song %s failed becuase the chart doesn't exist on disk" % [chart_path, song.id])
	song.charts.erase(difficulty)
	song.save_song()
	populate_tree()
	
