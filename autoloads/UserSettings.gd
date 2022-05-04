extends Node

var user_settings: HBUserSettings = HBUserSettings.new()

const USER_SETTINGS_PATH = "user://user_settings.json"
const LOG_NAME = "UserSettings"
var base_input_map = {}

var CUSTOM_SOUND_PATH = "user://custom_sounds" setget , _get_custom_sounds_path

var debounce_timer = Timer.new()
# when in controller mode, this counts down to hide the mouse
var mouse_hide_timer = Timer.new()

func _get_custom_sounds_path():
	return HBGame.platform_settings.user_dir_redirect(CUSTOM_SOUND_PATH)

signal controller_swapped(to_device)

var ACTION_CATEGORIES = {}

var action_names = {}

var axis_names = []

var button_names = []

const HIDE_KB_REMAPS_ACTIONS = [
	"gui_up",
	"gui_down",
	"gui_left",
	"gui_right",
	"gui_accept",
	"gui_cancel"
]

const DISABLE_ANALOG_FOR_ACTION = [
	"gui_accept",
	"gui_cancel",
	"gui_up",
	"gui_down",
	"gui_left",
	"gui_right",
]

var controller_device_idx = -1

var controller_guid := ""

const MOUSE_HIDE_TIME = 0.5

func _ready():
	add_child(debounce_timer)
	debounce_timer.wait_time = 1.0
	debounce_timer.one_shot = true
	debounce_timer.connect("timeout", self, "_save_user_settings")

	add_child(mouse_hide_timer)
	mouse_hide_timer.connect("timeout", Input, "set_mouse_mode", [Input.MOUSE_MODE_HIDDEN])
	# Godot simulates joy connections on startup, this makes sure we skip them

func _on_joy_connection_changed(device_idx: int, is_connected: bool):
#	TODO: This hangs the game, why? God knows
#	if controller_device_idx != -1:
#		# fallback to controller 0
#		if is_connected and Input.get_joy_guid(device_idx) == controller_guid:
#			print("Known controller reconnected, remapping...")
#			map_actions_to_controller()
	if Input.get_connected_joypads().size() == 0:
		current_mode = PROMPT_MODE.KEYBOARD

func get_input_map():
	var map = {}
	for action_name in InputMap.get_actions():
		if action_name in action_names:
			map[action_name] = []
			for event in InputMap.get_action_list(action_name):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventKey:
					map[action_name].append(event)
	return map
func _init_user_settings():
	load_user_settings()
	
	fill_localized_arrays()
	
	# Translation init
	if user_settings.locale != "auto-detect":
		TranslationServer.set_locale(user_settings.locale)
	
	base_input_map = get_input_map()

	# Correct switch default mapping
	if OS.get_name() == "Switch":
		for action_name in base_input_map:
			if action_name in ["gui_accept", "gui_cancel"]:
				for event in base_input_map[action_name]:
					if event is InputEventJoypadButton:
						if event.button_index == JOY_SONY_X:
							event.button_index = JOY_SONY_CIRCLE
						elif event.button_index == JOY_SONY_CIRCLE:
							event.button_index = JOY_SONY_X
	print("Shinobu: Setting buffer size to %d ms" % [user_settings.audio_buffer_size])
	ShinobuGodot.buffer_size = user_settings.audio_buffer_size
	ShinobuGodot.initialize()

	apply_user_settings(true)
	load_input_map()
	set_joypad_prompts()
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")


