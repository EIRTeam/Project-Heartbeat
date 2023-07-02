extends HBTask

class_name HBFilterSongsTask

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

signal songs_filtered(songs, song_id_to_select, difficulty_to_select)

var out_mutex := Mutex.new()
var songs: Array
var filter_by: String
var filtered_songs: Array
var sort_by_prop: String
var song_id_to_select
var difficulty_to_select
var search_term: String
func _init(_songs: Array, _filter_by: String, _sort_by: String, _song_id_to_select=null, _difficulty_to_select=null, _search_term := ""):
	super()
	songs = _songs
	filter_by = _filter_by
	sort_by_prop = _sort_by
	song_id_to_select = _song_id_to_select
	difficulty_to_select = _difficulty_to_select
	search_term = _search_term.to_lower()
func sort_and_filter_songs():
	var _filtered_songs = []
	var editor_songs_path = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs")
	for song in songs:
		var should_add_song = false
		match filter_by:
			"ppd":
				should_add_song = song is HBPPDSong and not (UserSettings.user_settings.hide_ppd_ex_songs and song is HBPPDSongEXT)
			"official":
				should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN
			"local":
				should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER \
									and not song is HBPPDSong and not song.comes_from_ugc() \
									and not song.path.begins_with(editor_songs_path) \
									and not song is SongLoaderDSC.HBSongDSC
			"editor":
				should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER \
									and not song is HBPPDSong and not song.comes_from_ugc() \
									and song.path.begins_with(editor_songs_path) \
									and not song is SongLoaderDSC.HBSongDSC
			"mmplus":
				should_add_song = song is SongLoaderDSC.HBSongMMPLUS and song.is_built_in
			"mmplus_mod":
				should_add_song = song is SongLoaderDSC.HBSongMMPLUS and song.is_mod_song and not song.is_built_in
			"dsc":
				should_add_song = song is SongLoaderDSC.HBSongDSC and not song is SongLoaderDSC.HBSongMMPLUS
			"workshop":
				should_add_song = song.comes_from_ugc()
			"all":
				should_add_song = true
		
		if should_add_song:
			if UserSettings.user_settings.filter_has_media:
				should_add_song = song.is_cached()
		
		if should_add_song:
			for field in [song.title.to_lower(), song.original_title.to_lower(), song.romanized_title.to_lower()]:
				if search_term.is_empty() or search_term in field:
					_filtered_songs.append(song)
					break
	
	_filtered_songs.sort_custom(Callable(self, "sort_array"))
	return _filtered_songs
		
func sort_array(a: HBSong, b: HBSong):
	var prop = sort_by_prop
	var a_prop = a.get(prop)
	var b_prop = b.get(prop)
	
	match prop:
		"title":
			a_prop = a.get_visible_title()
			b_prop = b.get_visible_title()
		"artist":
			a_prop = a.get_artist_sort_text()
			b_prop = b.get_artist_sort_text()
		"highest_score":
			a_prop = b.get_max_score()
			b_prop = a.get_max_score()
		"lowest_score":
			a_prop = b.get_min_score()
			b_prop = a.get_min_score()
		"_times_played":
			a_prop = HBGame.song_stats.get_song_stats(a.id).times_played
			b_prop = HBGame.song_stats.get_song_stats(b.id).times_played
	
	if a_prop is String:
		a_prop = a_prop.to_lower()
	if b_prop is String:
		b_prop = b_prop.to_lower()
	
	if not sort_by_prop in ["_added_time", "_released_time", "_updated_time"]:
		return a_prop < b_prop
	else:
		return b_prop < a_prop
		
func _create_song_item(song: HBSong):
	var item = SongListItem.instantiate()
	item.use_parent_material = true
	item.set_song(song)
	item.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	return item
func _task_process() -> bool:
	out_mutex.lock()
	filtered_songs = sort_and_filter_songs()
	out_mutex.unlock()

	return true
	
func get_task_output_data():
	return {"filtered_songs": filtered_songs}
	
func _on_task_finished_processing(data):
	emit_signal("songs_filtered", data.filtered_songs, song_id_to_select, difficulty_to_select)
