extends PanelContainer

var song_meta: HBSong: set = set_song_meta
signal song_meta_saved

var current_downloading_id = ""

@onready var add_variant_dialog: HBAddVariantDialog = get_node("%AddVariantDialog")

@onready var title_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongTitle")
@onready var romanized_title_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongRomanizedTitle")
@onready var artist_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongArtist")
@onready var artist_alias_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongArtistAlias")
@onready var vocals_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongVocals")
@onready var writers_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongWriters")
@onready var creator_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongCreator")
@onready var original_title_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongOriginalTitle")
@onready var composers_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongComposers")

@onready var audio_filename_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer2/SelectAudioFileLineEdit")
@onready var video_filename_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer4/VideoFileLineEdit")
@onready var preview_start_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/SongPreviewSpinBox")
@onready var preview_end_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/SongPreviewEndSpinBox")
@onready var voice_audio_filename_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer3/SelectVoiceAudioFileLineEdit")

@onready var difficulties_container = get_node("TabContainer/Charts/MarginContainer/HBoxContainer/VBoxContainer")

@onready var preview_image_filename_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer3/SelectPreviewImageLineEdit")
@onready var background_image_filename_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer4/SelectBackgroundImageLineEdit")

@onready var circle_image_line_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer5/SelectCircleImageLineEdit")
@onready var circle_logo_image_line_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer6/SelectCircleLogoLineEdit")

@onready var youtube_url_line_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/YoutubeURL")

@onready var intro_skip_checkbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/Label11/IntroSkipCheckbox")
@onready var intro_skip_min_time_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/IntroSkipTimeSpinbox")

@onready var start_time_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/StartTimeSpinbox")
@onready var end_time_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/EndTimeSpinbox")

@onready var volume_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/VolumeSpinbox")
@onready var chart_ed = get_node("TabContainer/Charts")
@onready var hide_artist_name_checkbox = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HideArtistName")
@onready var epilepsy_warning_checkbox = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/EpilepsyWarning")

@onready var alternative_video_container = get_node("TabContainer/Alternative Videos/MarginContainer/VBoxContainer/VBoxContainer")

@onready var skin_label: Label = get_node("%SkinLabel")
@onready var clear_skin_button: Button = get_node("%ClearSkinButton")
@onready var skin_picker: HBEditorSkinPicker = get_node("%SkinPicker")
@onready var select_skin_button: Button = get_node("%SelectSkinButton")

@onready var select_audio_button: Button = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer2/SelectAudioFileButton")
@onready var select_voice_audio_button: Button = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer3/SelectVoiceAudioFileButton")

@onready var select_preview_button: Button = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer3/SelectPreviewImageButton")
@onready var select_background_button: Button = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer4/SelectBackgroundImageButton")
@onready var select_circle_image_button: Button = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer5/SelectCircleImageButton")
@onready var select_circle_logo_button: Button = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer6/SelectCircleLogoButton")

@onready var add_variant_button: Button = get_node("TabContainer/Alternative Videos/MarginContainer/VBoxContainer/AddVariantButton")

@onready var import_media_button: Button = get_node("%ImportMediaButton")

var selected_variant_media: MediaImportDialog.MediaImportDialogResult

const VARIANT_EDITOR = preload("res://tools/editor/VariantEditor.tscn")

var show_hidden: bool = false: set = set_hidden

func _on_variant_delete_confirmed(variant_editor: Node, variant: HBSongVariantData):
	var variant_idx := song_meta.song_variants.find(variant)
	if variant_idx == -1:
		printerr("Something went wrong...")
		return
	if variant.variant_video:
		var video_path := song_meta.get_variant_video_res_path(variant_idx)
		if video_path.begins_with(song_meta.path) and FileAccess.file_exists(video_path):
			OS.move_to_trash(ProjectSettings.globalize_path(video_path))
	if variant.variant_video:
		var audio_path := song_meta.get_variant_audio_res_path(variant_idx)
		if audio_path.begins_with(song_meta.path) and FileAccess.file_exists(audio_path):
			OS.move_to_trash(ProjectSettings.globalize_path(audio_path))
	variant_editor.get_parent().remove_child(variant_editor)
	variant_editor.queue_free()
	save_meta()

