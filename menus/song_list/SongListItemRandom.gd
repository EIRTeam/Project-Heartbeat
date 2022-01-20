extends HBSongListItemBase

class_name HBSongListItemRandom

var t = 0.0

var current_color := Color()

const YELLOW_STAR = preload("res://graphics/icons/menu_star.png")
const WHITE_STAR = preload("res://graphics/icons/menu_star_white.png")

func _ready():
	$Control/RainbowOverlay.hide()
	$Control/TextureRect/StarRainbow.hide()

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

