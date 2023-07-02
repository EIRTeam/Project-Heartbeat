extends HBPPDSong

class_name HBPPDSongEXT


func _init():
	super()
	LOG_NAME = "HBPPDSongEXT"

func get_serialized_type():
	return "PPDSongEXT"

# audio extracted from video
func has_audio():
	return (video and FileAccess.file_exists(get_song_video_res_path())) or FileAccess.file_exists(get_song_audio_res_path())
		
func is_cached(variant := -1):
	return (video and FileAccess.file_exists(get_song_video_res_path())) and FileAccess.file_exists(get_song_audio_res_path())

func get_audio_stream(variant := -1):
	var audio_path = get_song_audio_res_path()
	var source_path = get_song_video_res_path()
	if audio_path.ends_with(".wav"):
		source_path = get_song_audio_res_path()
		audio_path = audio_path.get_basename() + ".ogg"
		
	var found_audio = FileAccess.file_exists(audio_path)
	# extract audio to ogg if it doesn't exist
	if not found_audio:
		var arguments = ["-nostdin", "-i", source_path, "-vn", "-acodec", "libvorbis", "-y", audio_path]
		var out = []
		var err = OS.execute(YoutubeDL.get_ffmpeg_executable(), arguments, out, true)
		if err != OK:
			print("ERROR CONVERTING!")
			print(out)
		found_audio = FileAccess.file_exists(audio_path)
	if found_audio:
		return HBUtils.load_ogg(audio_path)
	else:
		return null
	
func get_video_stream(variant := -1):
	# TODOGD4: This
	var video_stream = VideoStreamTheora.new()
	video_stream.set_file(get_song_video_res_path())
	return video_stream
