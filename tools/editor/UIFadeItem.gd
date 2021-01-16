extends ColorRect

onready var tween = Tween.new()

func _ready():
	add_child(tween)
	obscure()
	show()

func obscure():
	tween.stop_all()
	tween.interpolate_property(self, "modulate:a", 0.0, 0.5, 0.1)
	tween.start()
	mouse_filter = Control.MOUSE_FILTER_STOP

func reveal():
	tween.stop_all()
	tween.interpolate_property(self, "modulate:a", 0.5, 0.0, 0.1)
	tween.start()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
