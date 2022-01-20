extends HBSongListItemBase

class_name HBSongListItemRandom

var t = 0.0

var current_color := Color()

const YELLOW_STAR = preload("res://graphics/icons/menu_star.png")
const WHITE_STAR = preload("res://graphics/icons/menu_star_white.png")

func _ready():
	set_process(false)

func hover(no_animation = false):
	.hover(no_animation)
	set_process(true)
	$Control/TextureRect.texture = WHITE_STAR

func stop_hover(no_animation = false):
	.stop_hover(no_animation)
	set_process(false)
	$Control.self_modulate = Color.white
	$Control/TextureRect.self_modulate = Color.white
	$Control/TextureRect.texture = YELLOW_STAR

func _process(delta):
	t += delta
	current_color = current_color.from_hsv(fmod(t*0.25, 1), 1.0, 1.0)
	$Control.self_modulate = current_color
	$Control/TextureRect.self_modulate = current_color.inverted()

