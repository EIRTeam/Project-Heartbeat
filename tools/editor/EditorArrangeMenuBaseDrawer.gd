extends Control

const INNER_RING_RADIUS = [29, 37]
const MIDDLE_RING_RADIUS = [44, 61]
const OUTER_RING_RADIUS = [61, 69]

func _draw():
	var color := Color.LIGHT_GRAY
	color.a = 0.8
	
	_draw_ring(INNER_RING_RADIUS[0], INNER_RING_RADIUS[1], color)
	_draw_ring(MIDDLE_RING_RADIUS[0], MIDDLE_RING_RADIUS[1], color)
	
	var inner_mode_info := {
		"mode": UserSettings.user_settings.editor_arrange_inner_mode,
		"subdivision": UserSettings.user_settings.editor_arrange_inner_subdivision,
		"snap": UserSettings.user_settings.editor_arrange_inner_snap,
		"diagonal_step": UserSettings.user_settings.editor_arrange_inner_diagonal_step,
		"vertical_step": UserSettings.user_settings.editor_arrange_inner_vstep,
	}
	var middle_mode_info := {
		"mode": UserSettings.user_settings.editor_arrange_middle_mode,
		"subdivision": UserSettings.user_settings.editor_arrange_middle_subdivision,
		"snap": UserSettings.user_settings.editor_arrange_middle_snap,
		"diagonal_step": UserSettings.user_settings.editor_arrange_middle_diagonal_step,
		"vertical_step": UserSettings.user_settings.editor_arrange_middle_vstep,
	}
	
	var inner_snaps := get_snaps(inner_mode_info)
	var middle_snaps := get_snaps(middle_mode_info)
	
	_draw_snaps(inner_snaps, INNER_RING_RADIUS[0] + 2, INNER_RING_RADIUS[1], Color.BLACK)
	_draw_snaps(middle_snaps, MIDDLE_RING_RADIUS[0] + 8, MIDDLE_RING_RADIUS[1], Color.BLACK)

func get_snaps(mode_info: Dictionary) -> Array:
	var snaps := []
	
	match mode_info.mode:
		HBUserSettings.EDITOR_ARRANGE_MODES.SUBDIVIDED:
			var diff: float = 360.0 / mode_info.subdivision
			
			for i in range(0, mode_info.subdivision):
				snaps.append(i * diff)
		HBUserSettings.EDITOR_ARRANGE_MODES.SINGLE_SNAP:
			snaps = [0, 90, 180, 270]
			
			snaps.append_array([mode_info.snap, 180 - mode_info.snap, 180 + mode_info.snap, 360 - mode_info.snap])
		HBUserSettings.EDITOR_ARRANGE_MODES.DUAL_SNAP:
			snaps = [0, 90, 180, 270]
			
			snaps.append_array([mode_info.snap, 180 - mode_info.snap, 180 + mode_info.snap, 360 - mode_info.snap])
			snaps.append_array([90 - mode_info.snap, 90 + mode_info.snap, 270 - mode_info.snap, 270 + mode_info.snap])
		HBUserSettings.EDITOR_ARRANGE_MODES.DISTANCE:
			snaps = [0, 90, 180, 270]
			
			var angle = rad_to_deg(Vector2.ZERO.angle_to_point(Vector2(mode_info.diagonal_step.x, mode_info.diagonal_step.y)))
			snaps.append_array([angle, 180 - angle, 180 + angle, 360 - angle])
		HBUserSettings.EDITOR_ARRANGE_MODES.FAKE_SLOPE:
			snaps = [0, 90, 180, 270]
			
			var angle = rad_to_deg(Vector2.ZERO.angle_to_point(Vector2(UserSettings.user_settings.editor_arrange_separation, mode_info.vertical_step)))
			snaps.append_array([angle, 180 - angle, 180 + angle, 360 - angle])
		HBUserSettings.EDITOR_ARRANGE_MODES.FREE:
			pass
	
	return snaps

func _draw_ring(radius_from: int, radius_to: int, color: Color):
	var n_points := 64
	var points_arc := PackedVector2Array()
	var colors := PackedColorArray([color])
	
	var angle_step := 2*PI / n_points
	
	for i in range(n_points + 1):
		var point = i * angle_step
		points_arc.push_back(Vector2(cos(point), sin(point)) * radius_from)
	
	for i in range(n_points, -1, -1):
		var point = i * angle_step
		points_arc.push_back(Vector2(cos(point), sin(point)) * radius_to)
	
	draw_polygon(points_arc, colors)

func _draw_snaps(snaps: Array, radius_from: int, radius_to: int, color: Color):
	var start := Vector2(radius_from, 0)
	var end := Vector2(radius_to, 0)
	
	for angle in snaps:
		draw_line(start.rotated(deg_to_rad(angle)), end.rotated(deg_to_rad(angle)), color)
