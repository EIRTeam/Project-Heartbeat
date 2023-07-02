extends Control

@onready var sticks_container: HBoxContainer = get_node("%SticksContainer")
@onready var input_man: HeartbeatInputManager = get_node("%HeartbeatInputManager")
@onready var event_log: RichTextLabel = get_node("%EventLog")

const STICK_COUNT := 2
const STICK_HISTORY := 100

class StickInfo:
	var container: Control
	var last_joystick_inputs: PackedVector2Array
	var last_filtered_output: Vector2

var stick_infos: Array

var event_ids_processed_this_frame := []

func _input(event):
	var frame := Engine.get_frames_drawn()
	if event is InputEventHB:
		if not event.action in ["slide_left", "slide_right", "heart_note"]:
			return 
		if not event.event_uid in event_ids_processed_this_frame and event.pressed:
			event_ids_processed_this_frame.push_back(event.event_uid)
			HBGame.fire_and_forget_sound(UserSettings.user_sfx["slide_empty"], HBGame.sfx_group)
		event_log.add_text("[%d] %s main: %s Other: %s" % [frame, "Press" if event.pressed else "Release", event.action, event.actions])
		event_log.newline()
func _ready():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	for _stick in range(STICK_COUNT):
		var aspect_ratio_c := AspectRatioContainer.new()
		aspect_ratio_c.stretch_mode = AspectRatioContainer.STRETCH_HEIGHT_CONTROLS_WIDTH
		aspect_ratio_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c_rect := ColorRect.new()
		c_rect.color = Color(0.2, 0.2, 0.2)
		aspect_ratio_c.add_child(c_rect)
		var info := StickInfo.new()
		info.container = c_rect
		var pva := PackedVector2Array()
		pva.resize(STICK_HISTORY)
		info.last_joystick_inputs = pva
		sticks_container.add_child(aspect_ratio_c)
		stick_infos.push_back(info)
	queue_redraw()

func _draw_stick_debug(stick_idx: int):
	var info: StickInfo = stick_infos[stick_idx]
	var container: Control = stick_infos[stick_idx].container
	draw_set_transform_matrix(container.get_global_transform_with_canvas())

	var deadzone := input_man._get_action_deadzone("heart_note") as float
	var radius = container.size.x * 0.5
	var center := container.size * 0.5

	draw_arc(center, radius, 0, deg_to_rad(360), 30, Color.GRAY)
	draw_arc(center, radius * deadzone, 0, deg_to_rad(360), 30, Color.MEDIUM_PURPLE)
	var axis0 = Input.get_joy_axis(UserSettings.controller_device_idx, JOY_AXIS_0 + stick_idx * 2)
	var axis1 = Input.get_joy_axis(UserSettings.controller_device_idx, JOY_AXIS_1 + stick_idx * 2)
	var input := Vector2(axis0, axis1)
	var filtered_input := input
	var factor := UserSettings.user_settings.direct_joystick_filter_factor
	filtered_input = (filtered_input * factor) + (info.last_filtered_output * (1.0 - factor))
	var slide_angle := deg_to_rad(UserSettings.user_settings.direct_joystick_slider_angle_window)
	
	info.last_filtered_output = filtered_input
		
	for i in range(1, STICK_HISTORY):
		info.last_joystick_inputs[i-1] = info.last_joystick_inputs[i]
	info.last_joystick_inputs[STICK_HISTORY-1] = filtered_input
	
	draw_line(center, center + Vector2(radius, 0).rotated(-slide_angle * 0.5), Color.RED)
	draw_line(center, center + Vector2(radius, 0).rotated(slide_angle * 0.5), Color.RED)
	draw_line(center, center + Vector2(-radius, 0).rotated(-slide_angle * 0.5), Color.RED)
	draw_line(center, center + Vector2(-radius, 0).rotated(slide_angle * 0.5), Color.RED)

	var col := Color.GREEN

	for i in range(STICK_HISTORY-1):
		col.a = remap(i / float(STICK_HISTORY-2), 0.0, 1.0, 0.1, 0.9) * 0.5
		draw_circle(center + info.last_joystick_inputs[i] * radius, 4, col)

	draw_circle(center + input * radius, 4, Color.BLUE)
	draw_circle(center + filtered_input * radius, 4, Color.RED)

func _process(delta):
	event_ids_processed_this_frame.clear()
	input_man.flush_inputs()
	queue_redraw()
	input_man._frame_end()
func _draw():
	for stick in range(STICK_COUNT):
		_draw_stick_debug(stick)


var MainMenu = load("res://menus/MainMenu3D.tscn")
func _on_ReturnToMainMenuButton_pressed():
	var scene = MainMenu.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
