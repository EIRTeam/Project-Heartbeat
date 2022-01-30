extends HBSongListItemBase

class_name HBSongListItemRandom

var t = 0.0

var current_color := Color()

func _ready():
	stop_hover()

func hover(no_animation = false):
	.hover(no_animation)
	$Control/RainbowOverlay.show()
	$Control/TextureRect/StarRainbow.show()
	$Control.self_modulate.a = 0.0

func stop_hover(no_animation = false):
	.stop_hover(no_animation)
	$Control/RainbowOverlay.hide()
	$Control/TextureRect/StarRainbow.hide()
	$Control.self_modulate.a = 1.0

