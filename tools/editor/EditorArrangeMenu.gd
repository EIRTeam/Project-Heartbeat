extends Popup

class_name HBEditorArrangeMenu

signal angle_changed(new_angle, reverse, autoangle_toggle)

onready var clip_mask = get_node("Control")
onready var arc_drawer = get_node("Control/Control")
onready var reverse_indicator = get_node("Control/ReverseIndicator")

var editor setget set_editor
var rotation := 0.0 # In radians
var reverse := false
var autoangle_toggle := false

var mode_info := {
	"mode": UserSettings.user_settings.editor_arrange_inner_mode,
	"subdivision": UserSettings.user_settings.editor_arrange_inner_subdivision,
	"snap": UserSettings.user_settings.editor_arrange_inner_snap,
	"diagonal_step": UserSettings.user_settings.editor_arrange_inner_diagonal_step,
	"vertical_step": UserSettings.user_settings.editor_arrange_inner_vstep,
}

func _input(event):
	if visible:
		if Input.is_key_pressed(KEY_SHIFT) != reverse:
			reverse = Input.is_key_pressed(KEY_SHIFT)
			reverse_indicator.visible = reverse
			emit_signal("angle_changed", rotation, reverse, autoangle_toggle)
		
		if Input.is_key_pressed(KEY_CONTROL) != autoangle_toggle:
			autoangle_toggle = Input.is_key_pressed(KEY_CONTROL)
			emit_signal("angle_changed", rotation, reverse, autoangle_toggle)
		
		if event is InputEventMouseMotion:
			var mouse_pos := get_global_mouse_position() - Vector2(120, 120)
			var mouse_distance := mouse_pos.distance_to(rect_position)
			
			var new_rotation := rotation
			if mouse_distance > 10:
				new_rotation = mouse_pos.angle_to_point(rect_position)
			
			mode_info = {
				"mode": UserSettings.user_settings.editor_arrange_inner_mode,
				"subdivision": UserSettings.user_settings.editor_arrange_inner_subdivision,
				"snap": UserSettings.user_settings.editor_arrange_inner_snap,
				"diagonal_step": UserSettings.user_settings.editor_arrange_inner_diagonal_step,
				"vertical_step": UserSettings.user_settings.editor_arrange_inner_vstep,
			}
			
			if mouse_distance > 70:
				mode_info = {
					"mode": UserSettings.user_settings.editor_arrange_outer_mode,
					"subdivision": UserSettings.user_settings.editor_arrange_outer_subdivision,
					"snap": UserSettings.user_settings.editor_arrange_outer_snap,
					"diagonal_step": UserSettings.user_settings.editor_arrange_outer_diagonal_step,
					"vertical_step": UserSettings.user_settings.editor_arrange_outer_vstep,
				}
			elif mouse_distance > 44:
				mode_info = {
					"mode": UserSettings.user_settings.editor_arrange_middle_mode,
					"subdivision": UserSettings.user_settings.editor_arrange_middle_subdivision,
					"snap": UserSettings.user_settings.editor_arrange_middle_snap,
					"diagonal_step": UserSettings.user_settings.editor_arrange_middle_diagonal_step,
					"vertical_step": UserSettings.user_settings.editor_arrange_middle_vstep,
				}
			
			match mode_info.mode:
				HBUserSettings.EDITOR_ARRANGE_MODES.SUBDIVIDED:
					new_rotation /= PI / (mode_info.subdivision / 2.0)
					new_rotation = round(new_rotation) * (PI / (mode_info.subdivision / 2.0))
				HBUserSettings.EDITOR_ARRANGE_MODES.SINGLE_SNAP:
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([mode_info.snap, -mode_info.snap, 180 - mode_info.snap, -180 + mode_info.snap])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad2deg(new_rotation))
					new_rotation = deg2rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.DUAL_SNAP:
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([mode_info.snap, -mode_info.snap, 180 - mode_info.snap, -180 + mode_info.snap])
					snap_list.append_array([90 - mode_info.snap, 90 + mode_info.snap, -90 + mode_info.snap, -90 - mode_info.snap])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad2deg(new_rotation))
					new_rotation = deg2rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.DISTANCE:
					var angle = -rad2deg(Vector2.ZERO.angle_to_point(Vector2(mode_info.diagonal_step.x, mode_info.diagonal_step.y)))
					
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([angle, -angle, 180 - angle, -180 + angle])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad2deg(new_rotation))
					new_rotation = deg2rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.FAKE_SLOPE:
					var angle = -rad2deg(Vector2.ZERO.angle_to_point(Vector2(-UserSettings.user_settings.editor_arrange_separation, mode_info.vertical_step)))
					
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([angle, -angle, 180 - angle, -180 + angle])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad2deg(new_rotation))
					new_rotation = deg2rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.FREE:
					pass
			
			if new_rotation != rotation:
				emit_signal("angle_changed", new_rotation, reverse, autoangle_toggle)
			
			rotation = new_rotation
			update()
	else:
		rotation = 0.0

func _draw():
	var parent = get_parent_control()
	clip_mask.rect_position = Vector2.ZERO
	clip_mask.rect_size = Vector2(240, 240)
	
	var clip = clip_mask.get_global_rect().clip(parent.get_global_rect())
	
	clip_mask.rect_global_position = clip.position
	clip_mask.rect_size = clip.size
	
	$Control/Control2.rect_position = Vector2(120, 120) - clip_mask.rect_position
	arc_drawer.rect_position = Vector2(120, 120) - clip_mask.rect_position
	reverse_indicator.rect_position = Vector2(161, 169) - clip_mask.rect_position
	
	if visible:
		var mouse_pos := get_global_mouse_position() - Vector2(120, 120)
		arc_drawer.mouse_distance = mouse_pos.distance_to(rect_position)
		arc_drawer.rotation = rotation
		arc_drawer.update()

func get_angle():
	return rotation

func set_editor(_editor):
	editor = _editor
