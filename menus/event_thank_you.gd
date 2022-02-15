extends HBMenu

onready var tween_ty := Tween.new()

func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	add_child(tween_ty)
	$ColorRect.show()
	tween_ty.interpolate_property($ColorRect, "modulate:a", 1.0, 0.0, 1.0)
	tween_ty.start()
	tween_ty.connect("tween_all_completed", self, "_on_tween_all_completed", [], CONNECT_ONESHOT)

func _on_tween_all_completed():
	yield(get_tree().create_timer(UserSettings.user_settings.event_thank_you_duration), "timeout")
	tween_ty.reset_all()
	tween_ty.interpolate_property($ColorRect, "modulate:a", 0.0, 1.0, 1.0)
	tween_ty.start()
	tween_ty.connect("tween_all_completed", self, "change_to_menu", ["start_menu"], CONNECT_ONESHOT)
	
