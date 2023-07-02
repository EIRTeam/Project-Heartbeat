extends Control

@onready var url_line_edit = get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/URLLineEdit")
@onready var wait_dialog = get_node("WaitDialog")
@onready var wait_dialog_label = get_node("WaitDialog/Label")
@onready var download_button = get_node("Panel/MarginContainer/VBoxContainer/Button")
@onready var downloader_panel = get_node("Panel")
var request = HTTPRequest.new()
var download_request = HTTPRequest.new()
var GDUnzip = preload("gdunzip.gd")
const UA = "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"

var current_yt_url = ""
var current_title := ""
var current_thumbnail_url := ""
var current_ppd_id := ""

signal error(error)

func _ready():
	add_child(request)
	add_child(download_request)
	request.use_threads = true
	download_request.use_threads = true
	request.connect("request_completed", Callable(self, "_on_request_completed"))
	download_request.connect("request_completed", Callable(self, "_on_zip_download_completed"))
	download_button.connect("pressed", Callable(self, "download_from_url"))

func show_panel():
	downloader_panel.popup_centered_clamped(Vector2(587, 82))

func download_from_url():
	var url = url_line_edit.text.strip_edges()
	if not url.begins_with("https://projectdxxx.me/score/index/id/"):

		show_error("Invalid URL entered")
		return
	var s = url.split("id/")
	if s.size() <= 1:
		show_error("Invalid URL entered")
		return
	else:
		current_ppd_id = s[1]
	wait_dialog_label.text = "Downloading chart information, please wait..."
	wait_dialog.popup_centered()
	current_thumbnail_url = ""
	request.request(url, [UA], HTTPClient.METHOD_GET)
func show_error(error: String):
	emit_signal("error", error)
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	wait_dialog.hide()
	if result == OK and response_code == 200:
		var body_str = body.get_string_from_utf8()
		# Possibly the ugliest HACK in the whole codebase
		# I'm so so sorry
		# This is because the PPD website doesn't produce valid XML,
		# and this attribute having no value is the reason why apparently, so
		# we just get rid of it
		body_str = body_str.replace("allowfullscreen>", ">")
		body = body_str.to_utf8_buffer()
		
		var parser = XMLParser.new()
		parser.open_buffer(body)
		var found_download_url = false
		var found_yt_url = false
		var download_url = ""
		var yt_url = ""
		var video_info_json = {}
		current_title = ""
		while parser.read() == OK:
			if parser.get_node_type() != XMLParser.NODE_ELEMENT:
				continue
			if parser.get_node_name() == "input":
				if parser.has_attribute("value"):
					for i in range(parser.get_attribute_count()):
						if parser.get_attribute_name(i) == "value":
							var potential_url = parser.get_attribute_value(i)
							if potential_url != "":
								video_info_json = YoutubeDL.get_video_info_json(potential_url)
								if not video_info_json.is_empty():
									yt_url = potential_url
									found_yt_url = true
			if parser.get_node_name() == "a":
				if parser.has_attribute("href"):
					for i in range(parser.get_attribute_count()):
						if parser.get_attribute_value(i).begins_with("/score-library/download/id/"):
							download_url = parser.get_attribute_value(i)
							found_download_url = true
			if parser.get_node_name() == "h3" and current_title.is_empty():
				if parser.has_attribute("class"):
					for i in range(parser.get_attribute_count()):
						if parser.get_attribute_name(i) == "class":
							if "panel-title" in parser.get_attribute_value(i):
								parser.read()
								current_title = parser.get_node_data().strip_edges()
			if found_yt_url and found_download_url:
				break
				
		if not found_download_url:
			show_error("Couldn't find chart download, did you input the correct URL?")
		if not found_yt_url:
			show_error("Couldn't find song video URL!")
		
		var proper_format_found = false
		
		if "formats" in video_info_json:
			if "thumbnail" in video_info_json:
				current_thumbnail_url = video_info_json.thumbnail
			for format in video_info_json.formats:
				if format.ext in ["mp4"]:
					proper_format_found = true
		
		if found_yt_url and found_download_url and proper_format_found:
			current_yt_url = yt_url
			wait_dialog_label.text = "Downloading chart, please wait..."
			wait_dialog.popup_centered()
			download_request.request("https://projectdxxx.me" + download_url, [UA])
			
	#request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray)