func _variant_delete_button_pressed(variant_editor: Node, variant: HBSongVariantData):
	var confirm_dialog := ConfirmationDialog.new()
	add_child(confirm_dialog)
	confirm_dialog.dialog_text = "Are you sure you want to delete this variant? This will also move the variant's media files from the chart folder to trash."
	confirm_dialog.confirmed.connect(_on_variant_delete_confirmed.bind(variant_editor, variant))
	confirm_dialog.popup_centered()
	await confirm_dialog.visibility_changed
	confirm_dialog.queue_free()

func populate_variants():
	for child in alternative_video_container.get_children():
		child.queue_free()
	
	for variant_idx in range(song_meta.song_variants.size()):
		var variant_editor = VARIANT_EDITOR.instantiate()
		var variant := song_meta.song_variants[variant_idx] as HBSongVariantData
		alternative_video_container.add_child(variant_editor)
		variant_editor.initialize(song_meta, variant_idx)
		variant_editor.song = song_meta
		variant_editor.connect("deleted", _variant_delete_button_pressed.bind(variant_editor, variant))
		variant_editor.connect("show_download_prompt", Callable(self, "_on_show_download_prompt"))

func set_song_meta(value):
	song_meta = value
	
	title_edit.text = song_meta.title
	romanized_title_edit.text = song_meta.romanized_title
	artist_edit.text = song_meta.artist
	artist_alias_edit.text = song_meta.artist_alias
	vocals_edit.text = "\n".join(song_meta.vocals)
	writers_edit.text = "\n".join(song_meta.writers)
	composers_edit.text = "\n".join(song_meta.composers)
	creator_edit.text = song_meta.creator
	original_title_edit.text = song_meta.original_title
	audio_filename_edit.text = song_meta.audio
	video_filename_edit.text = song_meta.video
	circle_image_line_edit.text = song_meta.circle_image
	circle_logo_image_line_edit.text = song_meta.circle_logo
	voice_audio_filename_edit.text = song_meta.voice
	preview_start_edit.value = song_meta.preview_start
	preview_end_edit.value = song_meta.preview_end
	background_image_filename_edit.text = song_meta.background_image
	preview_image_filename_edit.text = song_meta.preview_image
	youtube_url_line_edit.text = song_meta.youtube_preview_url
	intro_skip_checkbox.button_pressed = song_meta.allows_intro_skip
	intro_skip_min_time_spinbox.value = song_meta.intro_skip_min_time
	hide_artist_name_checkbox.button_pressed = song_meta.hide_artist_name
	start_time_spinbox.value = song_meta.start_time
	end_time_spinbox.value = song_meta.end_time
	volume_spinbox.value = song_meta.volume
	epilepsy_warning_checkbox.button_pressed = song_meta.show_epilepsy_warning
	
	populate_variants()
	
	chart_ed.populate(value, not show_hidden)
	
	skin_picker.populate_list()
	skin_picker.selected_value = song_meta.skin_ugc_id
	
	if song_meta.skin_ugc_id == 0:
		skin_label.text = "None"
		clear_skin_button.disabled = true
	else:
		clear_skin_button.disabled = false
		skin_label.text = "Workshop Skin %d (not downloaded)" % [song_meta.skin_ugc_id]
		for skin_name in ResourcePackLoader.resource_packs:
			var skin: HBResourcePack = ResourcePackLoader.resource_packs[skin_name]
			if skin.is_skin():
				if skin.ugc_id == song_meta.skin_ugc_id:
					skin_label.text = skin.pack_name
					break
		
	
