extends Control

onready var widget_area = get_node("Node2D/WidgetArea")
onready var game = get_node("RhythmGame")
onready var game_ui = get_node("RythmGameUI")
onready var background_rect : TextureRect = get_node("Node2D/TextureRect")
onready var visualizer = get_node("Node2D/Visualizer")
onready var video_player: VideoPlayer = get_node("Node2D/VideoPlayer")
onready var grid_renderer = get_node("Node2D/GridRenderer")
onready var transform_preview = get_node("TransformPreview")
const SAFE_AREA_FACTOR = 0.05
const SAFE_AREA_SIZE = Vector2(192, 108)
onready var video_pause_timer = Timer.new()
var video_time = 0.0
func _ready():
	game.size = rect_size
	game.editing = true
	game.set_game_ui(game_ui)
	var input_manager = HeartbeatInputManager.new()
	game.set_game_input_manager(input_manager)
	input_manager.set_process_input(false)
	game.toggle_ui()
	connect("resized", self, "_on_resized")
	call_deferred("_on_resized")
	video_pause_timer.connect("timeout", self, "_video_player_debounce")
	video_pause_timer.wait_time = 0.250
	video_pause_timer.one_shot = true
	add_child(video_pause_timer)
	transform_preview.game = game
	visualizer.ingame = true
func _on_resized():
	game.size = rect_size
	game._on_viewport_size_changed()
	update()
	background_rect.set_deferred("rect_size", rect_size)
	visualizer.set_deferred("rect_size", rect_size)
	widget_area.set_deferred("rect_size", rect_size)
	grid_renderer.set_deferred("rect_size", rect_size)
	var height_u = rect_size.y / 9.0
	var width = height_u * 16.0
	var offset_X = (rect_size.x - width) / 2.0
	visualizer.set_deferred("rect_size:x", width)
	visualizer.rect_position.x = offset_X
	rescale_video_player()
func _process(delta):
	$Label.text = HBUtils.format_time(game.time * 1000.0)
	$Label.text += "\n BPM: " + str(game.get_bpm_at_time(game.time*1000.0))
	$Label.text += "\nVP:%s" % [video_player.stream_position]
func set_visualizer_processing_enabled(enabled):
	if UserSettings.user_settings.visualizer_enabled:
		visualizer.set_physics_process(enabled)
	
func _video_player_debounce():
	play_video_from_pos(video_time, true)
	
func play_video_from_pos(pos: float, pause_after = false):
	if video_player.stream and video_player.visible:
		video_player.paused = false
		video_player.play()
		video_player.stream_position = pos
		video_player.paused = false
		for _i in range(5):
			yield(get_tree(), 'idle_frame')
		if pause_after:
			video_player.paused = true
	
func set_time(time: float):
	if video_player.stream and video_player.visible:
		video_time = time
		video_pause_timer.start()
func rescale_video_player():
	var video_texture = video_player.get_video_texture()
	if video_texture:
		var video_size = video_texture.get_size()
		var video_ar = video_size.x / video_size.y
		var new_size_x = rect_size.y * video_ar
		if new_size_x <= rect_size.x:
			# side black bars (or none)
			video_player.rect_size = Vector2(new_size_x, rect_size.y)
		else:
			# bottom and top black bars
			video_player.rect_size = Vector2(rect_size.x, rect_size.x / video_ar)
		# Center that shit
		video_player.rect_position.x = (rect_size.x - video_player.rect_size.x) / 2.0
		video_player.rect_position.y = (rect_size.y - video_player.rect_size.y) / 2.0
	
func set_song(song: HBSong):
	var bg_path = song.get_song_background_image_res_path()
	var image = HBUtils.image_from_fs(bg_path)
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image, Texture.FLAGS_DEFAULT & ~(Texture.FLAG_MIPMAPS))
	background_rect.texture = image_texture
	video_player.stream = null
	background_rect.show()
	video_player.hide()
	visualizer.show()
	if song.has_video_enabled():
		if song.get_song_video_res_path() or (song.youtube_url and song.use_youtube_for_video and song.is_cached()):
			var stream = song.get_video_stream()
			if stream:
				video_player.show()
				# HACK HACK HACK: vp9 decoder requires us to set the stream position
				# to -1, then set it to 0 wait 5 frames, set our target start time
				# wait another 5 frames and only then can we pause the player
				# yeah I don't know why I bother either
				video_player.stream = stream
				video_player.play()
				video_player.stream_position = -1
				video_player.stream_position = 0
				video_player.paused = false # VideoPlayer only pulls frames when it's unpaused
				for _i in range(5):
					yield(get_tree(), 'idle_frame')
				video_player.stream_position = song.start_time  / 1000.0
				video_player.paused = true
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
	_draw_safe_area(origin, size)
func _draw_game_area(origin, size):
	draw_rect(Rect2(origin, size), Color(1.0, 1.0, 1.0), false, 1.0, true)

func _draw_safe_area(origin, size):
	var GAME_AREA_START = game.remap_coords(Vector2.ZERO)
	var safe_area_rect = Rect2(game.remap_coords(SAFE_AREA_SIZE), game.remap_coords(game.BASE_SIZE) + GAME_AREA_START - game.remap_coords(SAFE_AREA_SIZE) * 2)
	draw_rect(safe_area_rect, Color(1.0, 0.0, 0.0), false, 1.0, true)


func show_bg(show):
	if not video_player.stream:
		background_rect.visible = show

func show_video(show):
	if video_player.stream:
		if not show:
			video_player.paused = true
			video_pause_timer.stop()
		video_player.visible = show
