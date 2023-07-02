extends Control

@export var font: FontFile

func _show_notification(text: String):
	var label = Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	add_child(label)
	var tween = Threen.new()
	add_child(tween)
	label.custom_minimum_size.y = 50
	label.anchor_left = 0.05
	tween.interpolate_property(label, "modulate:a", 1.0, 0.0, 0.5, Threen.TRANS_LINEAR, Threen.EASE_OUT, 1.0)
	tween.interpolate_property(label, "anchor_bottom", 0.95, 0.75, 1.5, Threen.TRANS_LINEAR, Threen.EASE_IN_OUT)
	tween.connect("tween_all_completed", Callable(label, "queue_free"))
	tween.connect("tween_all_completed", Callable(tween, "queue_free"))
	tween.start()
