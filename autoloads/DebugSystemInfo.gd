extends CanvasLayer

func _ready():
	$"Version Label".text = HBVersion.get_version_string()

func disable_label():
	$"Version Label".hide()
	$"Version Label".mouse_filter = Control.MOUSE_FILTER_PASS

func enable_label():
	$"Version Label".hide()
#	$"Version Label".mouse_filter = Control.MOUSE_FILTER_IGNORE
#	$"Version Label".show()
