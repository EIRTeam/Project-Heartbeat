extends "res://menus/MainMenu.gd"
func _ready():
	# We have to do this to force a shader compile beforehand because godot is
	# stupid
	$SlideParticleCache.emitting = true

func menu_setup():
	fullscreen_menu_container = get_node("FullscreenMenuContainer")
	left_menu_container = get_node("ViewportLeft/MenuLeftContainer")
	right_menu_container = get_node("ViewportRight/MenuRightContainer")
	first_background_texrect = get_node("CanvasLayer/Background1")
	second_background_texrect = get_node("CanvasLayer/Background2")
	background_transition_animation_player = get_node("CanvasLayer/AnimationPlayer")
	change_to_menu(starting_menu, false, starting_menu_args)
