extends Control

@onready var game_preview = get_node("../../../GamePreview")
@onready var game = get_node("../../RhythmGame")

const MULTI_TARGETS = [240, 720, 1200, 1680]

func _draw():
	var origin = Vector2.ZERO
	var size = game.playing_field_size
	var h_size = UserSettings.user_settings.editor_grid_resolution.x
	var v_size = UserSettings.user_settings.editor_grid_resolution.y
	var h_count = ceil(1080 / h_size)
	var v_count = ceil(1920 / v_size)
	
	var main_color = UserSettings.user_settings.editor_main_grid_color
	var main_width = UserSettings.user_settings.editor_main_grid_width
	var secondary_color = UserSettings.user_settings.editor_secondary_grid_color
	var secondary_width = UserSettings.user_settings.editor_secondary_grid_width
	var dashes = UserSettings.user_settings.editor_dashes_per_grid_space
	
	if UserSettings.user_settings.editor_grid_safe_area_only:
		var safe_area_rect = game_preview._get_safe_area_rect()
		origin = game_preview.SAFE_AREA_SIZE
		size = safe_area_rect.size
		h_count = ceil(game_preview.SAFE_AREA_SIZE.y / h_size * 8)
		v_count = ceil(game_preview.SAFE_AREA_SIZE.x / v_size * 8)
	
	if UserSettings.user_settings.editor_grid_type == 2:
		h_size /= UserSettings.user_settings.editor_grid_subdivisions + 1
		v_size /= UserSettings.user_settings.editor_grid_subdivisions + 1
		h_count *= UserSettings.user_settings.editor_grid_subdivisions + 1
		v_count *= UserSettings.user_settings.editor_grid_subdivisions + 1
	
	for i in range(h_count):
		var first_point = game.remap_coords(origin + Vector2(0, i * h_size))
		var second_point = first_point + Vector2(size.x, 0)
		
		match UserSettings.user_settings.editor_grid_type:
			0: # Full
				draw_line(first_point, second_point, main_color, main_width)
			1: # Dashed
				if i % 2 == 0:
					draw_line(first_point, second_point, main_color, main_width)
					
					for j in range(v_count):
						if j % 2:
							var dash_start = game.remap_coords(origin + Vector2(j * v_size, i * h_size))
							var dash_end = game.remap_coords(origin + Vector2(j * v_size, (i+2) * h_size))
							dash_end.y = min(dash_end.y, game.remap_coords(origin).y + size.y)
							
							_draw_dashed_line(dash_start, dash_end, dashes, secondary_color, secondary_width)
			2: # Subdivided
				if i % (UserSettings.user_settings.editor_grid_subdivisions + 1) == 0:
					draw_line(first_point, second_point, main_color, main_width)
				else:
					draw_line(first_point, second_point, secondary_color, secondary_width)
	
	for i in range(v_count):
		var first_point = game.remap_coords(origin + Vector2(i * v_size, 0))
		var second_point = first_point + Vector2(0, size.y)
		
		match UserSettings.user_settings.editor_grid_type:
			0: # Full
				draw_line(first_point, second_point, main_color, main_width)
			1: # Dashed
				if i % 2 == 0:
					draw_line(first_point, second_point, main_color, main_width)
					
					for j in range(h_count):
						if j % 2:
							var dash_start = game.remap_coords(origin + Vector2(i * v_size, j * h_size))
							var dash_end =  game.remap_coords(origin + Vector2((i+2) * v_size, j * h_size))
							dash_end.x = min(dash_end.x, game.remap_coords(origin).x + size.x)
							
							_draw_dashed_line(dash_start, dash_end, dashes, secondary_color, secondary_width)
			2: # Subdivided
				if i % (UserSettings.user_settings.editor_grid_subdivisions + 1) == 0:
					draw_line(first_point, second_point, main_color, main_width)
				else:
					draw_line(first_point, second_point, secondary_color, secondary_width)
	
	if UserSettings.user_settings.editor_multinote_crosses_enabled:
		for note_coord in MULTI_TARGETS:
			draw_cross(game.remap_coords(Vector2(note_coord, origin.y + ceil(h_count / 2.0) * h_size)))

func _draw_dashed_line(start: Vector2, end: Vector2, dashes_count: int, color: Color, width: float = 1.0):
	var length = start.distance_to(end)
	var dash_size = ceil(length / (dashes_count * 2)) + 1
	
	for i in range(dashes_count * 2):
		if i % 2 == 0:
			var dash_start = start
			var dash_end = start
			
			if start.x == end.x:
				dash_start.y += i * dash_size
				dash_end.y += (i+1) * dash_size
				dash_end.y = min(dash_end.y, end.y)
				if dash_start.y > end.y:
					continue
			else:
				dash_start.x += i * dash_size
				dash_end.x += (i+1) * dash_size
				dash_end.x = min(dash_end.x, end.x)
				if dash_start.x > end.x:
					continue
			
			draw_line(dash_start, dash_end, color, width)

func draw_cross(cross_center: Vector2):
	var height = (game.get_note_scale() * 100) / 2.0
	var cross_vertical_start = cross_center - Vector2(0, height)
	var cross_vertical_end = cross_center + Vector2(0, height)
	var cross_horizontal_start = cross_center - Vector2(height, 0)
	var cross_horizontal_end = cross_center + Vector2(height, 0)
	
	var color = UserSettings.user_settings.editor_multinote_cross_color
	var width = UserSettings.user_settings.editor_multinote_cross_width
	
	draw_line(cross_vertical_start, cross_vertical_end, color, width)
	draw_line(cross_horizontal_start, cross_horizontal_end, color, width)

func set_horizontal(value):
	UserSettings.user_settings.editor_grid_resolution.x = value
	UserSettings.user_settings.emit_signal("editor_grid_resolution_changed")
	queue_redraw()
func set_vertical(value):
	UserSettings.user_settings.editor_grid_resolution.y = value
	UserSettings.user_settings.emit_signal("editor_grid_resolution_changed")
	queue_redraw()

func get_grid_size():
	var grid_size = Vector2(UserSettings.user_settings.editor_grid_resolution.x, UserSettings.user_settings.editor_grid_resolution.y)
	if UserSettings.user_settings.editor_grid_type == 2:
		grid_size /= UserSettings.user_settings.editor_grid_subdivisions + 1
	
	return grid_size

func get_grid_offset():
	if UserSettings.user_settings.editor_grid_safe_area_only:
		var grid_size = get_grid_size()
		var grid_offset = game_preview.SAFE_AREA_SIZE
		
		grid_offset.x = fmod(grid_offset.x, grid_size.x)
		grid_offset.y = fmod(grid_offset.y, grid_size.y)
		
		return grid_offset
	else:
		return Vector2.ZERO
