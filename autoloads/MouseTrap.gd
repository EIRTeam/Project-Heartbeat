extends CanvasLayer
@onready var cache_song_overlay = get_node("MouseTrap/CacheSongOverlay")
@onready var ppd_dialog = get_node("MouseTrap/PPDDialog")
@onready var content_dir_dialog = get_node("MouseTrap/AddContentDirDialog")
@onready var wrong_timezone_confirmation_window: HBConfirmationWindow = get_node("%WrongTimezoneConfirmationWindow")

var last_focus_before_wrong_timezone_window: Control

func disable_mouse_trap():
	$MouseTrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func enable_mouse_trap():
	$MouseTrap.mouse_filter = Control.MOUSE_FILTER_STOP

func show_wrong_timezone_window():
	last_focus_before_wrong_timezone_window = get_window().gui_get_focus_owner()
	wrong_timezone_confirmation_window.popup_centered()

func _ready():
	disable_mouse_trap()
	HBBackend.wrong_timezone_detected.connect(self.queue_show_wrong_timezone_window)
	wrong_timezone_confirmation_window.accept.connect(
		func():
			if last_focus_before_wrong_timezone_window:
				last_focus_before_wrong_timezone_window.grab_focus()
	)


func _on_Label_meta_clicked(meta):
	OS.shell_open(meta)
