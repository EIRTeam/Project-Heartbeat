extends Control


func select_song(song: HBSong):
	var bpm = "UNK"
	bpm = song.bpm
	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/BPMLabel.text = "%s BPM" % bpm

	var song_meta = song.get_meta_string()

	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/SongMetaLabel.text = PoolStringArray(song_meta).join('\n')
	$SongListPreview/VBoxContainer/Control/Panel3/TitleLabel.text = song.title
