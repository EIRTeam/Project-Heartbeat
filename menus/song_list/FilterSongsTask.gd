class_name HBFilterSongsTask

const SongListItem = preload("res://menus/song_list/SongListItem.tscn")

signal songs_filtered(songs, song_id_to_select, difficulty_to_select)

var out_mutex := Mutex.new()
var songs: Array
var filter_by: String
var filtered_songs: Array
var sort_by_prop: StringName
var song_id_to_select
var difficulty_to_select
var search_term: String

var task_id: int

func _init(_songs: Array, _filter_by: String, _sort_by: String, _song_id_to_select=null, _difficulty_to_select=null, _search_term := ""):
	songs = _songs
	filter_by = _filter_by
	sort_by_prop = _sort_by
	song_id_to_select = _song_id_to_select
	difficulty_to_select = _difficulty_to_select
	search_term = _search_term.to_lower()
	
class SongFilterData:
	var string_cmp: String
	var int_cmp: int
	var float_cmp: float
	var song: HBSong
	func _init(_song: HBSong):
		song = _song
	
func get_compare_func() -> Callable:
	var out_callable: Callable
	match sort_by_prop:
		&"title", &"artist", &"creator":
			out_callable = self.string_compare
		&"bpm", &"_times_played":
			out_callable = self.int_compare_asc
		&"_added_time", &"_released_time", &"_updated_time":
			out_callable = self.int_compare_desc
		&"lowest_score":
			out_callable = self.float_compare_asc
		&"highest_score":
			out_callable = self.float_compare_desc
			
			
	assert(out_callable.is_valid())
	return out_callable
	
func fill_compare_data(song: HBSong, filter_data: SongFilterData):
	match sort_by_prop:
		&"title":
			filter_data.string_cmp = song.get_visible_title().to_lower()
		&"artist":
			filter_data.string_cmp = song.get_artist_sort_text()
		&"creator":
			filter_data.string_cmp = song.creator
		&"highest_score":
			filter_data.float_cmp = song.get_max_score()
		&"lowest_score":
			filter_data.float_cmp = song.get_min_score()
		&"bpm":
			filter_data.int_cmp = song.bpm
		&"times_played":
			filter_data.int_cmp = song._times
		&"_times_played":
			filter_data.int_cmp = HBGame.song_stats.get_song_stats(song.id).times_played
		&"_added_time":
			filter_data.int_cmp = song._added_time
		&"_released_time":
			filter_data.int_cmp = song._released_time
		&"_updated_time":
			filter_data.int_cmp = song._updated_time
			
func queue():
	task_id = WorkerThreadPool.add_task(self.sort_and_filter_songs, true, "Song list sort and filter")
			
func sort_and_filter_songs():
	var _filtered_songs = []
	var editor_songs_path = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs")
	var compare_func := get_compare_func()
	var filter_datas: Array[SongFilterData]
	for song in songs:
		var should_add_song = false
		match filter_by:
			&"ppd":
				should_add_song = song is HBPPDSong and not (UserSettings.user_settings.hide_ppd_ex_songs and song is HBPPDSongEXT)
			&"official":
				should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN
			&"local":
				should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER \
									and not song is HBPPDSong and not song.comes_from_ugc() \
									and not song.path.begins_with(editor_songs_path) \
									and not song is SongLoaderDSC.HBSongDSC
			&"editor":
				should_add_song = song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER \
									and not song is HBPPDSong and not song.comes_from_ugc() \
									and song.path.begins_with(editor_songs_path) \
									and not song is SongLoaderDSC.HBSongDSC
			&"mmplus":
				should_add_song = song is SongLoaderDSC.HBSongMMPLUS and song.is_built_in
			&"mmplus_mod":
				should_add_song = song is SongLoaderDSC.HBSongMMPLUS and song.is_mod_song and not song.is_built_in
			&"dsc":
				should_add_song = song is SongLoaderDSC.HBSongDSC and not song is SongLoaderDSC.HBSongMMPLUS
			&"workshop":
				should_add_song = song.comes_from_ugc()
			&"all":
				should_add_song = true
		
		if should_add_song:
			if UserSettings.user_settings.filter_has_media:
				should_add_song = song.is_cached()
		
		if should_add_song:
			for field in [song.title.to_lower(), song.original_title.to_lower(), song.romanized_title.to_lower()]:
				if search_term.is_empty() or search_term in field:
					var filter_data := SongFilterData.new(song)
					fill_compare_data(song, filter_data)
					filter_datas.push_back(filter_data)
					break
	
	filter_datas.sort_custom(compare_func)
	var out_songs: Array = filter_datas.map(func(d: SongFilterData) -> HBSong: return d.song)
	_task_finished.call_deferred(out_songs)

func _task_finished(out_songs: Array):
	songs_filtered.emit(out_songs, song_id_to_select, difficulty_to_select)
	WorkerThreadPool.wait_for_task_completion(task_id)
	task_id = -1

func string_compare(a: SongFilterData, b: SongFilterData):
	return a.string_cmp < b.string_cmp
		
func int_compare_asc(a: SongFilterData, b: SongFilterData):
	return a.int_cmp < b.int_cmp
		
func int_compare_desc(a: SongFilterData, b: SongFilterData):
	return b.int_cmp < a.int_cmp
		
func float_compare_asc(a: SongFilterData, b: SongFilterData):
	return a.float_cmp < b.float_cmp
		
func float_compare_desc(a: SongFilterData, b: SongFilterData):
	return b.float_cmp < a.float_cmp
		
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if task_id != -1 and not WorkerThreadPool.is_task_completed(task_id):
			WorkerThreadPool.wait_for_task_completion(task_id)
