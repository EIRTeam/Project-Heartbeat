extends BaseButton

var song : HBSong setget set_song

var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")
func set_song(value: HBSong):
	song = value
	$VBoxContainer/TitleLabel.text = song.title
	if song.artist_alias != "":
		$VBoxContainer/AuthorLabel.text = song.artist_alias
	else:
		$VBoxContainer/AuthorLabel.text = song.artist

func hover():
	add_stylebox_override("normal", hover_style)

func stop_hover():
	add_stylebox_override("normal", normal_style)

func _on_pressed():
	var new_scene = preload("res://rythm_game/rhythm_game.tscn")
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.set_song(song)