func _on_add_variant_button_pressed():
	add_variant_dialog.popup_centered()
	var result: HBAddVariantDialog.AddVariantDialogResult = await add_variant_dialog.dialog_finished
	
	if result.error != HBAddVariantDialog.AddVariantDialogError.OK:
		return
		
	var import_ui := MediaImporterUI.new()
	var variant_idx := song_meta.song_variants.size() as int
	var variant := HBSongVariantData.new()
	variant.variant_name = result.variant_name
	variant.audio_only = !result.media_info.has_video_stream
	song_meta.song_variants.push_back(variant)
	import_ui.do_import(song_meta, result.media_info, variant_idx)
	var import_result: MediaImporterUI.MediaImporterUIResult = await import_ui.import_finished
	
	if import_result.error != MediaImporterUI.MediaImporterUIError.OK:
		song_meta.song_variants.remove_at(variant_idx)
		return
		
	populate_variants()
	import_ui.queue_free()
	save_meta()
	
func _ready():
	YoutubeDL.connect("video_downloaded", Callable(self, "_on_video_downloaded"))
	clear_skin_button.connect("pressed", Callable(self, "_on_clear_skin_button_pressed"))
	select_skin_button.connect("pressed", Callable(skin_picker, "popup_centered"))
	skin_picker.connect("skin_selected", Callable(self, "_on_skin_selected"))
	add_variant_button.pressed.connect(_on_add_variant_button_pressed)
	_update_paths()
	import_media_button.pressed.connect(_on_import_media_button_pressed)

func _on_import_media_button_pressed():
	var media_import_dialog := preload("res://tools/editor/media_import_dialog/MediaImportDialog.tscn").instantiate() as MediaImportDialog
	add_child(media_import_dialog)
	media_import_dialog.popup_centered()
	var result: MediaImportDialog.MediaImportDialogResult = await media_import_dialog.media_selected
	if not result.canceled and (result.has_video_stream or result.has_audio_stream):
		var original_video_path := song_meta.get_variant_video_res_path()
		var original_audio_path := song_meta.get_variant_audio_res_path()
			
		var temp := DirAccess.create_temp("media_tmp")
		var original_video_temp_path := ""
		var original_audio_temp_path := ""
		if FileAccess.file_exists(original_video_path):
			original_video_temp_path = temp.get_current_dir().path_join(original_video_path)
			DirAccess.copy_absolute(original_video_path, original_video_temp_path)
			DirAccess.remove_absolute(original_video_path)
		if FileAccess.file_exists(original_audio_path):
			original_audio_temp_path = temp.get_current_dir().path_join(original_audio_path)
			DirAccess.copy_absolute(original_audio_path, original_audio_temp_path)
			DirAccess.remove_absolute(original_audio_path)
			
		var importer_ui := MediaImporterUI.new()
		add_child(importer_ui)
		importer_ui.do_import(song_meta, result)
		var import_result: MediaImporterUI.MediaImporterUIResult = await importer_ui.import_finished
		importer_ui.queue_free()
		if import_result.error != MediaImporterUI.MediaImporterUIError.OK:
			if not original_video_temp_path.is_empty():
				DirAccess.copy_absolute(original_video_temp_path, original_video_path)
			if not original_audio_temp_path.is_empty():
				DirAccess.copy_absolute(original_audio_temp_path, original_audio_path)
		video_filename_edit.text = song_meta.video
		audio_filename_edit.text = song_meta.audio
	media_import_dialog.queue_free()

func _on_skin_selected(skin_ugc_id: int):
	if skin_ugc_id == 0:
		skin_label.text = "None"
		clear_skin_button.disabled = true
	else:
		skin_label.text = "Workshop Skin %d (not downloaded)" % [skin_ugc_id]
		for skin_name in ResourcePackLoader.resource_packs:
			var skin: HBResourcePack = ResourcePackLoader.resource_packs[skin_name]
			if skin.is_skin():
				if skin.ugc_id == skin_ugc_id:
					skin_label.text = skin.pack_name
					break
		clear_skin_button.disabled = false
		
