extends Control

signal start_pressed

func _unhandled_input(event):
	
	if event is InputEventKey or event is InputEventJoypadButton and event.button_index == JOY_SONY_X:
		if not event.pressed:
			return
		if event is InputEventJoypadButton:
			UserSettings.controller_device_idx = event.device
			UserSettings.controller_guid = Input.get_joy_guid(UserSettings.controller_device_idx)
			UserSettings.map_actions_to_controller()
		get_tree().set_input_as_handled()
#			$AnimationPlayer.play("FadeOut")
		emit_signal("start_pressed")
