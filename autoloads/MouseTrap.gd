extends Control

onready var file_dialog : FileDialog = get_node("FileDialog")

func disable_mouse_trap():
	mouse_filter = MOUSE_FILTER_IGNORE
	
func enable_mouse_trap():
	mouse_filter = MOUSE_FILTER_STOP
