extends Panel

var song_meta: HBSong: set = set_song_meta
signal song_meta_saved

var current_downloading_id = ""

@onready var add_variant_dialog_youtube_url = get_node("AddVariantDialog/VBoxContainer/LineEdit2")
@onready var add_variant_dialog_name = get_node("AddVariantDialog/VBoxContainer/LineEdit")

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
@onready var preview_start_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/SongPreviewSpinBox")
@onready var preview_end_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/SongPreviewEndSpinBox")
@onready var voice_audio_filename_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer3/SelectVoiceAudioFileLineEdit")

@onready var difficulties_container = get_node("TabContainer/Charts/MarginContainer/HBoxContainer/VBoxContainer")

@onready var preview_image_filename_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer3/SelectPreviewImageLineEdit")
@onready var background_image_filename_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer4/SelectBackgroundImageLineEdit")

@onready var circle_image_line_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer5/SelectCircleImageLineEdit")
@onready var circle_logo_image_line_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer6/SelectCircleLogoLineEdit")

@onready var youtube_url_line_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/YoutubeURL")
@onready var use_youtube_as_video = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/UseYoutubeAsVideo")
@onready var use_youtube_as_audio = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/UseYoutubeAsAudio")

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

const VARIANT_EDITOR = preload("res://tools/editor/VariantEditor.tscn")

var show_hidden: bool = false: set = set_hidden

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
	circle_image_line_edit.text = song_meta.circle_image
	circle_logo_image_line_edit.text = song_meta.circle_logo
	voice_audio_filename_edit.text = song_meta.voice
	preview_start_edit.value = song_meta.preview_start
	preview_end_edit.value = song_meta.preview_end
	background_image_filename_edit.text = song_meta.background_image
	preview_image_filename_edit.text = song_meta.preview_image
	use_youtube_as_audio.button_pressed = song_meta.use_youtube_for_audio
	use_youtube_as_video.button_pressed = song_meta.use_youtube_for_video
	youtube_url_line_edit.text = song_meta.youtube_url
	intro_skip_checkbox.button_pressed = song_meta.allows_intro_skip
	intro_skip_min_time_spinbox.value = song_meta.intro_skip_min_time
	hide_artist_name_checkbox.button_pressed = song_meta.hide_artist_name
	start_time_spinbox.value = song_meta.start_time
	end_time_spinbox.value = song_meta.end_time
	volume_spinbox.value = song_meta.volume
	epilepsy_warning_checkbox.button_pressed = song_meta.show_epilepsy_warning
	
	for child in alternative_video_container.get_children():
		child.queue_free()
	
	for variant in song_meta.song_variants:
		var variant_editor = VARIANT_EDITOR.instantiate()
		alternative_video_container.add_child(variant_editor)
		variant_editor.set_variant(variant)
		variant_editor.song = song_meta
		variant_editor.connect("deleted", Callable(variant_editor, "queue_free"))
		variant_editor.connect("show_download_prompt", Callable(self, "_on_show_download_prompt"))
	
	chart_ed.populate(value, not hidden)
	
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
		
	
func _ready():
	YoutubeDL.connect("video_downloaded", Callable(self, "_on_video_downloaded"))
	clear_skin_button.connect("pressed", Callable(self, "_on_clear_skin_button_pressed"))
	select_skin_button.connect("pressed", Callable(skin_picker, "popup_centered"))
	skin_picker.connect("skin_selected", Callable(self, "_on_skin_selected"))
	_update_paths()

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
	song_meta.circle_image = circle_image_line_edit.text
	song_meta.circle_logo = circle_logo_image_line_edit.text
	song_meta.preview_start = preview_start_edit.value
	song_meta.preview_end = preview_end_edit.value
	song_meta.background_image = background_image_filename_edit.text
	song_meta.preview_image = preview_image_filename_edit.text
	song_meta.youtube_url = youtube_url_line_edit.text
	song_meta.use_youtube_for_audio = use_youtube_as_audio.pressed
	song_meta.use_youtube_for_video = use_youtube_as_video.pressed
	
	song_meta.allows_intro_skip = intro_skip_checkbox.pressed
	song_meta.intro_skip_min_time = intro_skip_min_time_spinbox.value
	
	song_meta.start_time = start_time_spinbox.value
	song_meta.end_time = end_time_spinbox.value
	song_meta.hide_artist_name = hide_artist_name_checkbox.pressed
	
	song_meta.volume = volume_spinbox.value
	song_meta.show_epilepsy_warning = epilepsy_warning_checkbox.pressed
	
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


