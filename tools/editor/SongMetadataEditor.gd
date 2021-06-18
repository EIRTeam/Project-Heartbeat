extends Panel

var song_meta: HBSong setget set_song_meta
signal song_meta_saved

onready var title_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongTitle")
onready var romanized_title_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongRomanizedTitle")
onready var artist_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongArtist")
onready var artist_alias_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongArtistAlias")
onready var vocals_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongVocals")
onready var writers_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongWriters")
onready var creator_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongCreator")
onready var original_title_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongOriginalTitle")
onready var composers_edit = get_node("TabContainer/Metadata/MarginContainer/VBoxContainer/SongComposers")

onready var bpm_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/BPMSpinBox")
onready var audio_filename_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer2/SelectAudioFileLineEdit")
onready var preview_start_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/SongPreviewSpinBox")
onready var preview_end_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/SongPreviewEndSpinBox")
onready var voice_audio_filename_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/HBoxContainer3/SelectVoiceAudioFileLineEdit")

onready var difficulties_container = get_node("TabContainer/Charts/MarginContainer/HBoxContainer/VBoxContainer")

onready var preview_image_filename_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer3/SelectPreviewImageLineEdit")
onready var background_image_filename_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer4/SelectBackgroundImageLineEdit")

onready var circle_image_line_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer5/SelectCircleImageLineEdit")
onready var circle_logo_image_line_edit = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HBoxContainer6/SelectCircleLogoLineEdit")

onready var youtube_url_line_edit = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/YoutubeURL")
onready var use_youtube_as_video = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/UseYoutubeAsVideo")
onready var use_youtube_as_audio = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/UseYoutubeAsAudio")

onready var intro_skip_checkbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/Label11/IntroSkipCheckbox")
onready var intro_skip_min_time_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/IntroSkipTimeSpinbox")

onready var start_time_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/StartTimeSpinbox")
onready var end_time_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/EndTimeSpinbox")

onready var volume_spinbox = get_node("TabContainer/Technical Data/MarginContainer/VBoxContainer/VolumeSpinbox")
onready var chart_ed = get_node("TabContainer/Charts")
onready var hide_artist_name_checkbox = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/HideArtistName")
onready var epilepsy_warning_checkbox = get_node("TabContainer/Graphics/MarginContainer/VBoxContainer/EpilepsyWarning")

func set_song_meta(value):
	song_meta = value
	
	title_edit.text = song_meta.title
	romanized_title_edit.text = song_meta.romanized_title
	artist_edit.text = song_meta.artist
	artist_alias_edit.text = song_meta.artist_alias
	vocals_edit.text = PoolStringArray(song_meta.vocals).join("\n")
	writers_edit.text = PoolStringArray(song_meta.writers).join("\n")
	composers_edit.text = PoolStringArray(song_meta.composers).join("\n")
	creator_edit.text = song_meta.creator
	original_title_edit.text = song_meta.original_title
	bpm_edit.value = song_meta.bpm
	audio_filename_edit.text = song_meta.audio
	circle_image_line_edit.text = song_meta.circle_image
	circle_logo_image_line_edit.text = song_meta.circle_logo
	voice_audio_filename_edit.text = song_meta.voice
	preview_start_edit.value = song_meta.preview_start
	preview_end_edit.value = song_meta.preview_end
	background_image_filename_edit.text = song_meta.background_image
	preview_image_filename_edit.text = song_meta.preview_image
	use_youtube_as_audio.pressed = song_meta.use_youtube_for_audio
	use_youtube_as_video.pressed = song_meta.use_youtube_for_video
	youtube_url_line_edit.text = song_meta.youtube_url
	intro_skip_checkbox.pressed = song_meta.allows_intro_skip
	intro_skip_min_time_spinbox.value = song_meta.intro_skip_min_time
	hide_artist_name_checkbox.pressed = song_meta.hide_artist_name
	start_time_spinbox.value = song_meta.start_time
	end_time_spinbox.value = song_meta.end_time
	volume_spinbox.value = song_meta.volume
	epilepsy_warning_checkbox.pressed = song_meta.show_epilepsy_warning
	
	chart_ed.populate(value)
	
func _ready():
	pass


func save_meta():
	song_meta.title = title_edit.text
	song_meta.original_title = original_title_edit.text
	song_meta.romanized_title = romanized_title_edit.text
	song_meta.artist = artist_edit.text
	song_meta.artist_alias = artist_alias_edit.text
	song_meta.vocals = Array(vocals_edit.text.split("\n"))
	song_meta.composers = Array(composers_edit.text.split("\n"))
	song_meta.writers = Array(writers_edit.text.split("\n"))
	song_meta.creator = creator_edit.text
	
	song_meta.bpm = bpm_edit.value
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
	chart_ed.apply_to(song_meta)
	
	# sanitize
	
	song_meta.title = song_meta.get_sanitized_field("title")
	song_meta.romanized_title = song_meta.get_sanitized_field("romanized_title")
	
	song_meta.save_song()
	
	emit_signal("song_meta_saved")


func _on_AudioFileDialog_file_selected(path: String):
	var dir = Directory.new()
	var audio_path := song_meta.get_song_audio_res_path() as String
	
	dir.copy(path, audio_path)
	song_meta.audio = audio_path.get_file()
	audio_filename_edit.text = song_meta.audio
	save_meta()


func _on_BackgroundFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	song_meta.background_image = "background." + extension
	
	var image_path := song_meta.get_song_background_image_res_path() as String
	
	dir.copy(path, image_path)
	background_image_filename_edit.text = song_meta.background_image
	save_meta()


func _on_PreviewFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	song_meta.preview_image = "preview." + extension
	
	var image_path := song_meta.get_song_preview_res_path() as String
	
	dir.copy(path, image_path)
	preview_image_filename_edit.text = song_meta.preview_image
	save_meta()


func _on_VoiceAudioFileDialog_file_selected(path):
	var dir = Directory.new()
	var audio_path := song_meta.get_song_voice_res_path() as String
	
	dir.copy(path, audio_path)
	song_meta.voice = audio_path.get_file()
	voice_audio_filename_edit.text = song_meta.voice
	save_meta()


func _on_CircleFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	song_meta.circle_image = "circle." + extension
	
	var image_path := song_meta.get_song_circle_image_res_path() as String
	
	dir.copy(path, image_path)
	circle_image_line_edit.text = song_meta.circle_image
	save_meta()


func _on_CircleLogoFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	song_meta.circle_logo = "circle_logo." + extension
	
	var image_path := song_meta.get_song_circle_logo_image_res_path() as String
	
	dir.copy(path, image_path)
	circle_logo_image_line_edit.text = song_meta.circle_logo
	save_meta()