func fill_localized_arrays():
	button_names = [
		tr("DualShock Cross, Xbox A, Nintendo B"),
		tr("DualShock Circle, Xbox B, Nintendo A"),
		tr("DualShock Square, Xbox X, Nintendo Y"),
		tr("DualShock Triangle, Xbox Y, Nintendo X"),
		"L, L1",
		"R, R1",
		"L2",
		"R2",
		"L3",
		"R3",
		tr("Select, DualShock Share, Nintendo -"),
		tr("Start, DualShock Options, Nintendo +"),
		tr("D-Pad Up"),
		tr("D-Pad Down"),
		tr("D-Pad Left"),
		tr("D-Pad Right")
	]
	
	axis_names = [
		tr(" (Left Stick Left)"),
		tr(" (Left Stick Right)"),
		tr(" (Left Stick Up)"),
		tr(" (Left Stick Down)"),
		tr(" (Right Stick Left)"),
		tr(" (Right Stick Right)"),
		tr(" (Right Stick Up)"),
		tr(" (Right Stick Down)"),
		"", "", "", "",
		"", " (L2)",
		"", " (R2)"
	]
	
	action_names = {
		# Gameplay
		"note_up": tr("Note up"),
		"note_down": tr("Note down"),
		"note_left": tr("Note left"),
		"note_right": tr("Note right"),
		"slide_left": tr("Slide left"),
		"slide_right": tr("Slide right"),
		"heart_note": tr("Heart note"),
		"practice_set_waypoint": tr("Practice mode: Set waypoint"),
		"practice_go_to_waypoint": tr("Practice mode: Go to waypoint"),
		"practice_last_mode": tr("Practice mode: Last mode"),
		"practice_next_mode": tr("Practice mode: Next mode"),
		"practice_apply_latency": tr("Practice mode: Apply calculated latency"),
		"pause": tr("Pause"),
		
		# GUI
		"gui_up": tr("Menu up"),
		"gui_down": tr("Menu down"),
		"gui_left": tr("Menu left"),
		"gui_right": tr("Menu right"),
		"gui_tab_left": tr("Tab left"),
		"gui_tab_right": tr("Tab right"),
		"gui_accept": tr("Menu accept"),
		"gui_cancel": tr("Menu cancel"),
		"gui_show_song": tr("Show currently playing song"),
		"gui_search": tr("Menu search"),
		"contextual_option": tr("Contextual option"),
		
		# Editor
		#  General
		"editor_play": tr("Play/Pause"),
		"editor_playtest": tr("Playtest"),
		"editor_playtest_at_time": tr("Playtest at time"),
		"editor_move_playhead_left": tr("Move playhead to the left"),
		"editor_move_playhead_right": tr("Move playhead to the right"),
		"editor_quick_lyric": tr("Quick lyric"),
		"editor_quick_phrase_start": tr("Quick phrase start"),
		"editor_quick_phrase_end": tr("Quick phrase end"),
		"gui_undo": tr("Undo"),
		"gui_redo": tr("Redo"),
		#  Selection
		"editor_select_all": tr("Select all"),
		"editor_cut": tr("Cut notes"),
		"editor_copy": tr("Copy notes"),
		"editor_paste": tr("Paste notes"),
		"editor_delete": tr("Delete notes"),
		#  Sync
		"editor_toggle_hold": tr("Toggle hold"),
		"editor_toggle_sustain": tr("Toggle sustain"),
		"editor_toggle_double": tr("Toggle double"),
		"editor_change_note_up": tr("Increase note type"),
		"editor_change_note_down": tr("Decrease note type"),
		"editor_resolution_4": tr("Set resolution to 4ths"),
		"editor_resolution_6": tr("Set resolution to 6ths"),
		"editor_resolution_8": tr("Set resolution to 8ths"),
		"editor_resolution_12": tr("Set resolution to 12ths"),
		"editor_resolution_16": tr("Set resolution to 16ths"),
		"editor_resolution_24": tr("Set resolution to 24ths"),
		"editor_resolution_32": tr("Set resolution to 32nds"),
		"editor_timeline_snap": tr("Toggle timeline snap"),
		"editor_increase_resolution": tr("Increase timeline resolution"),
		"editor_decrease_resolution": tr("Decrease timeline resolution"),
		#  Placements
		"editor_grid": tr("Toggle grid"),
		"editor_grid_snap": tr("Toggle grid snap"),
		"editor_show_arrange_menu": tr("Show arrange menu"),
		"editor_arrange_l": tr("Arrange left"),
		"editor_arrange_r": tr("Arrange right"),
		"editor_arrange_u": tr("Arrange up"),
		"editor_arrange_d": tr("Arrange down"),
		"editor_arrange_ul": tr("Arrange up left"),
		"editor_arrange_ur": tr("Arrange up right"),
		"editor_arrange_dl": tr("Arrange down left"),
		"editor_arrange_dr": tr("Arrange down right"),
		"editor_arrange_center": tr("Arrange center"),
		"editor_fine_position_left": tr("Fine position notes left"),
		"editor_fine_position_right": tr("Fine position notes right"),
		"editor_fine_position_up": tr("Fine position notes up"),
		"editor_fine_position_down": tr("Fine position notes down"),
		"editor_move_left": tr("Move notes left"),
		"editor_move_right": tr("Move notes right"),
		"editor_move_up": tr("Move notes up"),
		"editor_move_down": tr("Move notes down"),
		#  Angles
		"editor_interpolate_angle": tr("Interpolate angles"),
		"editor_flip_angle": tr("Flip angle"),
		"editor_flip_oscillation": tr("Flip oscillation"),
		"editor_angle_l": tr("Set angle to 180º"),
		"editor_angle_r": tr("Set angle to 0º"),
		"editor_angle_u": tr("Set angle to 270º"),
		"editor_angle_d": tr("Set angle to 90º"),
		"editor_angle_ul": tr("Set angle to 225º"),
		"editor_angle_ur": tr("Set angle to 315º"),
		"editor_angle_dl": tr("Set angle to 135º"),
		"editor_angle_dr": tr("Set angle to 45º"),
		#  Transforms
		"editor_flip_h": tr("Flip horizontal"),
		"editor_flip_v": tr("Flip vertical"),
		"editor_make_circle_c": tr("Make circle clockwise"),
		"editor_make_circle_cc": tr("Make circle counter-clockwise"),
		"editor_circle_size_bigger": tr("Circle size bigger"),
		"editor_circle_size_smaller": tr("Circle size smaller"),
		"editor_circle_inside": tr("Circle inside"),
		#  Presets
		"editor_vertical_multi_left": tr("Vertical multi left"),
		"editor_vertical_multi_right": tr("Vertical multi right"),
		"editor_horizontal_multi_top": tr("Vertical multi top"),
		"editor_horizontal_multi_bottom": tr("Vertical multi bottom"),
		"editor_slider_multi_top": tr("Slider multi top"),
		"editor_slider_multi_bottom": tr("Slider multi bottom"),
		"editor_inner_slider_multi_top": tr("Inner slider multi top"),
		"editor_inner_slider_multi_bottom": tr("Inner slider multi bottom"),
		"editor_quad": tr("Quad"),
		"editor_triangle_left": tr("Triangle left"),
		"editor_triangle_right": tr("Triangle right"),
	}
	
	ACTION_CATEGORIES = {
		tr("Notes"): ["note_up", "note_down", "note_left", "note_right", "slide_left", "slide_right", "heart_note"],
		tr("Game"): ["pause", "practice_set_waypoint", "practice_go_to_waypoint", "practice_last_mode", "practice_next_mode", "practice_apply_latency"],
		tr("GUI"): ["gui_search", "gui_up", "gui_down", "gui_left", "gui_right", "gui_tab_left", "gui_tab_right", "gui_accept", "gui_cancel", "gui_show_song", "contextual_option"]
	}
