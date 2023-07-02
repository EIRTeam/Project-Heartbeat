extends ColorRect

@onready var tween = Threen.new()

func _ready():
	add_child(tween)
	obscure()
	show()

func obscure():
	tween.remove_all()
	tween.interpolate_property(self, "modulate:a", 0.0, 0.5, 0.1)
	tween.start()
	mouse_filter = Control.MOUSE_FILTER_STOP

func reveal():
	tween.remove_all()
	tween.interpolate_property(self, "modulate:a", 0.5, 0.0, 0.1)
	tween.start()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
