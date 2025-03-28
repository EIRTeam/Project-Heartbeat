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
	HBGame.rich_presence.notify_at_main_menu()
	
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	_on_viewport_size_changed()
	UserSettings.enable_menu_fps_limits = true
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	
func _on_viewport_size_changed():
	# this scales shit for more squareish resolutions, it's a bit hacky so you might need
	# to adjust the 0.90 magic number
	var default_169 = 16/9.0
	var ratio: float = get_viewport().size.x / float(get_viewport().size.y)
	%MenuCamera.fov = 47.0 * max(default_169/ratio, 0.90)
	
	var scaling: Vector3 = max(1.0/(ratio/default_169), 1.0) * Vector3.ONE
	%LeftMenu.scale = scaling
	%RightMenu.scale = scaling
func menu_setup():
	fullscreen_menu_container = get_node("FullscreenMenuContainer")
	left_menu_container = %LeftMenu.get_node("CanvasLayer3D/MenuLeftContainer")
	right_menu_container = %RightMenu.get_node("CanvasLayer3D/MenuRightContainer/VBoxContainer/Control")
	first_background_texrect = get_node("CanvasLayer/Background1")
	second_background_texrect = get_node("CanvasLayer/Background2")
	background_transition_animation_player = get_node("CanvasLayer/AnimationPlayer")
	user_info_ui = right_menu_container.get_node("../UserInfo")
	music_player_control = get_node("CanvasLayer2/MainMenuMusicPlayer")
	visualizer = get_node("CanvasLayer/MainMenuVisualizer2")
	bar_visualizer = get_node("CanvasLayer/AspectRatioContainer/Control")
	change_to_menu(starting_menu, false, starting_menu_args)