func get_axis_name(event: InputEventJoypadMotion):
	var n = 2 * event.axis;
	if event.axis_value >= 0:
		n += 1
	var axis_sign = "+"
	if event.axis_value < 0:
		axis_sign = "-"
	return "Axis " + str(event.axis) + " " + axis_sign + " " + axis_names[n]

func get_button_name(event: InputEventJoypadButton):
	return button_names[event.button_index]

func load_input_map():
	# Loads input map from the user's settings
	for action_name in user_settings.input_map:
		if InputMap.has_action(action_name):
			InputMap.action_erase_events(action_name)
			for action in user_settings.input_map[action_name]:
				if action is InputEventJoypadMotion and action_name in UserSettings.DISABLE_ANALOG_FOR_ACTION:
					continue
				if action is InputEventJoypadMotion or action is InputEventJoypadButton:
					action.device = controller_device_idx
				InputMap.action_add_event(action_name, action)
	current_mode = PROMPT_MODE.JOYPAD
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func map_actions_to_controller():
	for _device_idx in Input.get_connected_joypads():
		if Input.get_joy_guid(_device_idx) == controller_guid:
			Log.log(self, "Swapping main controller device from " + str(controller_device_idx) + " to " + str(_device_idx))
			controller_device_idx = _device_idx
			break
	# Remap actions to new device id
	load_input_map()
	JoypadSupport._set_joypad(controller_device_idx, true)
	
	if Input.get_connected_joypads().size() == 0:
		JoypadSupport.force_keyboard_prompts()
	
	emit_signal("controller_swapped", controller_device_idx)
	