func _on_clear_skin_button_pressed():
	skin_label.text = "None"
	skin_picker.selected_value = 0
	clear_skin_button.disabled = true

func save_meta():
	if show_hidden:
		return
	
	song_meta.title = title_edit.text
	song_meta.original_title = original_title_edit.text
	song_meta.romanized_title = romanized_title_edit.text
	song_meta.artist = artist_edit.text
	song_meta.artist_alias = artist_alias_edit.text
	song_meta.vocals = Array(vocals_edit.text.split("\n"))
	song_meta.composers = Array(composers_edit.text.split("\n"))
	song_meta.writers = Array(writers_edit.text.split("\n"))
	song_meta.creator = creator_edit.text
	
	song_meta.audio = audio_filename_edit.text
	song_meta.video = video_filename_edit.text
	song_meta.circle_image = circle_image_line_edit.text
	song_meta.circle_logo = circle_logo_image_line_edit.text
	song_meta.preview_start = preview_start_edit.value
	song_meta.preview_end = preview_end_edit.value
	song_meta.background_image = background_image_filename_edit.text
	song_meta.preview_image = preview_image_filename_edit.text
	if song_meta.youtube_preview_url != youtube_url_line_edit.text:
		song_meta.youtube_preview_url = youtube_url_line_edit.text
	
	song_meta.allows_intro_skip = intro_skip_checkbox.button_pressed
	song_meta.intro_skip_min_time = intro_skip_min_time_spinbox.value
	
	song_meta.start_time = start_time_spinbox.value
	song_meta.end_time = end_time_spinbox.value
	song_meta.hide_artist_name = hide_artist_name_checkbox.button_pressed
	
	song_meta.volume = volume_spinbox.value
	song_meta.show_epilepsy_warning = epilepsy_warning_checkbox.button_pressed
	
	song_meta.skin_ugc_id = skin_picker.selected_value
	
	chart_ed.apply_to(song_meta)
	
	# sanitize
	
	song_meta.title = song_meta.get_sanitized_field("title")
	song_meta.romanized_title = song_meta.get_sanitized_field("romanized_title")
	
	var variants = []
	
	for variant_editor in alternative_video_container.get_children():
		variant_editor.save_variant()
		variants.append(variant_editor.variant)
		
	song_meta.song_variants = variants
	for variant in song_meta.song_variants:
		SongLoader.add_video_ownership(song_meta, variant.variant_url)
	
	song_meta.save_song()
	
	emit_signal("song_meta_saved")


func _on_AudioFileDialog_file_selected(path: String):
	if show_hidden:
		return
	
	var audio_path := song_meta.get_song_audio_res_path() as String
	
	DirAccess.copy_absolute(path, audio_path)
	song_meta.audio = audio_path.get_file()
	audio_filename_edit.text = song_meta.audio
	save_meta()
	
	UserSettings.user_settings.last_audio_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	_update_paths()


func _on_BackgroundFileDialog_file_selected(path):
	if show_hidden:
		return
	
	var extension = path.get_extension()
	song_meta.background_image = "background." + extension
	
	var image_path := song_meta.get_song_background_image_res_path() as String
	
	DirAccess.copy_absolute(path, image_path)
	background_image_filename_edit.text = song_meta.background_image
	save_meta()
	
	UserSettings.user_settings.last_graphics_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	_update_paths()


func _on_PreviewFileDialog_file_selected(path):
	if show_hidden:
		return
	
	var extension = path.get_extension()
	song_meta.preview_image = "preview." + extension
	
	var image_path := song_meta.get_song_preview_res_path() as String
	
	DirAccess.copy_absolute(path, image_path)
	preview_image_filename_edit.text = song_meta.preview_image
	save_meta()
	
	UserSettings.user_settings.last_graphics_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	_update_paths()


