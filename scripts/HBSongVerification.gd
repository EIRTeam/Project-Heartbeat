# Class that verifies if a song is playable
extends Node

class_name HBSongVerification

enum CHART_ERROR {
	OK,
	FILE_NOT_FOUND,
	FILE_INVALID_JSON,
	HOLD_CHAIN_PIECE_WITHOUT_PARENT,
	AUDIO_NOT_DOWNLOADED
}



var CHART_ERROR_SEVERITY = {
	"fatal": [ CHART_ERROR.FILE_NOT_FOUND, CHART_ERROR.FILE_INVALID_JSON ],
	"warning": [ CHART_ERROR.HOLD_CHAIN_PIECE_WITHOUT_PARENT ]
}

enum META_ERROR {
	YOUTUBE_URL_INVALID,
	MANDATORY_FIELD_MISSING,
	AUDIO_FIELD_MISSING,
	AUDIO_NOT_FOUND,
	VOICE_NOT_FOUND,
	PREVIEW_MISSING,
	PREVIEW_FILE_MISSING,
	PREVIEW_FILE_TOO_BIG,
	ILLEGAL_FILES,
	ILLEGAL_FOLDERS
}

const LEGAL_FILE_EXTENSIONS = ["json", "png", "jpg", "jpeg"]

var META_ERROR_SEVERITY = {
	"fatal": [ META_ERROR.AUDIO_FIELD_MISSING, META_ERROR.VOICE_NOT_FOUND, META_ERROR.PREVIEW_FILE_MISSING, META_ERROR.AUDIO_NOT_FOUND ],
	"warning": [ META_ERROR.MANDATORY_FIELD_MISSING, META_ERROR.PREVIEW_FILE_TOO_BIG, META_ERROR.PREVIEW_MISSING, META_ERROR.ILLEGAL_FILES, META_ERROR.ILLEGAL_FOLDERS ],
	# Some things are only mandatory for UGC songs and will still allow the song to be played
	"fatal_ugc": [ META_ERROR.MANDATORY_FIELD_MISSING, META_ERROR.PREVIEW_MISSING, META_ERROR.PREVIEW_FILE_TOO_BIG, META_ERROR.ILLEGAL_FILES, META_ERROR.ILLEGAL_FOLDERS, CHART_ERROR.AUDIO_NOT_DOWNLOADED ]
}
# Meta fields that MUST be set to something 
const MANDATORY_META_FIELDS = [
	"title", "artist", "creator"
]

func verify_song(song: HBSong):
	var errors = {
		"meta": verify_meta(song),
		"audio": verify_audio(song)
	}
	for chart in song.charts:
		errors["chart_%s" % [chart]] = verify_chart(song, chart)
	return errors
func verify_meta(song: HBSong):
	var errors = []
	
	for field in MANDATORY_META_FIELDS:
		var field_c = song.get(field)
		if not field_c or field_c.strip_edges() == "":
			var error = {
				"type": META_ERROR.MANDATORY_FIELD_MISSING,
				"string": "The song is missing the %s field" % [field],
			}
			errors.append(error)
	if song.youtube_url:
		if not YoutubeDL.validate_video_url(song.youtube_url):
			var error = {
				"type": META_ERROR.YOUTUBE_URL_INVALID,
				"string": "The song's YouTube URL is invalid",
			}
			errors.append(error)
	if not song.audio and not (song.youtube_url and song.use_youtube_for_audio):
		var error = {
			"type": META_ERROR.AUDIO_FIELD_MISSING,
			"string": "The song doesn't have an audio file",
		}
		errors.append(error)
	elif not (song.youtube_url and song.use_youtube_for_audio):
		var audio_path = song.get_song_audio_res_path()
		if not FileAccess.file_exists(audio_path):
			var error = {
				"type": META_ERROR.AUDIO_NOT_FOUND,
				"string": "The song's audio file does not exist on disk",
			}
			errors.append(error)
	if song.voice:
		if not FileAccess.file_exists(song.get_song_voice_res_path()):
			var error = {
				"type": META_ERROR.AUDIO_NOT_FOUND,
				"string": "The song's voice audio file does not exist on disk",
			}
			errors.append(error)
	if not song.preview_image:
		var error = {
			"type": META_ERROR.PREVIEW_MISSING,
			"string": "The song doesn't have a preview image",
		}
		errors.append(error)
	else:
		if not FileAccess.file_exists(song.get_song_preview_res_path()):
			var error = {
				"type": META_ERROR.PREVIEW_FILE_MISSING,
				"string": "The song preview image file does not exist on disk",
			}
			errors.append(error)
		else:
			var file := FileAccess.open(song.get_song_preview_res_path(), FileAccess.READ)
			if file.get_length() > 1000000:
				var error = {
					"type": META_ERROR.PREVIEW_FILE_TOO_BIG,
					"string": "The song preview image file is too big (should be under 1 MB!), it currently is %.2f MB" % [file.get_length() / 1000000.0],
				}
				errors.append(error)
		
		if not song.is_cached():
			var error = {
				"type": META_ERROR.AUDIO_NOT_FOUND,
				"string": "The song's audio file cannot be found on this disk, you must have them on disk before uploading a song to the workshop, please download it.",
			}
			errors.append(error)
		
		
		if DirAccess.dir_exists_absolute(song.path):
			var found_folder = false
			var found_illegal_files := PackedStringArray()
			var dir := DirAccess.open(song.path)
			if DirAccess.get_open_error() == OK:
				dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
				var dir_name = dir.get_next()
				while dir_name != "":
					if not dir.current_is_dir():
						var ext = dir_name.to_lower().get_extension()
						if not ext in LEGAL_FILE_EXTENSIONS:
							found_illegal_files.append(dir_name)
					else:
						found_folder = true
					dir_name = dir.get_next()
			if found_illegal_files.size() > 0:
				var legal_shit = PackedStringArray()
				for extension in LEGAL_FILE_EXTENSIONS:
					legal_shit.append(".%s" % [extension])
				var error = {
					"type": META_ERROR.ILLEGAL_FILES,
					"string": "The song's folder contained files that aren't allowed, allowed types are: %s.\nWe found the following disallowed files: %s.\nPlease remove them before uploading to the workshop." % [", ".join(legal_shit), ",\n".join(found_illegal_files)],
				}
				errors.append(error)
			if found_folder:
				var error = {
					"type": META_ERROR.ILLEGAL_FILES,
					"string": "The song's folder contained subfolders, which aren't allowed, please remove them before uploading to the workshop.",
				}
				errors.append(error)
	for error in errors:
		error["fatal"] = false
		error["warning"] = false
		error["fatal_ugc"] = false
		if error.type in META_ERROR_SEVERITY.fatal_ugc:
			error["fatal_ugc"] = true
		if error.type in META_ERROR_SEVERITY.fatal:
			error["fatal"] = true
		elif error.type in META_ERROR_SEVERITY.warning:
			error["warning"] = true

	return errors
