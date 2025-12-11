extends HBSong

class_name HBSongFromPack

var pack_archive: HBPackArchive

func load_ogg(path_in_zip: String) -> AudioStreamOggVorbis:
	if not pack_archive.zip_file.file_exists(path_in_zip):
		print("Tried to load ogg %s for song %s, file did not exist in phpkg!" % [path_in_zip, id])
	var file_bytes := pack_archive.read_full_file(path_in_zip)
	var stream := PHNative.load_ogg_from_buffer(file_bytes)
	return stream

func get_video_stream(variant := -1):
	var video_path = get_song_video_res_path()
	
	if variant != -1 && not song_variants[variant].variant_video.is_empty():
		video_path = get_variant_video_res_path(variant)
		var video_stream = FFmpegVideoStream.new()
		video_stream.set_file(video_path)
	elif use_youtube_for_video and not youtube_url.is_empty():
		if is_cached(variant):
			if variant == -1 or song_variants[variant].audio_only:
				video_path = YoutubeDL.get_video_path(YoutubeDL.get_video_id(youtube_url))
			else:
				video_path = YoutubeDL.get_video_path(YoutubeDL.get_video_id(song_variants[variant].variant_url))
			# not officially supported but...
			var video_stream = FFmpegVideoStream.new()
			video_stream.set_file(video_path)
			return video_stream
		else:
			Log.log(self, "Tried to get video stream from an uncached song!!")
			return null
	if video_path.is_empty():
		return null
	print("Loading video stream ", video_path)

	var video_stream := PHZipFFmpegVideoStream.create(pack_archive.zip_file, video_path)

	return video_stream

func get_chart_for_difficulty(difficulty) -> HBChart:
	var chart_path = get_chart_path(difficulty)
	var file = pack_archive.zip_file.get_file(chart_path)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var result = test_json_conv.data
	var chart = HBChart.new()
	if not result:
		return null
	chart.deserialize(result, self)
	return chart

func get_audio_stream(variant := -1):
	if variant != -1 && not song_variants[variant].variant_audio.is_empty():
		return load_ogg(get_variant_audio_res_path(variant))
	var audio_path = get_song_audio_res_path()
	if youtube_url:
		if use_youtube_for_audio:
			var variant_url = get_variant_data(variant).variant_url
			if YoutubeDL.get_cache_status(get_variant_data(variant).variant_url, false, true) == YoutubeDL.CACHE_STATUS.OK:
				# not officially supported but...
				audio_path = YoutubeDL.get_audio_path(YoutubeDL.get_video_id(variant_url))
				return HBUtils.load_ogg(audio_path)
			else:
				Log.log(self, "Tried to get audio stream from an uncached song!!")
	return load_ogg(audio_path)

func _image_from_pkg(path: String) -> Texture2D:
	if not pack_archive.zip_file.file_exists(path):
		return null
	var data := pack_archive.read_full_file(path)
	return HBUtils.array2texture(data)


func get_song_preview() -> Texture2D:
	var asset_path = get_song_preview_res_path()
	if asset_path:
		return _image_from_pkg(asset_path)
	return null

func get_song_background() -> Texture2D:
	var asset_path = get_song_background_image_res_path()
	if asset_path:
		return _image_from_pkg(asset_path)
	return null

func get_song_circle_image() -> Texture2D:
	var asset_path = get_song_circle_image_res_path()
	if asset_path:
		return _image_from_pkg(asset_path)
	return null

func get_song_circle_logo() -> Texture2D:
	var asset_path = get_song_circle_logo_image_res_path()
	if asset_path:
		return _image_from_pkg(asset_path)
	return null
