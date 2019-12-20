tool
extends Control

class_name HBEditorAxisGizmoArrow
var cap_size = 10
var hovering = false
enum DIRECTION {
	X,
	Y
}

signal dragged(relative_movement)

signal start_dragging
signal finish_dragging

export(DIRECTION) var direction = DIRECTION.Y
var fired_drag_start = false
func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	
func _input(event):
	if hovering:
		if event is InputEventMouseMotion and Input.is_action_pressed("editor_select"):
			if not fired_drag_start:
				emit_signal("start_dragging")
				fired_drag_start = true
			emit_signal("dragged", event.relative)

		if event.is_action_released("editor_select"):
			fired_drag_start = false
			emit_signal("finish_dragging")
	
func _on_mouse_entered():
	hovering = true
	update()
func _on_mouse_exited():
	hovering = false
	update()
	
func _draw_x_cap():
	var color = get_gizmo_color()
	var point1 = Vector2(rect_size.x + cap_size*3, rect_size.y/2)
	var point2 = Vector2(rect_size.x, -cap_size)
	var point3 = Vector2(rect_size.x, rect_size.y+cap_size)
	draw_colored_polygon(PoolVector2Array([point1, point2, point3]), color)
	
func _draw_y_cap():
	var color = get_gizmo_color()
	var point1 = Vector2(rect_size.x/2, -cap_size*3)
	var point2 = Vector2(0-cap_size, 0)
	var point3 = Vector2(rect_size.x+cap_size, 0)
	draw_colored_polygon(PoolVector2Array([point1, point2, point3]), color)
	
func get_gizmo_color():
	if hovering:
		return Color.yellow
	elif direction == DIRECTION.X:
		return Color.red
	else:
		return Color.green
	
func _draw():
	draw_rect(Rect2(Vector2(), rect_size), get_gizmo_color())
	if direction == DIRECTION.X:
		_draw_x_cap()
	else:
		_draw_y_cap()
