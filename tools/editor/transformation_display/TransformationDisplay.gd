extends Control

# Transformation is a dict that maps note_type:transformation dict
# transformation dict contains keys that match properties in notedata
var transformation: EditorTransformation

# map of note_type:notedata
var notes_to_transform = {}

var angle_line_2ds = []

var multi_lasers = []

const TRAIL_RESOLUTION = 60

var game

var hide_timer: Timer

@onready var background_color_rect = get_node("ColorRect")

func _ready():
	hide_timer = Timer.new()
	hide_timer.wait_time = 0.1
	hide_timer.connect("timeout", Callable(self, "hide"))
	add_child(hide_timer)
	
	hide()
	var angle_line_2d = Line2D.new()
	
	angle_line_2d.texture = preload("res://tools/editor/transformation_display/angle_display.svg")
	angle_line_2d.width = 25
	angle_line_2d.texture_mode = Line2D.LINE_TEXTURE_TILE
	angle_line_2d.show_behind_parent = true
	for _i in range(10):
		var l2 = angle_line_2d.duplicate() as Line2D
		add_child(l2)
		l2.hide()
		var points = PackedVector2Array()
		points.resize(2)
		l2.points = points
		angle_line_2ds.append(l2)
	angle_line_2d.queue_free()

func get_transformed_value(note, transformation_map, property_name: String):
	var value
	value = note.get(property_name)
	
	if property_name in transformation_map[note]:
		value = transformation_map[note][property_name]
	else:
		value = note.get(property_name)
	return value
func get_note_scale():
	if game:
		return game.get_note_scale()
	return 1.0

func remap_coords(pos: Vector2):
	if game:
		return game.remap_coords(pos)
	return pos

var center

func _point_sort(a, b):
	if (a.x - center.x >= 0 && b.x - center.x < 0):
		return true;
	if (a.x - center.x < 0 && b.x - center.x >= 0):
		return false;
	if (a.x - center.x == 0 && b.x - center.x == 0):
		if (a.y - center.y >= 0 || b.y - center.y >= 0):
			return a.y > b.y
		return b.y > a.y

	# compute the cross product of vectors (center -> a) x (center -> b)
	var det = (a.x - center.x) * (b.y - center.y) - (b.x - center.x) * (a.y - center.y)
	if (det < 0):
		return true
	if (det > 0):
		return false

	# points a and b are on the same line from the center
	# check which point is closer to the center
	var d1 = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y)
	var d2 = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y)
	return d1 > d2

func _draw_note_graphic(center_pos: Vector2, note_type: int, target_graphic: String, note_modulate = Color.WHITE):
	var texture = HBNoteData.get_note_graphic(note_type, target_graphic) as Texture2D
	var note_texture_size = texture.get_size() * get_note_scale()
	var draw_pos = center_pos - note_texture_size / 2.0
	
	draw_texture_rect(texture, Rect2(draw_pos, note_texture_size), false, note_modulate)
	# draw timing arm
	var timing_arm_texture = ResourcePackLoader.get_graphic("timing_arm.png")
	var timing_arm_texture_size = timing_arm_texture.get_size() * get_note_scale()
	var timing_arm_draw_pos = center_pos - Vector2(timing_arm_texture_size.x / 2.0 + 2 * get_note_scale(), timing_arm_texture_size.y - (31 * get_note_scale()))
	draw_texture_rect(timing_arm_texture, Rect2(timing_arm_draw_pos, timing_arm_texture_size), false, note_modulate)

func _create_laser(scale_x):
	var laser = preload("res://rythm_game/Laser.tscn").instantiate()
	laser.width_scale = scale_x
	return laser

