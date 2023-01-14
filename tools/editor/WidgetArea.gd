extends Control

signal widget_area_input(event)

func _gui_input(event):
	emit_signal("widget_area_input", event)
	get_tree().set_input_as_handled()

func _clips_input():
   return true