func _on_AddVariantButton_pressed():
	var variant_editor = VARIANT_EDITOR.instantiate()
	alternative_video_container.add_child(variant_editor)
	variant_editor.song = song_meta
	variant_editor.connect("deleted", Callable(variant_editor, "queue_free"))
	variant_editor.connect("show_download_prompt", Callable(self, "_on_show_download_prompt"))

func _on_show_download_prompt(variant: int):
	if show_hidden:
		return
	
	save_meta()
	
	MouseTrap.cache_song_overlay.show_download_prompt(song_meta, variant)

func show_error(err: String):
	$ErrorDialog.dialog_text = err
	$ErrorDialog.popup_centered()

func _on_AddVariantDialog_confirmed():
	var url = add_variant_dialog_youtube_url.text
	if not song_meta.youtube_url:
		show_error("In order to add variants you must first add a base youtube URL")
		return
	if not YoutubeDL.validate_video_url(url):
		show_error("Invalid youtube URL")
	else:
		if YoutubeDL.get_cache_status(url, false) != YoutubeDL.CACHE_STATUS.OK:
			current_downloading_id = YoutubeDL.get_video_id(url)
			# HACK...
			var v = HBSongVariantData.new()
			v.variant_name = add_variant_dialog_name.text
			v.variant_url = url
			v.audio_only = true
			song_meta.song_variants.append(v)
			song_meta.cache_data(song_meta.song_variants.size()-1)
			$DownloadingSongPopup.popup_centered()
		else:
			user_add_variant(YoutubeDL.get_video_id(url))

func _on_video_downloaded(id, result):
	if id == current_downloading_id:
		$DownloadingSongPopup.hide()
		song_meta.song_variants.pop_back()
		if result.has("audio") and not result.audio:
			show_error("There was an error downloading the audio...")
		else:
			user_add_variant(id)

func user_add_variant(id: String):
	var variant_editor = VARIANT_EDITOR.instantiate()
	alternative_video_container.add_child(variant_editor)
	variant_editor.song = song_meta
	variant_editor.connect("deleted", Callable(variant_editor, "queue_free"))
	variant_editor.connect("show_download_prompt", Callable(self, "_on_show_download_prompt"))
	var norm = HBAudioNormalizer.new()
	norm.set_target_ogg(HBUtils.load_ogg(YoutubeDL.get_audio_path(id)))
	while not norm.work_on_normalization():
		pass
	var res = norm.get_normalization_result()
	variant_editor.variant.variant_url = "https://www.youtube.com/watch?v=%s" % [id]
	variant_editor.variant.variant_normalization = res
	variant_editor.variant.variant_name = add_variant_dialog_name.text
	variant_editor.set_variant(variant_editor.variant)

# Goofy ahh code
func set_enabled(enabled: bool):
	title_edit.editable = enabled
	romanized_title_edit.editable = enabled
	artist_edit.editable = enabled
	artist_alias_edit.editable = enabled
	vocals_edit.readonly = not enabled
	writers_edit.readonly = not enabled
	composers_edit.readonly = not enabled
	creator_edit.editable = enabled
	original_title_edit.editable = enabled
	audio_filename_edit.editable = enabled
	circle_image_line_edit.editable = enabled
	circle_logo_image_line_edit.editable = enabled
	voice_audio_filename_edit.editable = enabled
	preview_start_edit.editable = enabled
	preview_end_edit.editable = enabled
	background_image_filename_edit.editable = enabled
	preview_image_filename_edit.editable = enabled
	use_youtube_as_audio.disabled = not enabled
	use_youtube_as_video.disabled = not enabled
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
