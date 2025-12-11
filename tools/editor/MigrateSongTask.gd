extends RefCounted

class_name HBMigrateSongTask

enum MigrationError {
	OK = 0,
	HAS_UNCACHED_VARIANTS = -1,
	COPY_ERROR = -2
}

var song: HBSong
var task_idx: int
var allow_uncached_variants := false
var uncached_variants: PackedInt32Array

const UNCACHED_VARIANT_ERROR_STR := \
"""You need to have downloaded the media for the following song variants:
%s

Remember you need to download the video as well if the variant requires it!"""

class MigrationResult:
	var error: MigrationError
	var error_message: String

	static func make_ok() -> MigrationResult:
		var res := MigrationResult.new()
		res.error = MigrationError.OK
		return res
	
	static func make_error(_error: MigrationError, _message: String):
		var res := MigrationResult.new()
		res.error = _error
		res.error_message = _message
		return res

signal migration_finished()

## This makes sure we generate a unique file name for each variant file
func get_variant_file_path(song_directory: String, base_file_name: String, variant_idx: int, extension: String) -> String:
	var template := base_file_name + "%s" + "." + extension
	var index_template := "_%d"
	var file_path: String = template % [""]
	var test_idx := variant_idx
	if variant_idx >= 0:
		index_template = "_v%d"
		file_path = template % [index_template % [test_idx]]
	
	file_path = song_directory.path_join(file_path)
	
	while FileAccess.file_exists(file_path):
		test_idx += 1
		file_path = template % [index_template % [test_idx]]
	
	return file_path

func _init(_song: HBSong, _allow_uncached_variants := false) -> void:
	song = _song
	allow_uncached_variants = _allow_uncached_variants

func _show_status(status: String):
	pass

func _on_migration_finished(result: MigrationResult, _new_variant_audio_paths: Array[String], _new_variant_video_paths: Array[String]):
	if result.error == MigrationError.OK:
		for i in [-1] + range(song.song_variants.size()):
			if i in uncached_variants and allow_uncached_variants:
				continue
			song.set_variant_audio_path(i, _new_variant_audio_paths[i+1])
			song.set_variant_video_path(i, _new_variant_video_paths[i+1])
			song.get_variant_data(i).variant_url = ""
		song.youtube_preview_url = song.youtube_url
		song.youtube_url = ""
	song.save_song()
	WorkerThreadPool.wait_for_task_completion(task_idx)
	migration_finished.emit(result)
func run_migration():
	var should_show_uncached_variants_error := false
	for variant_idx: int in [-1] + range(song.song_variants.size()):
		var variant := song.get_variant_data(variant_idx) as HBSongVariantData
		if variant.variant_url.is_empty():
			continue
		
		var can_be_uncached := variant_idx != -1 and allow_uncached_variants
		if not variant.is_cached(true):
			uncached_variants.push_back(variant_idx)
			if not should_show_uncached_variants_error:
				should_show_uncached_variants_error = not can_be_uncached
	
	if not uncached_variants.is_empty() and should_show_uncached_variants_error:
		var variant_list: PackedStringArray
		for variant_idx: int in uncached_variants:
			if variant_idx < 0:
				variant_list.push_back("- Default")
			else:
				variant_list.push_back("- " + song.get_variant_data(variant_idx).variant_name)
		migration_finished.emit.call_deferred(MigrationResult.make_error(MigrationError.HAS_UNCACHED_VARIANTS, UNCACHED_VARIANT_ERROR_STR % ["\n".join(variant_list)]))
		return
	task_idx = WorkerThreadPool.add_task(_run_migration, true, "Migrate song")
func _run_migration():
	var song_directory := song.path
	var new_variant_audio_paths: Array[String]
	var new_variant_video_paths: Array[String]
	for variant_idx: int in [-1] + range(song.song_variants.size()):
		if variant_idx in uncached_variants and allow_uncached_variants:
			new_variant_video_paths.push_back("")
			new_variant_audio_paths.push_back("")
			continue
		var variant_data := song.get_variant_data(variant_idx) as HBSongVariantData
		if variant_idx == -1:
			_show_status("Copying media for variant %s" % [ variant_data.variant_name ])
		else:
			_show_status("Copying media for song")
		if variant_data.variant_url.is_empty():
			continue
		
		var new_audio_file_path := get_variant_file_path(song_directory, "audio", variant_idx, "ogg")
		
		var video_id := YoutubeDL.get_video_id(variant_data.variant_url)
		var audio_src := YoutubeDL.get_audio_path(video_id)
		var audio_copy_result := DirAccess.copy_absolute(audio_src, new_audio_file_path)
		
		if not audio_copy_result == OK:
			_on_migration_finished.call_deferred(MigrationResult.make_error(MigrationError.COPY_ERROR, "Error copying audio file from\n%s\nto\n%s\nError code %d" % [audio_src, new_audio_file_path, audio_copy_result]), new_variant_audio_paths, new_variant_video_paths)
			return
		if not variant_data.audio_only:
			var video_src := YoutubeDL.get_video_path(video_id)
			var video_ext := video_src.get_extension()
			var new_video_file_path := get_variant_file_path(song_directory, "video", variant_idx, video_ext)
			var video_copy_result := DirAccess.copy_absolute(video_src, new_video_file_path)
			if not video_copy_result == OK:
				_on_migration_finished.call_deferred(MigrationResult.make_error(MigrationError.COPY_ERROR, "Error copying video file from\n%s\nto\n%s\nError code %d" % [video_src, new_video_file_path, video_copy_result]), new_variant_audio_paths, new_variant_video_paths)
				return
			new_variant_video_paths.push_back(new_video_file_path.get_file())
		else:
			new_variant_video_paths.push_back("")
		new_variant_audio_paths.push_back(new_audio_file_path.get_file())
	_on_migration_finished.call_deferred(MigrationResult.make_ok(), new_variant_audio_paths, new_variant_video_paths)
