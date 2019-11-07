extends Control

signal start_pressed

func _unhandled_input(event):
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if $AnimationPlayer.current_animation != "FadeOut":
			$AnimationPlayer.play("FadeOut")
			emit_signal("start_pressed")
			get_tree().set_input_as_handled()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "FadeOut":
		queue_free()
