extends CanvasLayer
@onready var cache_song_overlay = get_node("MouseTrap/CacheSongOverlay")
@onready var ppd_dialog = get_node("MouseTrap/PPDDialog")
@onready var content_dir_dialog = get_node("MouseTrap/AddContentDirDialog")

func disable_mouse_trap():
	$MouseTrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func enable_mouse_trap():
	$MouseTrap.mouse_filter = Control.MOUSE_FILTER_STOP

func _ready():
	disable_mouse_trap()


func _on_Label_meta_clicked(meta):
	OS.shell_open(meta)
