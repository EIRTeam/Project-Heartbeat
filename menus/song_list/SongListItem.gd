extends VBoxContainer

var song : HBSong setget set_song

func set_song(value: HBSong):
	song = value
	$TitleLabel.text = song.data.title
	if song.data.has("artist_alias"):
		$AuthorLabel.text = song.data.artist_alias
	else:
		$AuthorLabel.text = song.data.artist
