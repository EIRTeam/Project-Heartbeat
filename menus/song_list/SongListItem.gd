extends VBoxContainer

var song : Dictionary setget set_song

func set_song(value: Dictionary):
	song = value
	$TitleLabel.text = song.title
	if song.has("artist_alias"):
		$AuthorLabel.text = song.artist_alias
	else:
		$AuthorLabel.text = song.artist
