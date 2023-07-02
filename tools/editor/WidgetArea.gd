extends Control

signal widget_area_input(event)

func _gui_input(event):
	emit_signal("widget_area_input", event)
	get_viewport().set_input_as_handled()

func _clips_input():
	return true

func deselect_all():
	for widget in get_children():
		if widget is HBEditorNoteMovementWidget:
			widget.movement_gizmo.finish_dragging()