func verify_audio(song: HBSong):
	var errors = []
	if song.audio:
		if FileAccess.file_exists(song.get_song_audio_res_path()):
			var err_audio = HBUtils.verify_ogg(song.get_song_audio_res_path())
			if err_audio == HBUtils.OGG_ERRORS.NOT_AN_OGG:
				var error = {
					"type": HBUtils.OGG_ERRORS.NOT_AN_OGG,
					"string": "The audio file is not an OGG",
				}
				errors.append(error)
			elif err_audio == HBUtils.OGG_ERRORS.NOT_VORBIS:
				var error = {
					"type": HBUtils.OGG_ERRORS.NOT_AN_OGG,
					"string": "The audio file is an OGG file, but it doesn't use the vorbis codec.",
				}
				errors.append(error)
	if song.voice:
		if FileAccess.file_exists(song.get_song_voice_res_path()):
			var err_audio = HBUtils.verify_ogg(song.get_song_voice_res_path())
			if err_audio == HBUtils.OGG_ERRORS.NOT_AN_OGG:
				var error = {
					"type": HBUtils.OGG_ERRORS.NOT_AN_OGG,
					"string": "The voice audio file is not an OGG",
				}
				errors.append(error)
			elif err_audio == HBUtils.OGG_ERRORS.NOT_VORBIS:
				var error = {
					"type": HBUtils.OGG_ERRORS.NOT_AN_OGG,
					"string": "The voice audio file is an OGG file, but it doesn't use the vorbis codec.",
				}
				errors.append(error)
	for error in errors:
		error["fatal"] = true
		error["warning"] = false
		error["fatal_ugc"] = false
	return errors
func verify_chart(song: HBSong, difficulty: String):
	var path = song.get_chart_path(difficulty)
	var errors = []
	if not FileAccess.file_exists(path):
		var error = {
			"type": CHART_ERROR.FILE_NOT_FOUND,
			"string": "Couldn't find this chart's file",
		}
		errors.append(error)
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		var test_json_conv = JSON.new()
		var json_err := test_json_conv.parse(file.get_as_text())
		var result = test_json_conv.data
		if json_err != OK:
			var error = {
				"type": CHART_ERROR.FILE_INVALID_JSON,
				"string": "Chart JSON Invalid:\n " + str(test_json_conv.get_error_message()) + " at line " + str(test_json_conv.get_error_line())
			}
			errors.append(error)
		else:
			var chart = HBChart.new()
			chart.deserialize(result.result, song)
			var found_left_slide = false
			var found_right_slide = false
			var points = chart.get_timing_points()
			points.reverse()
			for point in points:
				if point is HBBaseNote:
					if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
						found_left_slide = true
					if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
						found_right_slide = true
					if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT and not found_left_slide:
						var error = {
							"type": CHART_ERROR.HOLD_CHAIN_PIECE_WITHOUT_PARENT,
							"string": "Found a left slide chain piece that didn't come after a slide of the same direction at time " + str(point.time)
						}
						errors.append(error)
						break
					if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT and not found_right_slide:
						var error = {
							"type": CHART_ERROR.HOLD_CHAIN_PIECE_WITHOUT_PARENT,
							"string": "Found a right slide chain piece that didn't come after a slide of the same direction at time " + str(point.time)
						}
						errors.append(error)
						break
	for error in errors:
		error["fatal"] = false
		error["warning"] = false
		error["fatal_ugc"] = false
		if error.type in CHART_ERROR_SEVERITY.fatal:
			error["fatal"] = true
		elif error.type in CHART_ERROR_SEVERITY.warning:
			error["warning"] = true
	return errors

func has_fatal_error(errors, count_ugc=false):
	for error_class in errors:
		for error in errors[error_class]:
			if error.fatal or (error.fatal_ugc and count_ugc):
				return true
	return false
