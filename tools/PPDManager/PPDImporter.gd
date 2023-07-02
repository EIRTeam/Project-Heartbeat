extends Control

signal error(error)

@onready var wait_dialog = get_node("WaitDialog")
@onready var wait_dialog_label = get_node("WaitDialog/Label")
@onready var window_dialog = get_node("Window")
@onready var PPD_folders_checkbox = get_node("Window/MarginContainer/VBoxContainer/PPDFoldersCheckbox")
@onready var PPD_ogg_checkbox = get_node("Window/MarginContainer/VBoxContainer/PPDOGGCheckbox")
@onready var PPD_folder_name_line_edit = get_node("Window/MarginContainer/VBoxContainer/HBoxContainer/LineEdit")
@onready var PPD_hide_songs_checkbox = get_node("Window/MarginContainer/VBoxContainer/HidePPDEXtSongsCheckbox")
@onready var close_button = get_node("Window/MarginContainer/VBoxContainer/CloseButton")
@onready var current_install_label = get_node("Window/MarginContainer/VBoxContainer/Label2")
@onready var remove_installation_button = get_node("Window/MarginContainer/VBoxContainer/RemoveInstallationButton")
@onready var PPD_importer_file_dialog = get_node("PPDImporterFileDialog")

func _on_import_pressed():
	pass

func _ready():
	close_button.connect("pressed", Callable(window_dialog, "hide"))
	PPD_importer_file_dialog.set_current_dir(UserSettings.user_settings.ppd_songs_directory)

func show_error(err):
	emit_signal("error", err)
	
func show_wait(wait_msg: String):
	wait_dialog.popup_centered()
	wait_dialog_label.text = wait_msg
	
func create_folder_path(path: String) -> HBFolder:
	var curr_folder := UserSettings.user_settings.root_folder as HBFolder
	var path_steps := path.split("/")
	for step in path_steps:
		if not curr_folder.has_subfolder(step):
			var f := HBFolder.new()
			f.folder_name = step
			curr_folder.subfolders.append(f)
		curr_folder = curr_folder.get_subfolder(step)
	return curr_folder
			
func _on_PPDImporterFileDialog_dir_selected(dir: String):
	if PPD_folders_checkbox.pressed and not PPD_folder_name_line_edit.text.strip_edges():
		show_error("PPD Folder needs a name")
	var predir = UserSettings.user_settings.ppd_songs_directory
	UserSettings.user_settings.ppd_songs_directory = dir
	UserSettings.user_settings.hide_ppd_ex_songs = PPD_hide_songs_checkbox.pressed
	var sl = SongLoaderPPDEXT.new()
	var err = sl._init_loader()
	if err != OK:
		show_error("Error importing songs, does the folder exist?")
	
	if PPD_folders_checkbox.pressed or PPD_ogg_checkbox.pressed:
		show_wait("Finding your songs...")
		await get_tree().process_frame
		var songs := sl.load_songs() as Array
		if PPD_ogg_checkbox.pressed:
			for i in range(songs.size()):
				var song := songs[i] as HBPPDSongEXT
				# this means the song has an mp4 we need to extract audio from
				if song.has_audio() and not song.is_cached():
					show_wait("Converting audio for %s (%d/%d)" % [song.title, i+1, songs.size()])
					await get_tree().process_frame
					var _stream = song.get_audio_stream()
					if not _stream:
						UserSettings.user_settings.ppd_songs_directory = predir
						show_error("There was a problem importing the song %s, call a programmer." % [song.title])
						return
		if PPD_folders_checkbox.pressed:
			var root_folder := UserSettings.user_settings.root_folder as HBFolder
			if root_folder.has_subfolder(PPD_folder_name_line_edit.text):
				var sf = root_folder.get_subfolder(PPD_folder_name_line_edit.text)
				root_folder.subfolders.erase(sf)
			for song in songs:
				var song_path = PPD_folder_name_line_edit.text
				if "/" in song.id:
					var p = song.id.replace("PPDEXT+", "").rsplit("/", true, 1)[0]
					if p:
						song_path += "/" + p
				var folder := create_folder_path(song_path)
				folder.songs.append(song.id)
		wait_dialog.hide()
	$RestartAcceptDialog.popup_centered()
	UserSettings.save_user_settings()


func show_panel():
	$Window.popup_centered()
	current_install_label.visible = false
	remove_installation_button.disabled = true
	if UserSettings.user_settings.ppd_songs_directory:
		remove_installation_button.disabled = false
		current_install_label.visible = true
		current_install_label.text = "Current installation path: %s" % [UserSettings.user_settings.ppd_songs_directory]


func _on_RestartAcceptDialog_confirmed():
	get_tree().quit(0)


func _on_RemoveInstallationConfirmationDialog_confirmed():
	UserSettings.user_settings.ppd_songs_directory = ""
	UserSettings.user_settings.hide_ppd_ex_songs = false
	UserSettings.save_user_settings()
	$RestartAcceptDialog.popup_centered()
