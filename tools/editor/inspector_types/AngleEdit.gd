tool
extends Control

export(float)var angle = 0 setget set_angle

signal angle_changed(angle)

func set_angle(value):
	angle = value
	emit_signal("angle_changed", angle)
	update()

func _gui_input(event):
	if not Engine.editor_hint:
		if Input.is_action_pressed("editor_select"):
			var center = rect_size / 2
			set_angle(round(rad2deg(center.angle_to_point(get_local_mouse_position())) - 180))
			get_tree().set_input_as_handled()

func _draw():
	var center = rect_size / 2
	var radius = min(rect_size.y, rect_size.x) / 2
	
	draw_circle(center, radius, Color.black)
	draw_line(center, center + Vector2.RIGHT.rotated(deg2rad(angle)) * radius, Color.white)
