extends Control

export(DynamicFont) var font

func _show_notification(text: String):
	var label = Label.new()
	label.text = text
	label.set_anchors_and_margins_preset(Control.PRESET_BOTTOM_LEFT)
	label.valign = Label.VALIGN_CENTER
	label.add_font_override("font", font)
	add_child(label)
	var tween = Tween.new()
	add_child(tween)
	label.rect_min_size.y = 50
	label.anchor_left = 0.05
	tween.interpolate_property(label, "modulate:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT, 1.0)
	tween.interpolate_property(label, "anchor_bottom", 0.95, 0.75, 1.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.connect("tween_all_completed", label, "queue_free")
	tween.connect("tween_all_completed", tween, "queue_free")
	tween.start()