enum PROMPT_MODE {
	KEYBOARD,
	JOYPAD
}
	
var current_mode = PROMPT_MODE.KEYBOARD
func _input(event):
	if event is InputEventJoypadButton:
		if controller_device_idx == -1:
			controller_device_idx = event.device
			controller_guid = Input.get_joy_guid(controller_device_idx)
			map_actions_to_controller()
		if current_mode != PROMPT_MODE.JOYPAD:
			current_mode = PROMPT_MODE.JOYPAD
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			set_joypad_prompts()
			JoypadSupport._set_joypad(event.device, true)
	elif event is InputEventKey or event is InputEventMouseButton:
		if current_mode != PROMPT_MODE.KEYBOARD:
			current_mode = PROMPT_MODE.KEYBOARD
			mouse_hide_timer.stop()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			JoypadSupport.force_keyboard_prompts()
	if event is InputEventMouseMotion:
		mouse_hide_timer.stop()
	if current_mode == PROMPT_MODE.JOYPAD:
		if event is InputEventMouseMotion:
			if not event.relative.is_equal_approx(Vector2.ZERO):
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mouse_hide_timer.start()
func load_user_settings():
	var file := File.new()
	var usp = HBGame.platform_settings.user_dir_redirect(USER_SETTINGS_PATH)
	if file.file_exists(usp):
		if file.open(usp, File.READ) == OK:
			var result = JSON.parse(file.get_as_text())
			if result.error == OK:
				user_settings = HBUserSettings.deserialize(result.result)
				Log.log(self, "Successfully loaded user settings from " + usp)
			else:
				Log.log(self, "Error loading user settings, on line %d: %s" % [result.error_line, result.error_string], Log.LogLevel.ERROR)
	
func set_joypad_prompts():
	match user_settings.button_prompt_override:
		"default":
			JoypadSupport.set_autodetect_to(true)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.UNINDENTIFIED)
			JoypadSupport.force_keyboard_prompts()
		"xbox":
			JoypadSupport.set_autodetect_to(false)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.XBOX)
		"playstation":
			JoypadSupport.set_autodetect_to(false)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.PLAYSTATION)
		"nintendo":
			JoypadSupport.set_autodetect_to(false)
			JoypadSupport.set_chosen_skin(JS_JoypadIdentifier.JoyPads.NINTENDO)
func apply_user_settings(apply_display := false):
	if apply_display:
		apply_display_mode()
	_update_fps_limits()
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, user_settings.visualizer_enabled)
	apply_volumes()
	register_user_fx()
	HBGame.spectrum_snapshot.enabled = user_settings.visualizer_enabled

var enable_menu_fps_limits := false setget set_enable_menu_fps_limits

func set_enable_menu_fps_limits(val):
	enable_menu_fps_limits = val
	_update_fps_limits()

func _update_fps_limits():
	OS.vsync_enabled = user_settings.vsync_enabled
	Engine.target_fps = 0
	if not user_settings.vsync_enabled:
		if enable_menu_fps_limits:
			Engine.target_fps = 0
			OS.vsync_enabled = true
		else:
			Engine.target_fps = int(user_settings.fps_limit)
