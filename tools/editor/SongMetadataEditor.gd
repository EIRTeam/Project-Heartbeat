extends Panel

var song_meta: HBSong setget set_song_meta
signal song_meta_saved

onready var title_edit = get_node("TabContainer/Metadata/VBoxContainer/SongTitle")
onready var romanized_title_edit = get_node("TabContainer/Metadata/VBoxContainer/SongRomanizedTitle")
onready var artist_edit = get_node("TabContainer/Metadata/VBoxContainer/SongArtist")
onready var artist_alias_edit = get_node("TabContainer/Metadata/VBoxContainer/SongArtistAlias")
onready var vocals_edit = get_node("TabContainer/Metadata/VBoxContainer/SongVocals")
onready var writers_edit = get_node("TabContainer/Metadata/VBoxContainer/SongWriters")
onready var creator_edit = get_node("TabContainer/Metadata/VBoxContainer/SongCreator")
onready var original_title_edit = get_node("TabContainer/Metadata/VBoxContainer/SongOriginalTitle")
onready var composers_edit = get_node("TabContainer/Metadata/VBoxContainer/SongComposers")

onready var bpm_edit = get_node("TabContainer/Technical Data/VBoxContainer/BPMSpinBox")
onready var audio_filename_edit = get_node("TabContainer/Technical Data/VBoxContainer/HBoxContainer2/SelectAudioFileLineEdit")
onready var preview_start_edit = get_node("TabContainer/Technical Data/VBoxContainer/SongPreviewSpinBox")
onready var voice_audio_filename_edit = get_node("TabContainer/Technical Data/VBoxContainer/HBoxContainer3/SelectVoiceAudioFileLineEdit")

onready var difficulties_container = get_node("TabContainer/Charts/HBoxContainer/VBoxContainer")
onready var stars_container = get_node("TabContainer/Charts/HBoxContainer/VBoxContainer2")

onready var preview_image_filename_edit = get_node("TabContainer/Graphics/VBoxContainer/HBoxContainer3/SelectPreviewImageLineEdit")
onready var background_image_filename_edit = get_node("TabContainer/Graphics/VBoxContainer/HBoxContainer4/SelectBackgroundImageLineEdit")

onready var circle_image_line_edit = get_node("TabContainer/Graphics/VBoxContainer/HBoxContainer5/SelectCircleImageLineEdit")
onready var circle_logo_image_line_edit = get_node("TabContainer/Graphics/VBoxContainer/HBoxContainer6/SelectCircleLogoLineEdit")

onready var youtube_url_line_edit = get_node("TabContainer/Technical Data/VBoxContainer/YoutubeURL")
onready var use_youtube_as_video = get_node("TabContainer/Technical Data/VBoxContainer/UseYoutubeAsVideo")
onready var use_youtube_as_audio = get_node("TabContainer/Technical Data/VBoxContainer/UseYoutubeAsAudio")
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
	background_image_filename_edit.text = song_meta.background_image
	preview_image_filename_edit.text = song_meta.preview_image
	use_youtube_as_audio.pressed = song_meta.use_youtube_for_audio
	use_youtube_as_video.pressed = song_meta.use_youtube_for_video
	youtube_url_line_edit.text = song_meta.youtube_url
	
	# Uncheck all difficulties
	for difficulty_checkbox in difficulties_container.get_children():
		difficulty_checkbox.pressed = false
	for difficulty in song_meta.charts:
		for difficulty_checkbox in difficulties_container.get_children():
			if difficulty_checkbox.text.to_lower() == difficulty.to_lower():
				difficulty_checkbox.pressed = true
				break
		for star_spinbox in stars_container.get_children():
			if star_spinbox.name.to_lower() == difficulty.to_lower():
				star_spinbox.value = song_meta.charts[difficulty].stars
	
func _ready():
	pass


func save_meta():
	song_meta.title = title_edit.text
	song_meta.romanized_title = romanized_title_edit.text
	song_meta.artist = artist_edit.text
	song_meta.artist_alias = artist_alias_edit.text
	song_meta.vocals = Array(vocals_edit.text.split("\n"))
	song_meta.composers = Array(composers_edit.text.split("\n"))
	song_meta.writers = Array(writers_edit.text.split("\n"))
	song_meta.creator = creator_edit.text
	
	song_meta.bpm = bpm_edit.value
	song_meta.audio = audio_filename_edit.text
	song_meta.preview_start = preview_start_edit.value
	song_meta.background_image = background_image_filename_edit.text
	song_meta.preview_image = preview_image_filename_edit.text
	song_meta.youtube_url = youtube_url_line_edit.text
	song_meta.use_youtube_for_audio = use_youtube_as_audio.pressed
	song_meta.use_youtube_for_video = use_youtube_as_video.pressed
	
	for difficulty_checkbox in difficulties_container.get_children():
		if difficulty_checkbox.pressed:
			var difficulty = difficulty_checkbox.text.to_lower()
			if not difficulty in song_meta.charts:
				song_meta.charts[difficulty] = {
					"file": difficulty + ".json"
				}
				
	for star_spinbox in stars_container.get_children():
		if star_spinbox.name.to_lower() in song_meta.charts:
			song_meta.charts[star_spinbox.name.to_lower()].stars = star_spinbox.value
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
