extends ConfirmationDialog

onready var tree = get_node("MarginContainer/VBoxContainer/HBoxContainer/Tree")
onready var new_song_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/NewSongButton")
onready var add_chart_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/AddDifficultyButton")
onready var edit_data_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainerSong/EditDataButton")
onready var song_meta_editor_dialog = get_node("SongMetaEditorDialog")
onready var song_meta_editor = get_node("SongMetaEditorDialog/SongMetaEditor")
onready var create_difficulty_dialog = get_node("CreateDifficultyDialog")
onready var create_song_dialog = get_node("CreateSongDialog")
signal chart_selected(song, difficulty)

# If we should show songs in res://
var show_hidden = false

func _ready():
	connect("about_to_show", self, "_on_about_to_show")
	tree.connect("item_selected", self, "_on_item_selected")
	edit_data_button.connect("pressed", self, "_show_meta_editor")
	new_song_button.connect("pressed", create_song_dialog, "popup_centered")
	create_song_dialog.connect("confirmed", self, "_on_CreateSongDialog_confirmed")
	call_deferred("popup_centered")
	connect("confirmed", self, "_on_confirmed")
	add_chart_button.connect("pressed", create_difficulty_dialog, "popup_centered")
	create_difficulty_dialog.connect("difficulty_created", self, "_on_difficulty_created")
	MouseTrap.cache_song_overlay.connect("video_downloaded", self, "_on_video_downloaded")
	
func _on_video_downloaded(id, result, song):
	_on_confirmed()
	
func populate_tree():
	# Disable song-specific buttons
	add_chart_button.disabled = true
	edit_data_button.disabled = true
	get_ok().disabled = true
	tree.clear()
	var root = tree.create_item()
	for song in SongLoader.songs.values():
		# PPD charts cannot be edited...
		if not song is HBPPDSong:
			if not song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN or show_hidden:
				var item = tree.create_item()
				item.set_text(0, song.title)
				item.set_meta("song", song)
				for difficulty in song.charts:
					var diff_item = tree.create_item(item)
					diff_item.set_text(0, difficulty.capitalize())
					diff_item.set_meta("song", song)
					diff_item.set_meta("difficulty", difficulty)
	
func _on_item_selected():
	var item = tree.get_selected()
	if item.has_meta("difficulty"):
		get_ok().disabled = false
	else:
		get_ok().disabled = true
	add_chart_button.disabled = false
	edit_data_button.disabled = false
	
func _on_about_to_show():
	populate_tree()
	rect_size = Vector2.ZERO

func _show_meta_editor():
	song_meta_editor_dialog.rect_size = Vector2.ZERO
	song_meta_editor.song_meta = tree.get_selected().get_meta("song")
	song_meta_editor_dialog.popup_centered_minsize(Vector2(500, 650))
func _on_CreateSongDialog_confirmed():
	if $CreateSongDialog/VBoxContainer/LineEdit.text != "":
		var song_name = HBUtils.get_valid_filename($CreateSongDialog/VBoxContainer/LineEdit.text)
		if song_name != "":
			
			var song_meta = HBSong.new()
			song_meta.title = $CreateSongDialog/VBoxContainer/LineEdit.text
			song_meta.id = song_name
			song_meta.path = "user://songs/%s" % song_name
			song_meta.save_song()
			SongLoader.songs[song_meta.id] = song_meta
			populate_tree()

func show_error(error: String):
	$AcceptDialog.dialog_text = error
	$AcceptDialog.rect_size = Vector2.ZERO
	$AcceptDialog.popup_centered(Vector2(500, 100))
func _on_confirmed():
	var item = tree.get_selected()
	var song = item.get_meta("song") as HBSong
	if not song.is_cached():
		MouseTrap.cache_song_overlay.show_download_prompt(song)
		return
	if not song.has_audio():
		show_error("You must add an audio track to your song before editing, you can do this from \"Edit song data\".")
	else:
		emit_signal("chart_selected", song, item.get_meta("difficulty"))
		hide()

func _on_SongMetaEditorDialog_confirmed():
	song_meta_editor.save_meta()
	populate_tree()

func _on_difficulty_created(difficulty: String, stars):
	var song = tree.get_selected().get_meta("song") as HBSong
	var diff = HBUtils.get_valid_filename(difficulty.strip_edges())
	if diff:
		song.charts[difficulty.to_lower()] = {
			"file": difficulty.to_lower() + ".json",
			"stars": stars
		}
		song.save_song()
		populate_tree()
	else:
		show_error("Invalid difficulty name!")

func _unhandled_input(event):
	if event.is_action_pressed("free_friends"):
		show_hidden = true
		populate_tree()
