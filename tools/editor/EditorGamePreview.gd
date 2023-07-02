extends Control

@onready var widget_area = get_node("Node2D/WidgetArea")
@onready var game = get_node("RhythmGame")
@onready var game_ui = get_node("RythmGameUI")
@onready var background_rect : TextureRect = get_node("Node2D/TextureRect")
@onready var visualizer = get_node("Node2D/Visualizer")
@onready var video_player: VideoStreamPlayer = get_node("Node2D/VideoStreamPlayer")
@onready var grid_renderer = get_node("Node2D/GridRenderer")
@onready var transform_preview = get_node("TransformPreview")
var settings: HBPerSongEditorSettings
const SAFE_AREA_FACTOR = 0.05
const SAFE_AREA_SIZE = Vector2(192, 108)
@onready var video_pause_timer = Timer.new()
var video_time = 0.0

signal preview_size_changed

func _ready():
	video_player.volume_db = 0
	game.health_system_enabled = false
	game.size = size
	game.editing = true
	game.set_game_ui(game_ui)
	var input_manager = HeartbeatInputManager.new()
	game.set_game_input_manager(input_manager)
	input_manager.set_process_input(false)
	game.toggle_ui()
	connect("resized", Callable(self, "_on_resized"))
	_on_resized()
	video_pause_timer.connect("timeout", Callable(self, "_video_player_debounce"))
	video_pause_timer.wait_time = 0.250
	video_pause_timer.one_shot = true
	add_child(video_pause_timer)
	transform_preview.game = game
	visualizer.ingame = true
	video_player.connect("finished", Callable(self, "_on_video_player_finished"))
	game_ui.aspect_ratio_container.connect("resized", Callable(self, "_on_game_resized"))

func _on_game_resized():
	if game_ui.size.y != 0:
		var ratio: float = game_ui.size.x / game_ui.size.y
		var scale: float = (game_ui.aspect_ratio_container.size.x / 1920.0)
		if ratio > 16.0/9.0:
			scale = (game_ui.aspect_ratio_container.size.y / 1080.0)
		game_ui.game_layer_node.scale = Vector2.ONE * scale
		emit_signal("preview_size_changed")
	
func _on_video_player_finished():
	video_player.play()
	video_player.paused = true 
	video_player.stream_position = 0.0
func _on_resized():
	game.size = size
	game._on_viewport_size_changed()
	queue_redraw()
	background_rect.size = size
	visualizer.size = size
	widget_area.size = size
	grid_renderer.size = size
	var height_u = size.y / 9.0
	var width = height_u * 16.0
	var offset_X = (size.x - width) / 2.0
	visualizer.size.x = width
	visualizer.position.x = offset_X
	rescale_video_player()
func pause():
	video_player.paused = true
func _process(delta):
	if $Label.visible:
		$Label.text = HBUtils.format_time(game.time_msec)
		$Label.text += "\n BPM: " + str(game.get_note_speed_at_time(game.time_msec))
		$Label.text += "\nVP:%s" % [video_player.stream_position]
		$Label.text += "\nDIFF:%.2f" % [video_player.stream_position - game.time_msec / 1000.0]

func set_visualizer_processing_enabled(enabled):
	if UserSettings.user_settings.visualizer_enabled:
		visualizer.set_physics_process(enabled)
	
func _video_player_debounce():
	video_player.stream_position = video_time

func play_video_from_pos(pos: float):
	if video_player.stream and video_player.visible:
		video_player.paused = false
		if not is_equal_approx(video_player.stream_position, pos):
			video_player.stream_position = pos

func set_time(time: float):
	if video_player.stream and video_player.visible:
		video_time = time
		_video_player_debounce()

func rescale_video_player():
	var video_texture = video_player.get_video_texture()
	if video_texture:
		var video_size = video_texture.get_size()
		var video_ar = video_size.x / video_size.y
		var new_size_x = size.y * video_ar
		if new_size_x <= size.x:
			# side black bars (or none)
			video_player.size = Vector2(new_size_x, size.y)
		else:
			# bottom and top black bars
			video_player.size = Vector2(size.x, size.x / video_ar)
		# Center that shit
		video_player.position.x = (size.x - video_player.size.x) / 2.0
		video_player.position.y = (size.y - video_player.size.y) / 2.0
	
func set_song(song: HBSong, variant=-1):
	var bg_path = song.get_song_background_image_res_path()
	var image = HBUtils.image_from_fs(bg_path)
	var image_texture = ImageTexture.create_from_image(image) #,Texture2D.FLAGS_DEFAULT & ~(Texture2D.FLAG_MIPMAPS)
	background_rect.texture = image_texture
	video_player.stream = null
	background_rect.show()
	video_player.hide()
	visualizer.show()
	if song.has_video_enabled():
		if song.get_song_video_res_path() or (song.youtube_url and song.use_youtube_for_video and song.is_cached()):
			var stream = song.get_video_stream(variant)
			if stream:
				video_player.show()
				# HACK HACK HACK: vp9 decoder requires us to set the stream position
				# to -1, then set it to 0 wait 5 frames, set our target start time
				# wait another 5 frames and only then can we pause the player
				# yeah I don't know why I bother either
				video_player.stream = stream
				video_player.stream_position = song.start_time  / 1000.0
				video_player.play()
				video_player.paused = true
				var offset = song.get_video_offset(variant)
				video_player.offset = -offset / 1000.0
				video_player.set_stream_position(song.get_video_offset(variant) / 1000.0)
				if visualizer:
					visualizer.visible = UserSettings.user_settings.use_visualizer_with_video
				rescale_video_player()
				background_rect.hide()
			else:
				Log.log(self, "Video Stream failed to load")

func play_at_pos(pos: float):
	video_time = pos
	video_pause_timer.stop()
	play_video_from_pos(pos)

func _draw():
	var origin = game.remap_coords(Vector2())
	var size = game.playing_field_size
	_draw_game_area(origin, size)
	_draw_safe_area()
func _draw_game_area(origin, size):
	draw_rect(Rect2(origin, size), Color(1.0, 1.0, 1.0), false, 1.0)# true) TODOGODOT4 Antialiasing argument is missing

func _get_safe_area_rect():
	var GAME_AREA_START = game.remap_coords(Vector2.ZERO)
	return Rect2(game.remap_coords(SAFE_AREA_SIZE), game.remap_coords(game.BASE_SIZE) + GAME_AREA_START - game.remap_coords(SAFE_AREA_SIZE) * 2)
func _draw_safe_area():
	draw_rect(_get_safe_area_rect(), Color(1.0, 0.0, 0.0), false, 1.0)# true) TODOGODOT4 Antialiasing argument is missing


func show_bg(show: bool):
	settings.set("show_bg", show)
	
	update_bga()

func show_video(show: bool):
	settings.set("show_video", show)
	
	update_bga()

func update_bga(force_video_off: bool = false):
	if not settings:
		return
	
	var show_video = settings.show_video and not force_video_off
	
	if video_player.stream:
		if show_video:
			video_player.paused = true
			video_pause_timer.stop()
		
		video_player.visible = show_video
	
	background_rect.visible = false
	if not video_player.visible:
		background_rect.visible = settings.show_bg
