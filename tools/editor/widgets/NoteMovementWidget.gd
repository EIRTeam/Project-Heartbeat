tool
extends HBEditorWidget
onready var movement_gizmo = get_node("MovementGizmo")
var internal_pos : Vector2
var starting_pos
var drag_origin: Vector2
var entry_angle = 0.0 setget set_entry_angle
var starting_entry_angle = 0.0
var show_angle = false
var note_data: HBBaseNote setget set_note_data
var angle_color := Color.green
onready var texture_rect = get_node("TextureRect")

func set_entry_angle(val):
	entry_angle = val
	starting_entry_angle = val
	update()

func set_note_data(val):
	note_data = val
	texture_rect.texture = HBNoteData.get_note_graphic(note_data.note_type, "target")
	angle_color = ResourcePackLoader.get_note_trail_color(note_data.note_type)
	arrange_gizmo()
func _ready():
	get_viewport().connect("size_changed", self, "_on_resized")
	_on_resized()
	
func _on_resized():
	yield(get_tree(), "idle_frame")
	call_deferred("arrange_gizmo")
	
func arrange_gizmo():
	if note_data:
		var note_scale = editor.rhythm_game.get_note_scale()
		movement_gizmo.rect_size = texture_rect.texture.get_size() * note_scale
		movement_gizmo.rect_position = rect_size / 2 - movement_gizmo.rect_size/2
		texture_rect.rect_position = movement_gizmo.rect_position
		texture_rect.rect_size = movement_gizmo.rect_size
		internal_pos = rect_position
	
func _on_dragged(movement: Vector2):
	internal_pos += movement
	
	var snapped_pos = editor.snap_position_to_grid(
		editor.rhythm_game.inv_map_coords(internal_pos + rect_size/2),
		editor.rhythm_game.inv_map_coords(drag_origin + rect_size/2),
		Input.is_key_pressed(KEY_SHIFT)
	)
	
	editor._change_selected_property_delta("position", snapped_pos - starting_pos)
	rect_position = editor.rhythm_game.remap_coords(snapped_pos) - rect_size / 2

func _widget_area_input(event: InputEvent):
	if not get_tree().is_input_handled():
		if event is InputEventMouseButton:
			if event.is_action_released("editor_select"):
				get_tree().set_input_as_handled()
				editor._commit_selected_property_change("entry_angle")
				show_angle = false
	#			_on_timing_point_property_changed("entry_angle", )
		if event is InputEventMouseMotion:
			if Input.is_action_pressed("editor_select"):
				get_tree().set_input_as_handled()
				var note_center = rect_size/2
				entry_angle = note_center.angle_to_point(get_local_mouse_position())
				
				if Input.is_key_pressed(KEY_CONTROL):
					entry_angle /= PI / (editor.song_editor_settings.angle_snaps / 2.0)
					entry_angle = round(entry_angle) * (PI / (editor.song_editor_settings.angle_snaps / 2.0))
				
				editor._change_selected_property("entry_angle", rad2deg(entry_angle) - 180)
				show_angle = true
				update()
func _draw():
	if show_angle:
		var note_center = rect_size/2
		var rotated_n_v = Vector2.RIGHT.rotated(entry_angle)
		draw_line(note_center, note_center + rotated_n_v * 1000, angle_color, 3.0, true)
	# draw sine wave
	var sine_color = ResourcePackLoader.get_note_trail_color(note_data.note_type)
	sine_color.a = 0.75
	
	var trail_points = PoolVector2Array()
	trail_points.resize(editor.rhythm_game.TRAIL_RESOLUTION)
	
	for point_i in range(editor.rhythm_game.TRAIL_RESOLUTION):
		var n = point_i / float(editor.rhythm_game.TRAIL_RESOLUTION-1)
		var wave_point = HBUtils.calculate_note_sine(n, note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance)
		trail_points[point_i] = editor.rhythm_game.remap_coords(wave_point) - rect_position
		
	draw_polyline(trail_points, sine_color, 4.0, true)
	
func _on_start_dragging():
	drag_origin = rect_position

func _on_finish_dragging():
	editor._commit_selected_property_change("position")
