tool
extends HBEditorWidget
signal note_moved(new_pos)
signal note_moving_finished()
onready var movement_gizmo = get_node("MovementGizmo")
var internal_pos : Vector2
var starting_pos
var entry_angle = 0.0 setget set_entry_angle
var starting_entry_angle = 0.0
var show_angle = false
func set_entry_angle(val):
	entry_angle = val
	starting_entry_angle = val
	update()

func _ready():
	arrange_gizmo()
	get_viewport().connect("size_changed", self, "_on_resized")
	
func _on_resized():
	yield(get_tree(), "idle_frame")
	arrange_gizmo()
	
func arrange_gizmo():
	var note_scale = editor.rhythm_game.get_note_scale()
	movement_gizmo.rect_size = Vector2(128, 128) * note_scale
	movement_gizmo.rect_position = rect_size / 2 - movement_gizmo.rect_size/2
	internal_pos = rect_position
	
func _on_dragged(movement: Vector2):
	internal_pos += movement
#	emit_signal("note_moved", internal_pos)
	var snapped_pos = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(internal_pos + rect_size/2))
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
				editor._change_selected_property("entry_angle", rad2deg(entry_angle))
				show_angle = true
				update()
func _draw():
	if show_angle:
		var note_center = rect_size/2
		var rotated_n_v = Vector2.RIGHT.rotated(entry_angle - deg2rad(180))
		draw_line(note_center, note_center + rotated_n_v * 1000, Color.green)
func _on_start_dragging():
	internal_pos = rect_position

func _on_finish_dragging():
	editor._commit_selected_property_change("position")