func _on_zip_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print(result, response_code)
	wait_dialog.hide()
	if result == OK and response_code == 200:
		wait_dialog_label.text = "Installing chart..."
		wait_dialog.popup_centered()
		await get_tree().process_frame
		var zip = GDUnzip.new()
		zip.buffer = body
		zip.buffer_size = body.size()
		zip._get_files()
		
		var songs_folder = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "songs")
		
		var chart_name = "ppd_%s" % [current_ppd_id]
		var found_chart_data = !chart_name.is_empty()
		
		if chart_name.is_empty():
			wait_dialog.hide()
			show_error("Error gathering song metadata")
			return
		
		for f in zip.files:
			if f.ends_with("/data.ini"):
				found_chart_data = true
				
		if not found_chart_data:
			wait_dialog.hide()
			show_error("Error installing chart: data.ini not found")
			return
			
		if DirAccess.dir_exists_absolute(HBUtils.join_path(songs_folder, chart_name)):
			wait_dialog.hide()
			print(HBUtils.join_path(songs_folder, chart_name))
			show_error("Cannot install %s, a chart with that folder name already exists!" % [chart_name])
			return
		for f in zip.files:
			var extraction_path = HBUtils.join_path(songs_folder, HBUtils.join_path(chart_name, f.split("/")[-1]))
			print("Extract to: %s" % extraction_path)
			if f.ends_with(".ppd") or f.ends_with("data.ini"):
				var extraction_dir = extraction_path.get_base_dir()
				# ensure path to extract to exists
				if not DirAccess.dir_exists_absolute(extraction_dir):
					DirAccess.make_dir_recursive_absolute(extraction_dir)
				var uncompressed = zip.uncompress(f)
				if uncompressed:
					var file = FileAccess.open(extraction_path, FileAccess.WRITE)
					file.store_buffer(uncompressed)
					file.close()
				else:
					print("FAILED TO DECOMPRESS ", f)
					
		wait_dialog_label.text = "Downloading video..."
		wait_dialog.popup_centered()
		await get_tree().process_frame
		if perform_ytdl_direct_download(HBUtils.join_path(songs_folder, chart_name)) != OK:
			wait_dialog.hide()
			show_error("Error downloading video, ask on the discord for troubleshooting")
			HBUtils.remove_recursive(HBUtils.join_path(songs_folder, chart_name))
			return
			
		var thumbnail_downloaded = false
		if current_thumbnail_url:
			wait_dialog_label.text = "Downloading video thumbnail..."
			wait_dialog.popup_centered()
			await get_tree().process_frame
			var request = HTTPRequest.new()
			request.use_threads = true
			add_child(request)
			if request.request(current_thumbnail_url) == OK:
				var request_result = await request.request_completed
				var req_result_err = request_result[0]
				var req_body = request_result[3]
				if req_result_err == OK:
					var texture = HBUtils.array2texture(req_body)
					if texture.get_size() != Vector2.ZERO:
						texture.get_image().save_png(HBUtils.join_path(songs_folder, chart_name).path_join("thumbnail.png"))
						thumbnail_downloaded = true
				if not thumbnail_downloaded:
					wait_dialog.hide()
					show_error("Error downloading video thumbnail, ask on the discord for troubleshooting")
					HBUtils.remove_recursive(HBUtils.join_path(songs_folder, chart_name))
					return
			
		var chart_meta_path = HBUtils.join_path(songs_folder, HBUtils.join_path(chart_name, "data.ini"))
		var ppd_ldr = SongLoader.song_loaders["ppd"] as SongLoaderPPD
		var song = ppd_ldr.load_song_meta_from_folder(chart_meta_path, chart_name)
		song.uses_native_video = true
		song.title = current_title
		song.video = "video.mp4"
		song.audio = "audio.ogg"
		# song_ext
		var song_ext = HBPPDSong.new()
		song_ext.uses_native_video = true
		song_ext.video = "video.mp4"
		song_ext.audio = "audio.ogg"
		if thumbnail_downloaded:
			song.preview_image = "thumbnail.png"
			song_ext.preview_image = "thumbnail.png"
		song_ext.title = current_title
		
		wait_dialog_label.text = "Calculating audio normalization..."
		wait_dialog.popup_centered()
		await get_tree().process_frame
		
		var norm = HBAudioNormalizer.new()
		norm.set_target_ogg(song.get_audio_stream())
		while not norm.work_on_normalization():
			pass
		var res = norm.get_normalization_result()
		song.has_audio_loudness = true
		song.audio_loudness = res
		song_ext.has_audio_loudness = true
		song_ext.audio_loudness = res
		
		song_ext.save_to_file(HBUtils.join_path(songs_folder, chart_name).path_join("ph_ext.json"))
		ppd_ldr.set_ppd_youtube_url(song, current_yt_url)
		SongLoader.songs[chart_name] = song
		wait_dialog.hide()
		show_error("Downloaded %s succesfully!" % [current_title])
		#get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))
	else:
		show_error("Error downloading chart (%d, %d)" % [result, response_code])

func perform_ytdl_direct_download(folder: String) -> int:
	var shared_params = YoutubeDL.get_ytdl_shared_params()
	var video_height = UserSettings.user_settings.desired_video_resolution
	var video_fps = UserSettings.user_settings.desired_video_fps
	shared_params += [
		"--merge-output-format", "mp4",
		"-f", "bestvideo[vcodec^=avc1][ext=mp4][height<=?{height}][fps<=?{fps}]+bestaudio[ext=m4a]/best[ext=mp4][height<=?{height}][fps<=?{fps}]".format({"height": video_height, "fps": video_fps})
	]
	
	var video_file_location = folder.path_join("video.mp4")
	
	var o = []
	
	shared_params += [current_yt_url, "-o", ProjectSettings.globalize_path(video_file_location)]
	
	var ee = ""
	
	ee = " ".join(PackedStringArray(shared_params))
	
	OS.execute(YoutubeDL.get_ytdl_executable(), shared_params, o, true)
	
	if not FileAccess.file_exists(video_file_location):
		return ERR_BUG
	else:
		var audio_target = ProjectSettings.globalize_path(folder.path_join("audio.ogg"))
		var arguments = ["-i", ProjectSettings.globalize_path(video_file_location), "-vn", "-acodec", "libvorbis", "-y", audio_target]
		var out = []
		var err = OS.execute(YoutubeDL.get_ffmpeg_executable(), arguments, out, true)
		if err != OK:
			return ERR_BUG
	return OK