func get_current_display():
	return min(UserSettings.user_settings.display, OS.get_screen_count()-1)

func save_user_settings():
	debounce_timer.start(0)
func _save_user_settings():
	var file := File.new()
	var usp = HBGame.platform_settings.user_dir_redirect(USER_SETTINGS_PATH)
	user_settings.input_map = get_input_map()
	if file.open(usp, File.WRITE) == OK:
		var contents = JSON.print(user_settings.serialize(), "  ")
		file.store_string(contents)
		PlatformService.service_provider.write_remote_file_async(usp.get_file(), contents.to_utf8())

func get_event_name(event: InputEvent):
	var ret = ""
	if event is InputEventJoypadMotion:
		var _axis_sign = "+"
		if event.axis_value < 0:
			_axis_sign = "-"
		ret = get_axis_name(event)
	elif event is InputEventJoypadButton:
		ret = get_button_name(event)
	elif event is InputEventKey:
		ret = OS.get_scancode_string(event.scancode)
	return ret
	
func apply_display_mode():
	yield(get_tree(), "idle_frame")
	var curr_display = get_current_display()
	var display_mode = UserSettings.user_settings.display_mode
	if HBGame.is_on_steam_deck():
		display_mode = "fullscreen"
		
	match display_mode:
		"fullscreen":
			OS.window_borderless = true
			OS.window_fullscreen = true
			
		"borderless":
			OS.window_borderless = true
			OS.window_fullscreen = false
			OS.window_position = OS.get_screen_position(curr_display)
			# HACK! adding one to the pixel height prevents godot
			# from going into exclusive FS mode on Windows
			if OS.get_name() == "Windows":
				OS.window_size = OS.get_screen_size(curr_display) + Vector2(0, 1)
			else:
				OS.window_size = OS.get_screen_size(curr_display)
		"windowed":
			OS.window_borderless = false
			OS.window_fullscreen = false
			OS.window_position = OS.get_screen_position(curr_display) + (OS.get_screen_size(curr_display) / 2.0) - OS.window_size / 2.0
			
	
func apply_volumes():
	ShinobuGodot.set_master_volume(user_settings.master_volume)
	ShinobuGodot.set_group_volume("music", user_settings.music_volume)
	ShinobuGodot.set_group_volume("menu_music", 0.0 if user_settings.disable_menu_music else 1.0)
	ShinobuGodot.set_group_volume("sfx", user_settings.sfx_volume)
	
func register_user_fx():
	for sound in user_settings.DEFAULT_SOUNDS:
		reload_sound_from_disk(sound)
	
func reload_sound_from_disk(sound_name: String):
	ShinobuGodot.register_sound_from_path(get_sound_path(sound_name), sound_name)
	
func reset_to_default_input_map():
	user_settings.input_map = base_input_map
	load_input_map()
	save_user_settings()

func get_content_directories(only_editable=false):
	if only_editable:
		return [user_settings.content_path]
	else:
		return ["res://"] + [user_settings.content_path]

func get_sound_by_name(sound_name: String) -> AudioStream:
	var file := File.new()
	if user_settings.custom_sounds[sound_name] != "default":
		var file_path = "%s/%s" % [UserSettings.CUSTOM_SOUND_PATH, user_settings.custom_sounds[sound_name]]
		var f = HBUtils.load_wav(file_path)
		if file.file_exists(file_path):
			if f:
				return f
	return HBUserSettings.DEFAULT_SOUNDS[sound_name]

func get_sound_path(sound_name: String) -> String:
	var file := File.new()
	if user_settings.custom_sounds[sound_name] != "default":
		var file_path = "%s/%s" % [UserSettings.CUSTOM_SOUND_PATH, user_settings.custom_sounds[sound_name]]
		if file.file_exists(file_path):
			return file_path
	return HBUserSettings.DEFAULT_SOUNDS[sound_name]

func should_use_direct_joystick_access() -> bool:
	return user_settings.use_direct_joystick_access and Input.is_joy_known(controller_device_idx)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		Input.stop_joy_vibration(controller_device_idx)
