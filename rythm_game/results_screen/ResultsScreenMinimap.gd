extends Control

var game_info: HBGameInfo setget set_game_info

var chart: HBChart

var image = Image.new()
var texture = ImageTexture.new()

const CIRCLE_SIZE = 4
const TOP_MARGIN = 0.0

func _ready():
	var gf = HBGameInfo.new()
	gf.song_id = "sands_of_time"
	gf.difficulty = "extreme"
	gf.result._song_end_time = 60*4
	set_game_info(gf)

func set_game_info(val):
	game_info = val
	var song := game_info.get_song() as HBSong
	chart = song.get_chart_for_difficulty(game_info.difficulty) as HBChart
	
func _redraw_items():
	var time_start = OS.get_ticks_usec()
	var base_color = Color.white
	base_color.a = 0.0
	var texture_size_changed = false
	if abs(rect_size.y) == 0:
		return
	if abs(rect_size.x) == 0:
		return
	if rect_size != image.get_size():
		image.create(rect_size.x, rect_size.y, false, Image.FORMAT_RGBA8)
		texture_size_changed = true
	else:
		image.fill(base_color)
	image.lock()

	#image.fill(base_color)
	
	var visible_layers = 0
	for layer in chart.layers:
		if layer.name != "Events" and layer.name != "Lyrics" and not layer.timing_points.empty():
			visible_layers += 1
			
	var current_song := game_info.get_song() as HBSong
			
	var start_time = current_song.start_time / 1000.0
	var end_time = game_info.result._song_end_time / 1000.0
	var duration = end_time - start_time
	var wii = (visible_layers / float(visible_layers))
	var y_pos_max = (float(rect_size.y) * wii)
	var off_y = (rect_size.y - y_pos_max) / 2.0 + CIRCLE_SIZE / 2.0
	var layer_i = 1
	for layer in chart.layers:
		if layer.name == "Events" or layer.name == "Lyrics" or layer.timing_points.empty():
#			layer_i += 1
			continue
		# We draw the layer lines
		var y_pos = off_y + (rect_size.y * (layer_i / float(visible_layers+1)))
		var rect_color: Color = Color.white
#		if fmod(layer_i, 2) == 0:
		rect_color.a = 0.5
		if fmod(layer_i, 2) == 0:
			rect_color.a = 0.25
		
		draw_line(Vector2(0, y_pos + TOP_MARGIN - CIRCLE_SIZE / 2.0 + 2), Vector2(rect_size.x, y_pos + TOP_MARGIN - CIRCLE_SIZE / 2.0 + 2), rect_color, 4, false)
#		draw_rect(Rect2(Vector2(0, y_pos + TOP_MARGIN - CIRCLE_SIZE), Vector2(rect_size.x, 1)), rect_color)
		
		if layer.timing_points.size() > 0:
			var base_item := layer.timing_points[0] as HBBaseNote
			if base_item:
				var note_color := ResourcePackLoader.get_note_trail_color(base_item.note_type) as Color
				
				for item in layer.timing_points:
					if item is HBBaseNote:
						var pos = ((item.time / 1000.0) - start_time) / duration
						
						# We draw the notes in the minimap, they are not squares
						# they match the height for easier viewing.
						for x in range(-CIRCLE_SIZE, CIRCLE_SIZE):
							for y in range(-CIRCLE_SIZE, CIRCLE_SIZE):
								if y_pos + TOP_MARGIN + y < image.get_size().y:
									if pos*rect_size.x + x < image.get_size().x:
										image.set_pixel(pos*rect_size.x + x, y_pos + TOP_MARGIN + y, note_color)
		layer_i += 1
	image.unlock()
	if texture_size_changed:
		texture.create_from_image(image, 0)
	else:
		texture.set_data(image)
	var time_end = OS.get_ticks_usec()
	print("_renegerate_minimap took %d microseconds" % [(time_end - time_start)])
	draw_texture(texture, Vector2.ZERO)
	
var _redraw_referred = false
	
func _draw():
	if not _redraw_referred:
		_redraw_referred = true
		call_deferred("update")
	else:
		_redraw_items()
		_redraw_referred = false
