tool
extends Control

class_name HBEditorRoundMovementGizmo

signal dragged(relative_movement)
signal finish_dragging()
var hovering = false
func _draw():
	var color = Color.white
	if hovering:
		color = Color.yellow
	draw_circle(rect_size/2, rect_size.x/2, color)


func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	
func _input(event):
	if hovering:
		if event is InputEventMouseMotion and Input.is_action_pressed("editor_select"):
			emit_signal("dragged", event.relative)
		if event.is_action_released("editor_select"):
			emit_signal("finish_dragging")
	
func _on_mouse_entered():
	hovering = true
	update()
func _on_mouse_exited():
	hovering = false
	update()
	
