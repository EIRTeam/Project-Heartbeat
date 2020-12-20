extends HBTask

class_name HBFilterSongsTask

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

signal songs_filtered(song_items, songs)

var out_mutex := Mutex.new()
var songs: Array
var filter_by: String
var filtered_songs: Array
var song_items: Array = []
var sort_by_prop: String
func _init(_songs: Array, _filter_by: String, _sort_by: String).():
	songs = _songs
	filter_by = _filter_by
	sort_by_prop = _sort_by
func sort_and_filter_songs():
	songs.sort_custom(self, "sort_array")
	prints("Filtering by", filter_by)

	if filter_by != "all":
		var filtered_songs = []
		for song in songs:
			var should_add_song = false
			match filter_by:
				"ppd":
					should_add_song = song is HBPPDSong
				"official":
					should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN
				"community":
					should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER and not song is HBPPDSong
			if should_add_song:
				filtered_songs.append(song)
		return filtered_songs
	else:
		return songs
		
func sort_array(a: HBSong, b: HBSong):
	var prop = sort_by_prop
	var a_prop = a.get(prop)
	var b_prop = b.get(prop)
	if prop == "title":
		a_prop = a.get_visible_title()
		b_prop = b.get_visible_title()
	elif prop == "artist":
		a_prop = a.get_artist_sort_text()
		b_prop = b.get_artist_sort_text()
	elif prop == "score":
		a_prop = b.get_max_score()
		b_prop = a.get_max_score()
	if a_prop is String:
		a_prop = a_prop.to_lower()
	if b_prop is String:
		b_prop = b_prop.to_lower()
	return a_prop < b_prop
		
func _create_song_item(song: HBSong):
	var item = SongListItem.instance()
	item.use_parent_material = true
	item.set_song(song)
	item.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)
	return item
func _task_process() -> bool:
	out_mutex.lock()
	filtered_songs = sort_and_filter_songs()
	out_mutex.unlock()
	for song in filtered_songs:
		var item = _create_song_item(song)
		out_mutex.lock()
		song_items.append(item)
		out_mutex.unlock()
	return true
	
func get_task_output_data():
	return {"song_items": song_items, "filtered_songs": filtered_songs}
	
func _on_task_finished_processing(data):
	VisualServer.sync()
	emit_signal("songs_filtered", data.song_items, data.filtered_songs)
