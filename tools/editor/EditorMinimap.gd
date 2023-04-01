extends Panel

var editor: HBEditor setget set_editor

onready var selection_rect = get_node("ColorRect")
signal offset_changed

const LAYER_HEIGHT = 8
const CIRCLE_SIZE = 3

var image = Image.new()
var texture = ImageTexture.new()
var sections := []

class MinimapSection:
	var x_pos: float
	var data: HBChartSection
	
	func _init(_x_pos: float, _data: HBChartSection):
		x_pos = _x_pos
		data = _data

func _ready():
	pass
func set_editor(val):
	editor = val
	editor.connect("timing_points_changed", self, "update")

func _redraw_items():
	sections.clear()
	
	var song_length_ms := int(editor.get_song_length() * 1000.0)
	
	var visible_layers = 0
	for layer in editor.timeline.get_layers():
		if layer.visible and not layer.layer_name in ["Lyrics", "Sections", "Events", "Tempo Map"]:
			visible_layers += 1
	
	# Get a consistent height
	if visible_layers:
		rect_min_size.y = visible_layers * LAYER_HEIGHT
		selection_rect.rect_size.y = rect_size.y
	
	var texture_size_changed = false
	if rect_size != image.get_size():
		image.create(rect_size.x, rect_size.y, false, Image.FORMAT_RGBA8)
		texture_size_changed = true
	
	var base_color = Color.white
	base_color.a = 0.0
	image.fill(base_color)
	image.lock()
	
	for section in editor.get_sections():
		var pos = (section.time / float(song_length_ms)) * rect_size.x
		sections.append(MinimapSection.new(pos, section))
	
	var layer_i = 0
	for layer in editor.timeline.get_layers():
		if not layer.visible:
			continue
		
		if layer.layer_name in ["Lyrics", "Sections", "Events", "Tempo Map"]:
			continue
		
		var y_pos = layer_i * LAYER_HEIGHT
		
		draw_layer_line(0, y_pos, layer_i, null)
		
		for section in sections:
			draw_layer_line(section.x_pos, y_pos, layer_i, section.data)
		
		if layer.get_child_count() > 1:
			var base_item = layer.get_child(1)
			if base_item:
				var note_color: Color
				if base_item is EditorTimelineItemNote:
					note_color = ResourcePackLoader.get_note_trail_color(base_item.data.note_type) as Color
				
				for item in layer.get_children():
					if item is EditorTimelineItemNote:
						var data = item.data as HBTimingPoint
						var pos = data.time / float(song_length_ms)
					
						# We draw the notes in the minimap, they are not squares
						# they match the height for easier viewing.
						for x in range(-1, 2):
							for y in range(-CIRCLE_SIZE, CIRCLE_SIZE):
								if y_pos + y < image.get_size().y:
									if pos*rect_size.x + x < image.get_size().x:
										image.set_pixel(pos*rect_size.x + x, y_pos + y + CIRCLE_SIZE + 1, note_color)
		layer_i += 1
	
	for section in sections:
		for x in range(2):
			for y in range(rect_size.y):
				image.set_pixel(section.x_pos + x, y, section.data.color)
	
	image.unlock()
	if texture_size_changed:
		texture.create_from_image(image, 0)
	else:
		texture.set_data(image)
	draw_texture(texture, Vector2.ZERO)
func _draw():
	_redraw_items()

func draw_layer_line(x_pos, y_pos, layer_i, section):
	var color = section.color if section else null
	if fmod(layer_i, 2) == 1:
		if not color:
			color = Color("#7289DA")
		else:
			color = color.darkened(0.4)
	else:
		if not color:
			color = Color("#4E5D94")
		else:
			color = color.darkened(0.3)
	
	draw_rect(Rect2(Vector2(x_pos, y_pos), Vector2(rect_size.x, CIRCLE_SIZE * 2.0 + 2)), color)

func _sort_by_time(a, b):
	if a is EditorTimelineItem and b is EditorTimelineItem:
		return a.data.time < b.data.time
	else:
		return false

func _on_time_cull_changed(cull_start_time, cull_end_time):
	var song_length_ms: int = int(editor.get_song_length() * 1000.0)
	if song_length_ms > 0:
		var pos = cull_start_time / float(song_length_ms)
		selection_rect.rect_position.x = rect_size.x * pos
		selection_rect.rect_size.x = rect_size.x * ((cull_end_time - cull_start_time) / float(song_length_ms))
		selection_rect.rect_size.y = rect_size.y

func _bsearch_sections(a, b):
	return a.x_pos < b.x_pos

func _gui_input(event):
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		
		hint_tooltip = ""
		
		# Hacky but fast as sonic
		var current_section_i = sections.bsearch_custom({"x_pos": mouse_pos.x}, self, "_bsearch_sections")
		if sections.size() > 0:
			var current_section = sections[clamp(current_section_i-1, 0, sections.size()-1)]
			if current_section:
				if mouse_pos.x > current_section.x_pos:
					hint_tooltip = current_section.data.name
			
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			if event is InputEventMouseButton:
				if not event.button_index == BUTTON_LEFT:
					return
			var song_length_ms: int = int(editor.get_song_length() * 1000.0)
			var new_offset = (get_local_mouse_position().x / rect_size.x) * song_length_ms
			var cull_size = selection_rect.rect_size.x
			emit_signal("offset_changed", max(new_offset - (cull_size / rect_size.x * song_length_ms) / 2.0, 0))
