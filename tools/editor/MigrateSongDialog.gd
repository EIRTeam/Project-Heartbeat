extends ConfirmationDialog

class_name HBMigrateSongDialog

@onready var status_dialog: AcceptDialog = get_node("%StatusDialog")
@onready var error_dialog: AcceptDialog = get_node("%ErrorDialog")
@onready var completed_dialog: AcceptDialog = get_node("%CompletedDialog")

var song: HBSong

const UNCACHED_VARIANT_ERROR_STR := \
"""You need to have downloaded the media for the following song variants:
%s

Remember you need to download the video as well if the variant requires it!"""

func _ready() -> void:
	status_dialog.get_ok_button().hide()
	confirmed.connect(_run_migration)
	
func _show_status(status_text: String):
	status_dialog.dialog_text = status_text

func _show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()
	await error_dialog.visibility_changed
	hide()

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
func _run_migration():
	var uncached_variants: PackedInt32Array
	
	for variant_idx: int in [-1] + range(song.song_variants.size()):
		var variant := song.get_variant_data(variant_idx) as HBSongVariantData
		if variant.variant_url.is_empty():
			continue
		if not variant.is_cached(true):
			uncached_variants.push_back(variant_idx)
	
	if not uncached_variants.is_empty():
		var variant_list: PackedStringArray
		for variant_idx: int in uncached_variants:
			if variant_idx < 0:
				variant_list.push_back("- Default")
			else:
				variant_list.push_back("- " + song.get_variant_data(variant_idx).variant_name)
		_show_error(UNCACHED_VARIANT_ERROR_STR % ["\n".join(variant_list)])
		return
	
	
	var song_directory := song.path
	for variant_idx: int in [-1] + range(song.song_variants.size()):
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
			_show_error("Error copying audio file from\n%s\nto\n%s\nError code %d" % [audio_src, new_audio_file_path, audio_copy_result])
			return
		if not variant_data.audio_only:
			var video_src := YoutubeDL.get_video_path(video_id)
			var video_ext := video_src.get_extension()
			var new_video_file_path := get_variant_file_path(song_directory, "video", variant_idx, video_ext)
			var video_copy_result := DirAccess.copy_absolute(video_src, new_video_file_path)
			if not video_copy_result == OK:
				_show_error("Error copying video file from\n%s\nto\n%s\nError code %d" % [video_src, new_video_file_path, video_copy_result])
				return
			song.set_variant_video_path(variant_idx, new_video_file_path.get_file())
		song.set_variant_audio_path(variant_idx, new_audio_file_path.get_file())
		variant_data.variant_url = ""
	song.youtube_preview_url = song.youtube_url
	song.youtube_url = ""
	
	song.save_song()
	completed_dialog.popup_centered()
	await completed_dialog.visibility_changed
	hide()
	
