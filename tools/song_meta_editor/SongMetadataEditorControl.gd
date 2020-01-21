extends Panel

var song_meta: HBSong setget set_song_meta
signal song_meta_saved

onready var title_edit = get_node("TabContainer/Metadata/VBoxContainer/SongTitle")
onready var artist_edit = get_node("TabContainer/Metadata/VBoxContainer/SongArtist")
onready var artist_alias_edit = get_node("TabContainer/Metadata/VBoxContainer/SongArtistAlias")
onready var producers_edit = get_node("TabContainer/Metadata/VBoxContainer/SongProducers")
onready var writers_edit = get_node("TabContainer/Metadata/VBoxContainer/SongWriters")
onready var creator_edit = get_node("TabContainer/Metadata/VBoxContainer/SongCreator")

onready var bpm_edit = get_node("TabContainer/Technical Data/VBoxContainer/BPMSpinBox")
onready var audio_filename_edit = get_node("TabContainer/Technical Data/VBoxContainer/HBoxContainer2/SelectAudioFileLineEdit")
onready var preview_start_edit = get_node("TabContainer/Technical Data/VBoxContainer/SongPreviewSpinBox")
onready var voice_audio_filename_edit = get_node("TabContainer/Technical Data/VBoxContainer/HBoxContainer3/SelectVoiceAudioFileLineEdit")

onready var difficulties_container = get_node("TabContainer/Difficulties/HBoxContainer/VBoxContainer")
onready var stars_container = get_node("TabContainer/Difficulties/HBoxContainer/VBoxContainer2")

onready var preview_image_filename_edit = get_node("TabContainer/Graphics/VBoxContainer/HBoxContainer3/SelectPreviewImageLineEdit")
onready var background_image_filename_edit = get_node("TabContainer/Graphics/VBoxContainer/HBoxContainer4/SelectBackgroundImageLineEdit")
func set_song_meta(value):
	song_meta = value
	
	title_edit.text = song_meta.title
	artist_edit.text = song_meta.artist
	artist_alias_edit.text = song_meta.artist_alias
	producers_edit.text = PoolStringArray(song_meta.producers).join("\n")
	writers_edit.text = PoolStringArray(song_meta.writers).join("\n")
	creator_edit.text = song_meta.creator

	bpm_edit.value = song_meta.bpm
	audio_filename_edit.text = song_meta.audio
	preview_start_edit.value = song_meta.preview_start
	background_image_filename_edit.text = song_meta.background_image
	preview_image_filename_edit.text = song_meta.preview_image
	
	# Uncheck all difficulties
	for difficulty_checkbox in difficulties_container.get_children():
		difficulty_checkbox.pressed = false
	for difficulty in song_meta.charts:
		for difficulty_checkbox in difficulties_container.get_children():
			print("comparing ", difficulty_checkbox.text.to_lower(), " with ", difficulty.to_lower())
			if difficulty_checkbox.text.to_lower() == difficulty.to_lower():
				difficulty_checkbox.pressed = true
				break
		for star_spinbox in stars_container.get_children():
			if star_spinbox.name.to_lower() == difficulty.to_lower():
				star_spinbox.value = song_meta.charts[difficulty].stars
	
func _ready():
	pass


func _on_SaveButton_pressed():
	song_meta.title = title_edit.text
	song_meta.artist = artist_edit.text
	song_meta.artist_alias = artist_alias_edit.text
	song_meta.producers = Array(producers_edit.text.split("\n"))
	song_meta.writers = Array(writers_edit.text.split("\n"))
	song_meta.creator = creator_edit.text
	
	song_meta.bpm = bpm_edit.value
	song_meta.audio = audio_filename_edit.text
	song_meta.preview_start = preview_start_edit.value
	song_meta.background_image = background_image_filename_edit.text
	song_meta.preview_image = preview_image_filename_edit.text
	
	
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
	var extension = path.get_extension()
	var audio_path := song_meta.get_song_audio_res_path() as String
	
	dir.copy(path, audio_path)
	song_meta.audio = audio_path.get_file()
	audio_filename_edit.text = song_meta.audio
	_on_SaveButton_pressed()


func _on_BackgroundFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	song_meta.background_image = "background." + extension
	
	var image_path := song_meta.get_song_background_image_res_path() as String
	
	dir.copy(path, image_path)
	background_image_filename_edit.text = song_meta.background_image
	_on_SaveButton_pressed()


func _on_PreviewFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	song_meta.preview_image = "preview." + extension
	
	var image_path := song_meta.get_song_preview_res_path() as String
	
	dir.copy(path, image_path)
	preview_image_filename_edit.text = song_meta.preview_image
	_on_SaveButton_pressed()


func _on_VoiceAudioFileDialog_file_selected(path):
	var dir = Directory.new()
	var extension = path.get_extension()
	var audio_path := song_meta.get_song_voice_res_path() as String
	
	dir.copy(path, audio_path)
	song_meta.voice = audio_path.get_file()
	voice_audio_filename_edit.text = song_meta.voice
	_on_SaveButton_pressed()
