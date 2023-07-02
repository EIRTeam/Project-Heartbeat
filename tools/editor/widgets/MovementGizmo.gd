@tool
extends Control

class_name HBEditorMovementGizmo

signal dragged(relative_movement)
signal start_dragging()
signal finished_dragging()

var hovering = false
func _draw():
	var border_color = Color.YELLOW
	if hovering:
		border_color = Color.RED
	border_color.a = 0.75
	
	draw_rect(Rect2(Vector2(0,0), size), border_color, false, 2.0)


func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	
func _input(event):
	if hovering:
		if event.is_action_pressed("editor_select") and not event.is_echo():
			emit_signal("start_dragging")
		if event is InputEventMouseMotion and Input.is_action_pressed("editor_select"):
			emit_signal("dragged", event.relative)
		if event.is_action_released("editor_select") and not event.is_echo():
			emit_signal("finish_dragging")

func finish_dragging():
	hovering = false

func _on_mouse_entered():
	hovering = true
	queue_redraw()
func _on_mouse_exited():
	hovering = false
	queue_redraw()
	
