extends Panel

signal resumed

func _ready():
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	hide()
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.hide()
	connect("resumed", self, "_on_resumed")
	
func _on_resumed():
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.hide()
func _on_viewport_size_changed():
	$ViewportContainer/Viewport.size = OS.window_size

#func _input(event):
#	$Viewport.input(event)

func show_pause():
	show()
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.show()
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.grab_focus()
