extends Control

signal start_pressed

func _unhandled_input(event):
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton or event is InputEventAction:
		if event is InputEventKey or event is InputEventJoypadButton:
			if not event.pressed:
				return
		get_viewport().set_input_as_handled()
#			$AnimationPlayer.play("FadeOut")
		emit_signal("start_pressed")
