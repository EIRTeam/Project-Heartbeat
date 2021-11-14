extends Control

onready var url_line_edit = get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/URLLineEdit")
onready var wait_dialog = get_node("WaitDialog")
onready var wait_dialog_label = get_node("WaitDialog/Label")
onready var download_button = get_node("Panel/MarginContainer/VBoxContainer/Button")
onready var downloader_panel = get_node("Panel")
var request = HTTPRequest.new()
var download_request = HTTPRequest.new()
var GDUnzip = preload("gdunzip.gd")
const UA = "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"

var current_yt_url = ""
var current_title := ""

signal error(error)

func _ready():
	add_child(request)
	add_child(download_request)
	request.use_threads = true
	download_request.use_threads = true
	request.connect("request_completed", self, "_on_request_completed")
	download_request.connect("request_completed", self, "_on_zip_download_completed")
	download_button.connect("pressed", self, "download_from_url")
	wait_dialog.get_close_button().hide()

func show_panel():
	downloader_panel.popup_centered_minsize(Vector2(587, 82))

func download_from_url():
	var url = url_line_edit.text.strip_edges()
	if not url.begins_with("https://projectdxxx.me"):
		show_error("Invalid URL entered")
		return
	wait_dialog_label.text = "Downloading chart information, please wait..."
	wait_dialog.popup_centered()
	request.request(url, [UA], true, HTTPClient.METHOD_GET)
func show_error(error: String):
	emit_signal("error", error)
func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	wait_dialog.hide()
	if result == OK and response_code == 200:
		var parser = XMLParser.new()
		parser.open_buffer(body)
		var found_download_url = false
		var found_yt_url = false
		var download_url = ""
		var yt_url = ""
		current_title = ""
		while parser.read() == OK:
			if parser.get_node_type() != XMLParser.NODE_ELEMENT:
				continue
			if parser.get_node_name() == "input":
				if parser.has_attribute("value"):
					for i in range(parser.get_attribute_count()):
						if parser.get_attribute_name(i) == "value":
							var potential_url = parser.get_attribute_value(i)
							if YoutubeDL.validate_video_url(potential_url):
								yt_url = potential_url
								found_yt_url = true
			if parser.get_node_name() == "a":
				if parser.has_attribute("href"):
					for i in range(parser.get_attribute_count()):
						if parser.get_attribute_value(i).begins_with("/score-library/download/id/"):
							download_url = parser.get_attribute_value(i)
							found_download_url = true
			if parser.get_node_name() == "h3" and current_title.empty():
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
			show_error("Only charts with YouTube target movies are supported")
				
		if found_yt_url and found_download_url:
			current_yt_url = yt_url
			wait_dialog_label.text = "Downloading chart, please wait..."
			wait_dialog.popup_centered()
			download_request.request("https://projectdxxx.me" + download_url, [UA])
			
	#request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray)

func _on_zip_download_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print(result, response_code)
	wait_dialog.hide()
	if result == OK and response_code == 200:
		wait_dialog_label.text = "Installing chart..."
		wait_dialog.popup_centered()
		yield(get_tree(), "idle_frame")
		var zip = GDUnzip.new()
		zip.buffer = body
		zip.buffer_size = body.size()
		zip._get_files()
		
		var songs_folder = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "songs")
		var dir = Directory.new()
		
		var chart_name = current_title
		var found_chart_data = !chart_name.empty()
		
		if chart_name.empty():
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
			
		if dir.dir_exists(HBUtils.join_path(songs_folder, chart_name)):
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
				if not dir.dir_exists(extraction_dir):
					dir.make_dir_recursive(extraction_dir)
				var uncompressed = zip.uncompress(f)
				if uncompressed:
					var file = File.new()
					file.open(extraction_path, File.WRITE)
					file.store_buffer(uncompressed)
				else:
					print("FAILED TO DECOMPRESS ", f)
		var chart_meta_path = HBUtils.join_path(songs_folder, HBUtils.join_path(chart_name, "data.ini"))
		var ppd_ldr = SongLoader.song_loaders["ppd"] as SongLoaderPPD
		var song = ppd_ldr.load_song_meta_from_folder(chart_meta_path, chart_name)
		ppd_ldr.set_ppd_youtube_url(song, current_yt_url)
		SongLoader.songs[chart_name] = song
		wait_dialog.hide()
		show_error("Downloaded %s succesfully!" % [chart_name])
		#get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))
	else:
		show_error("Error downloading chart (%d, %d)" % [result, response_code])
