extends CanvasLayer

onready var file_dialog : FileDialog = get_node("MouseTrap/FileDialog")
onready var cache_song_overlay = get_node("MouseTrap/CacheSongOverlay")
func disable_mouse_trap():
	$MouseTrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func enable_mouse_trap():
	$MouseTrap.mouse_filter = Control.MOUSE_FILTER_STOP
