extends Panel

var song_meta: HBSong setget set_song_meta
var package_name: String
var package_meta: HBPackageMeta
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
	emit_signal("song_meta_saved")


func _on_FileDialog_file_selected(path: String):
	var dir = Directory.new()
	var extension = path.get_extension()
	var song_path := HBPackageMeta.get_dev_package_song_path(package_name, song_meta.id) as String
	var audio_file_name = song_meta.id + ".ogg"
	audio_filename_edit.text = audio_file_name
	
	dir.copy(path, song_path.plus_file(audio_file_name))
	_on_SaveButton_pressed()
