extends Panel

var editor: HBEditor setget set_editor

const CIRCLE_SIZE = 2
const TOP_MARGIN = 5.0

onready var selection_rect = get_node("ColorRect")
signal offset_changed

var image = Image.new()
var texture = ImageTexture.new()

func _ready():
	pass
func set_editor(val):
	editor = val
	editor.connect("timing_points_changed", self, "update")

func _redraw_items():
	var base_color = Color.white
	base_color.a = 0.0
	var texture_size_changed = false
	if rect_size != image.get_size():
		image.create(rect_size.x, rect_size.y, false, Image.FORMAT_RGBA8)
		texture_size_changed = true
	else:
		image.fill(base_color)
	image.lock()

	#image.fill(base_color)
	
	var visible_layers = 0
	for layer in editor.timeline.get_layers():
		if layer.visible:
			visible_layers += 1
	var layer_i = 0
	for layer in editor.timeline.get_layers():
		if not layer.visible:
			continue
		# We draw the layer lines
		var y_pos = rect_size.y * (layer_i / float(visible_layers))
		var rect_color: Color = Color("#2D3444")
		if fmod(layer_i, 2) == 0:
			rect_color = Color("#252b38")
		draw_rect(Rect2(Vector2(0, y_pos + TOP_MARGIN - CIRCLE_SIZE), Vector2(rect_size.x, CIRCLE_SIZE * 2.0)), rect_color)

		if layer.get_child_count() > 1:
			var base_item := layer.get_child(1) as EditorTimelineItemNote
			if base_item:
				var note_color := IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, base_item.data.note_type)) as Color
				var song_length_ms: int = int(editor.get_song_length() * 1000.0)

				
				for item in layer.get_children():
					if item is EditorTimelineItemNote:
						var data = item.data as HBBaseNote
						var pos = data.time / float(song_length_ms)
						
						# We draw the notes in the minimap, they are not squares
						# they match the height for easier viewing.
						for x in range(-1, 2):
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
	draw_texture(texture, Vector2.ZERO)
func _draw():
	_redraw_items()

func _on_time_cull_changed(cull_start_time, cull_end_time):
	var song_length_ms: int = int(editor.get_song_length() * 1000.0)
	if song_length_ms > 0:
		var pos = cull_start_time / float(song_length_ms)
		selection_rect.rect_position.x = rect_size.x * pos
		selection_rect.rect_size.x = rect_size.x * ((cull_end_time - cull_start_time) / float(song_length_ms))
		selection_rect.rect_size.y = rect_size.y

func _gui_input(event):
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			if event is InputEventMouseButton:
				if not event.button_index == BUTTON_LEFT:
					return
			var song_length_ms: int = int(editor.get_song_length() * 1000.0)
			var new_offset = (get_local_mouse_position().x / rect_size.x) * song_length_ms
			var cull_size = selection_rect.rect_size.x
			emit_signal("offset_changed", max(new_offset - (cull_size / rect_size.x * song_length_ms) / 2.0, 0))
