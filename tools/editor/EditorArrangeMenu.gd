extends Popup

class_name HBEditorArrangeMenu

signal angle_changed(new_angle, reverse, autoangle_toggle)

@onready var clip_mask = get_node("Control")
@onready var arc_drawer = get_node("Control/Control")
@onready var reverse_indicator = get_node("Control/ReverseIndicator")

var editor : set = set_editor
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
		
		if Input.is_key_pressed(KEY_CTRL) != autoangle_toggle:
			autoangle_toggle = Input.is_key_pressed(KEY_CTRL)
			emit_signal("angle_changed", rotation, reverse, autoangle_toggle)
		
		if event is InputEventMouseMotion:
			var mouse_pos := get_viewport().get_mouse_position() - Vector2(120, 120)
			var mouse_distance := mouse_pos.distance_to(position)
			
			var new_rotation := rotation
			if mouse_distance > 10:
				new_rotation = mouse_pos.angle_to_point(position)
			
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
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad_to_deg(new_rotation))
					new_rotation = deg_to_rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.DUAL_SNAP:
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([mode_info.snap, -mode_info.snap, 180 - mode_info.snap, -180 + mode_info.snap])
					snap_list.append_array([90 - mode_info.snap, 90 + mode_info.snap, -90 + mode_info.snap, -90 - mode_info.snap])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad_to_deg(new_rotation))
					new_rotation = deg_to_rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.DISTANCE:
					var angle = -rad_to_deg(Vector2.ZERO.angle_to_point(Vector2(mode_info.diagonal_step.x, mode_info.diagonal_step.y)))
					
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([angle, -angle, 180 - angle, -180 + angle])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad_to_deg(new_rotation))
					new_rotation = deg_to_rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.FAKE_SLOPE:
					var angle = -rad_to_deg(Vector2.ZERO.angle_to_point(Vector2(-UserSettings.user_settings.editor_arrange_separation, mode_info.vertical_step)))
					
					var snap_list := [0, 90, 180, -90]
					snap_list.append_array([angle, -angle, 180 - angle, -180 + angle])
					snap_list.sort()
					
					var new_rotation_idx = HBUtils.bsearch_closest(snap_list, rad_to_deg(new_rotation))
					new_rotation = deg_to_rad(snap_list[new_rotation_idx])
				HBUserSettings.EDITOR_ARRANGE_MODES.FREE:
					pass
			
			if new_rotation != rotation:
				emit_signal("angle_changed", new_rotation, reverse, autoangle_toggle)
			
			rotation = new_rotation
			set_process(true)
	else:
		rotation = 0.0

func _process(delta):
	var parent = get_parent()
	clip_mask.position = Vector2.ZERO
	clip_mask.size = Vector2(240, 240)
	
	var clip = clip_mask.get_global_rect().intersection(parent.get_global_rect())
	
	clip_mask.global_position = clip.position
	clip_mask.size = clip.size
	
	$Control/Control2.position = Vector2(120, 120) - clip_mask.position
	arc_drawer.position = Vector2(120, 120) - clip_mask.position
	reverse_indicator.position = Vector2(161, 169) - clip_mask.position
	
	if visible:
		var mouse_pos := get_viewport().get_mouse_position() - Vector2(120, 120)
		arc_drawer.mouse_distance = mouse_pos.distance_to(position)
		arc_drawer.arc_rotation = rotation
		arc_drawer.queue_redraw()
	set_process(false)
func get_angle():
	return rotation

func set_editor(_editor):
	editor = _editor
