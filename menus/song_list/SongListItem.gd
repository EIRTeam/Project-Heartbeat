extends BaseButton

var song : HBSong setget set_song

func set_song(value: HBSong):
	song = value
	$VBoxContainer/TitleLabel.text = song.title
	if song.artist_alias != "":
		$VBoxContainer/AuthorLabel.text = song.artist_alias
	else:
		$VBoxContainer/AuthorLabel.text = song.artist



func _on_pressed():
	get_tree().change_scene_to(preload("res://rythm_game/rhythm_game.tscn"))
