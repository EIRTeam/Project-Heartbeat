extends Control

func disable_mouse_trap():
	mouse_filter = MOUSE_FILTER_IGNORE
	
func enable_mouse_trap():
	mouse_filter = MOUSE_FILTER_STOP