func _draw_transformation():
	var transformation_map = transformation.transform_notes(notes_to_transform)

	var scale_x = (remap_coords(Vector2(1.0, 1.0)) - remap_coords(Vector2.ZERO)).x
	
	var trail_points = PackedVector2Array()
	trail_points.resize(TRAIL_RESOLUTION)
	
	for line in angle_line_2ds:
		line.hide()
	
	var found_note_types = []

	var i = 0

	for laser in multi_lasers:
		laser.queue_free()
		
	multi_lasers = []
	
	var note_groups = {}
	for note_to_transform in transformation_map:
		if not note_to_transform.time in note_groups:
			note_groups[note_to_transform.time] = 0
		
		note_groups[note_to_transform.time] += 1
	
	for note_to_transform in transformation_map:
		var note_type = get_transformed_value(note_to_transform, transformation_map, "note_type")
		var target_graphic = "target"

		var is_multi = note_groups[note_to_transform.time] > 1
		
		if is_multi:
			target_graphic = "multi_note_target"
		
		found_note_types.append(note_to_transform.note_type)

		var entry_angle = get_transformed_value(note_to_transform, transformation_map, "entry_angle")
		var note_position = get_transformed_value(note_to_transform, transformation_map, "position")
		var note_frequency = get_transformed_value(note_to_transform, transformation_map, "oscillation_frequency")
		var note_amplitude = get_transformed_value(note_to_transform, transformation_map, "oscillation_amplitude")
		var note_distance = get_transformed_value(note_to_transform, transformation_map, "distance")
		var note_center_pos = remap_coords(get_transformed_value(note_to_transform, transformation_map, "position"))
		
		if i < angle_line_2ds.size():
			var l2 = angle_line_2ds[i] as Line2D
			l2.points[0] = note_center_pos
			
			var distance = get_transformed_value(note_to_transform, transformation_map, "distance")
			
			var p = Vector2(distance, 0)
			p = p.rotated(deg_to_rad(entry_angle))
			l2.points[1] = note_center_pos + p
			
			l2.default_color = ResourcePackLoader.get_note_trail_color(note_type)
			l2.default_color.a = 0.75
			l2.width = 25*get_note_scale()
			l2.show()
		
		# draw sine wave
		var sine_color = ResourcePackLoader.get_note_trail_color(note_type)
		sine_color.a = 0.75
		
		for point_i in range(TRAIL_RESOLUTION):
			var n = point_i / float(TRAIL_RESOLUTION-1)
			var wave_point = HBUtils.calculate_note_sine(n, note_position, entry_angle, note_frequency, note_amplitude, note_distance)
			trail_points[point_i] = remap_coords(wave_point)
			
		draw_polyline(trail_points, sine_color, 4.0, true)

		var note_modulate = Color.WHITE

		if not note_to_transform in notes_to_transform:
			note_modulate = Color(0.75, 0.75, 0.75)
		_draw_note_graphic(note_center_pos, note_type, target_graphic, note_modulate)
		if i > 0:
			var make_multi_laser = true
			if i < transformation_map.size() - 1:
				var next_note = transformation_map.keys()[i+1] as HBBaseNote
				if next_note.time == note_to_transform.time:
					make_multi_laser = false
			if make_multi_laser:
				var prev_note = transformation_map.keys()[i-1] as HBBaseNote
				if prev_note.time == note_to_transform.time:
					var positions = []
					for ii in range(i, -1, -1):
						var multi_note = transformation_map.keys()[ii] as HBBaseNote
						if multi_note.time != note_to_transform.time:
							break
						positions.append(remap_coords(get_transformed_value(multi_note, transformation_map, "position")))
					
					center = Vector2.ZERO
					for point in positions:
						center += point
					center /= float(positions.size())
					
					positions.sort_custom(Callable(self, "_point_sort"))
					positions.append(positions[0])
					var laser = _create_laser(scale_x)
					$ColorRect.add_sibling(laser)
					laser.show_behind_parent = true
					laser.positions = positions
					multi_lasers.append(laser)
					
					
		i += 1
func _draw():
	_draw_transformation()

func _hide():
	hide_timer.start()