func _on_VoiceAudioFileDialog_file_selected(path):
	if show_hidden:
		return
	
	var audio_path := song_meta.get_song_voice_res_path() as String
	
	DirAccess.copy_absolute(path, audio_path)
	song_meta.voice = audio_path.get_file()
	voice_audio_filename_edit.text = song_meta.voice
	save_meta()
	
	UserSettings.user_settings.last_audio_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	_update_paths()


func _on_CircleFileDialog_file_selected(path):
	if show_hidden:
		return
	
	var extension = path.get_extension()
	song_meta.circle_image = "circle." + extension
	
	var image_path := song_meta.get_song_circle_image_res_path() as String
	
	DirAccess.copy_absolute(path, image_path)
	circle_image_line_edit.text = song_meta.circle_image
	save_meta()
	
	UserSettings.user_settings.last_graphics_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	_update_paths()


func _on_CircleLogoFileDialog_file_selected(path):
	if show_hidden:
		return
	
	var extension = path.get_extension()
	song_meta.circle_logo = "circle_logo." + extension
	
	var image_path := song_meta.get_song_circle_logo_image_res_path() as String
	
	DirAccess.copy_absolute(path, image_path)
	circle_logo_image_line_edit.text = song_meta.circle_logo
	save_meta()
	
	UserSettings.user_settings.last_graphics_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	_update_paths()


func _update_paths():
	$PreviewFileDialog.set_current_dir(UserSettings.user_settings.last_graphics_dir)
	$BackgroundFileDialog.set_current_dir(UserSettings.user_settings.last_graphics_dir)
	$CircleFileDialog.set_current_dir(UserSettings.user_settings.last_graphics_dir)
	$CircleLogoFileDialog.set_current_dir(UserSettings.user_settings.last_graphics_dir)
	$AudioFileDialog.set_current_dir(UserSettings.user_settings.last_audio_dir)
	$VoiceAudioFileDialog.set_current_dir(UserSettings.user_settings.last_audio_dir)

func _on_show_download_prompt(variant: int):
	if show_hidden:
		return
	
	save_meta()
	
	MouseTrap.cache_song_overlay.show_download_prompt(song_meta, variant)

func show_error(err: String):
	$ErrorDialog.dialog_text = err
	$ErrorDialog.popup_centered()

# Goofy ahh code
func set_enabled(enabled: bool):
	title_edit.editable = enabled
	romanized_title_edit.editable = enabled
	artist_edit.editable = enabled
	artist_alias_edit.editable = enabled
	vocals_edit.editable = enabled
	writers_edit.editable = enabled
	composers_edit.editable = enabled
	creator_edit.editable = enabled
	original_title_edit.editable = enabled
	audio_filename_edit.editable = false
	video_filename_edit.editable = false
	circle_image_line_edit.editable = enabled
	circle_logo_image_line_edit.editable = enabled
	voice_audio_filename_edit.editable = false
	preview_start_edit.editable = enabled
	preview_end_edit.editable = enabled
	background_image_filename_edit.editable = enabled
	preview_image_filename_edit.editable = enabled
	youtube_url_line_edit.editable = enabled
	intro_skip_checkbox.disabled = not enabled
	intro_skip_min_time_spinbox.editable = enabled
	hide_artist_name_checkbox.disabled = not enabled
	start_time_spinbox.editable = enabled
	end_time_spinbox.editable = enabled
	volume_spinbox.editable = enabled
	epilepsy_warning_checkbox.disabled = not enabled
	
	select_skin_button.disabled = not enabled
	clear_skin_button.disabled = not enabled
	
	select_audio_button.disabled = not enabled
	select_voice_audio_button.disabled = not enabled
	
	select_preview_button.disabled = not enabled
	select_background_button.disabled = not enabled
	select_circle_image_button.disabled = not enabled
	select_circle_logo_button.disabled = not enabled
	
	add_variant_button.disabled = not enabled

func set_hidden(p_show_hidden: bool):
	show_hidden = p_show_hidden
	
	set_enabled(not show_hidden)
