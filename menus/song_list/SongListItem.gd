extends VBoxContainer

var song : HBSong setget set_song

func set_song(value: HBSong):
	song = value
	$TitleLabel.text = song.title
	if song.artist_alias != "":
		$AuthorLabel.text = song.artist_alias
	else:
		$AuthorLabel.text = song.artist
