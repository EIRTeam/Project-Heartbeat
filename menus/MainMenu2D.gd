extends "res://menus/MainMenu.gd"

const SLIDE_PARTICLES = preload("res://graphics/effects/SlideParticles.tscn")

func _ready():
	super._ready()
	# We have to do this to force a shader compile beforehand because godot is
	# stupid
	var particles = SLIDE_PARTICLES.instantiate()
	add_child(particles)
	particles.emitting = true
	particles.position = Vector2(10000, 10000)
	HBGame.rich_presence.update_activity({
		"state": "On main menu"
	})

func menu_setup():
	fullscreen_menu_container = get_node("FullscreenMenuContainer")
	left_menu_container = get_node("MarginContainer/HBoxContainer/ContainerLeft")
	right_menu_container = get_node("MarginContainer/HBoxContainer/ContainerRight")
	first_background_texrect = get_node("CanvasLayer/Background1")
	second_background_texrect = get_node("CanvasLayer/Background2")
	background_transition_animation_player = get_node("CanvasLayer/AnimationPlayer")
	user_info_ui = right_menu_container.get_node("VBoxContainer/UserInfo")
	music_player_control = get_node("CanvasLayer2/MainMenuMusicPlayer")
	change_to_menu(starting_menu, false, starting_menu_args)
