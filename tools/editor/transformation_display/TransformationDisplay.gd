extends Control

# Transformation is a dict that maps note_type:transformation dict
# transformation dict contains keys that match properties in notedata
var transformation = {}

# map of note_type:notedata
var notes_to_transform = {}

var angle_line_2ds = []

onready var multi_laser = get_node("Laser")

const TRAIL_RESOLUTION = 60

var game

onready var background_color_rect = get_node("ColorRect")

func _ready():
	hide()
	var angle_line_2d = Line2D.new()
	
	angle_line_2d.texture = preload("res://tools/editor/transformation_display/angle_display.svg")
	angle_line_2d.width = 25
	angle_line_2d.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	for _i in range(10):
		var l2 = angle_line_2d.duplicate() as Line2D
		add_child(l2)
		l2.hide()
		var points = PoolVector2Array()
		points.resize(2)
		l2.points = points
		angle_line_2ds.append(l2)

func get_transformed_value(note_type, property_name: String):
	var value
	if note_type in notes_to_transform:
		value = notes_to_transform[note_type].get(property_name)
	else:
		value = HBBaseNote.new().get(property_name)
	if property_name in transformation[note_type]:
		value = transformation[note_type][property_name]
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

func _draw_transformation():
	var is_multi = transformation.size() > 1
	var scale_x = (remap_coords(Vector2(1.0, 1.0)) - remap_coords(Vector2.ZERO)).x
	
	if is_multi:
		multi_laser.width_scale = scale_x
	
	var laser_positions = PoolVector2Array()
	laser_positions.resize(transformation.size())
	
	var trail_points = PoolVector2Array()
	trail_points.resize(TRAIL_RESOLUTION)
	
	for line in multi_laser.line_2ds:
		line.free()
	multi_laser.line_2ds = []
	
	for line in angle_line_2ds:
		line.hide()
	
	for i in range(transformation.size()):
		var note_type = transformation.keys()[i]
		
		var target_graphic = "target"

		if is_multi:
			target_graphic = "multi_note_target"
		
		var texture = HBNoteData.get_note_graphic(note_type, target_graphic) as Texture
		var note_texture_size = texture.get_size() * get_note_scale()
		var note_center_pos = remap_coords(get_transformed_value(note_type, "position"))
		var draw_pos = note_center_pos - note_texture_size / 2.0
		
		var entry_angle = get_transformed_value(note_type, "entry_angle")
		var note_position = get_transformed_value(note_type, "position")
		var note_frequency = get_transformed_value(note_type, "oscillation_frequency")
		var note_amplitude = get_transformed_value(note_type, "oscillation_amplitude")
		var note_distance = get_transformed_value(note_type, "distance")
		
		if i < angle_line_2ds.size():
			var l2 = angle_line_2ds[i] as Line2D
			l2.points[0] = note_center_pos
			var distance = get_transformed_value(note_type, "distance")
			var p = remap_coords(Vector2(distance, 0))
			p = p.rotated(deg2rad(entry_angle))
			l2.points[1] = note_center_pos + p
			l2.default_color = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_type))
			l2.default_color.a = 0.75
			l2.width = 25*get_note_scale()
			l2.show()
		# draw sine wave
		
		var sine_color = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_type))
		sine_color.a = 0.75
		
		for point_i in range(TRAIL_RESOLUTION):
			var n = point_i / float(TRAIL_RESOLUTION-1)
			var wave_point = HBUtils.calculate_note_sine(n, note_position, entry_angle, note_frequency, note_amplitude, note_distance)
			trail_points[point_i] = remap_coords(wave_point)
			
		draw_polyline(trail_points, sine_color, 4.0, true)
		# draw note
		var note_modulate = Color(0.5, 0.5, 0.5, 1.0)
		
		for note_to_transform_type in notes_to_transform:
			if note_to_transform_type == note_type:
				note_modulate = Color.white
				break
		
		draw_texture_rect(texture, Rect2(draw_pos, note_texture_size), false, note_modulate)
		# draw timing arm
		var timing_arm_texture = IconPackLoader.timing_arm_atlas
		var timing_arm_texture_size = timing_arm_texture.get_size() * get_note_scale()
		var timing_arm_draw_pos = note_center_pos - Vector2(timing_arm_texture_size.x / 2.0 + 2 * get_note_scale(), timing_arm_texture_size.y - (31 * get_note_scale()))
		draw_texture_rect(timing_arm_texture, Rect2(timing_arm_draw_pos, timing_arm_texture_size), false, note_modulate)
		
		laser_positions[i] = note_center_pos
	if is_multi:
		center = Vector2.ZERO
		for point in laser_positions:
			center += point
		center /= float(laser_positions.size())
		var positions = Array(laser_positions)
		positions.sort_custom(self, "_point_sort")
		positions.append(positions[0])
		multi_laser.positions = positions
		multi_laser.show()
	else:
		multi_laser.hide()
func _draw():
	_draw_transformation()