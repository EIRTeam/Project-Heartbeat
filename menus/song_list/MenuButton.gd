extends Button

class_name HeartbeatMenuButton

var target_scale = 1.0 setget set_target_scale


func _ready():
	set_process(false)

func set_target_scale(value):
	if target_scale != value:
		target_scale = value
		set_process(true)

func _process(delta: float):
	if target_scale != rect_scale.x:
		rect_scale = lerp(rect_scale, Vector2(target_scale, target_scale), 0.5)
	else:
		set_process(false)
