extends HBMenu

var OPTIONS = {
	tr("Game"): {
		"timing_method": {
			"name": tr("Timing method"),
			"description": tr("Selects the timing method to use, using the system clock is the recommended option for most people, use the alternatives only if you are having issues."),
			"options": [HBUserSettings.TIMING_METHOD.SYSTEM_CLOCK, HBUserSettings.TIMING_METHOD.SOUND_HARDWARE_CLOCK, HBUserSettings.TIMING_METHOD.SOUND_HARDWARE_CLOCK_FALLBACK],
			"options_pretty": ["System clock", "Sound hardware clock", "Sound hardware clock (alternative)"],
			"type": "options"
		},
		"workshop_download_audio_only": {
			"name": tr("Download audio only from workshop"),
			"description": tr("If enabled downloads only audio when subscribing to workshop items from the in-game workshop browser")
		},
		"show_note_types_before_playing": {
			"name": tr("Show note types before playing"),
			"description": tr("Shows a list of notes and how to hit them before the song starts")
		},
		"locale": {
			"name": tr("Language"),
			"description": tr("Selects the language to use (requires restart)"),
			"options": ["auto-detect", "en", "es", "ca"],
			"options_pretty": [tr("Auto detect"), "English", "Español", "Català"],
			"type": "options"
		},
		"lag_compensation": {
			"name": tr("Latency compensation"),
			"description": tr("Delay applied to note timing, in miliseconds higher values means notes come later. Keep in mind the game already somewhat compensates for hardware delay (by, for example, already compensating for pulseaudio latency)."),
			"minimum": -300,
			"maximum": 300,
			"step": 1,
			"debounce_step": 10,
			"postfix": " ms"
		},
		"show_latency": {
			"name": tr("Show latency"),
			"description": tr("Shows how late or how early you were when hitting notes."),
		},
		"load_all_notes_on_song_start": {
			"name": tr("Load all notes when song starts"),
			"description": tr("Makes the game pre-generate all notes before the song starts playing, this increases loadtimes but will increase performance once loaded."),
		},
		"show_console": {
			"name": tr("Show console"),
			"description": tr("Shows the engine console."),
		}
	},
	tr("Input"): {
		"controller_guid": {
			"name": tr("Controller"),
			"description": tr("Controller to use for input."),
			"type": "controller_selector"
		},
		"use_direct_joystick_access": {
			"name": tr("Use direct joystick access with known controllers"),
			"description": tr("Allows the game to access controller joysticks directly, used to make slide and heart notes more consistent, only available on controllers marked as known")
		},
		"input_poll_more_than_once_per_frame": {
			"name": tr("Poll for input more than once per frame"),
			"description": tr("If this is enabled the game polls for input more than once per frame, it can reduce input lag but it will increase CPU usage.")
		},
		"enable_vibration": {
			"name": tr("Enable vibration"),
			"description": tr("If enabled allows the controller to vibrate.")
		},
		"analog_deadzone": {
			"name": tr("Analog deadzone"),
			"description": tr("From 0 to 1, how much travel is required for the analog sticks (and other analog inputs) to be considered on/off."),
			"minimum": 0.1,
			"maximum": 1.0,
			"step": 0.05,
		},
	},
	tr("Controls"): {
		"__section_override": preload("res://menus/options_menu/OptionControlsSection.tscn").instance()
	},
	tr("Content"): {
		"__section_override": preload("res://menus/options_menu/content_dirs_menu/OptionContentDirsSection.tscn").instance()
	},
	tr("Audio"): {
		"master_volume": {
			"name": tr("Master volume"),
			"description": tr("Global game volume"),
			"minimum": 0.1,
			"maximum": 7.5,
			"step": 0.05,
			"percentage": true,
			"postfix": " %"
		},
		"sfx_volume": {
			"name": tr("Sound effects volume"),
			"description": tr("Volume for the sound effects"),
			"minimum": 0.0,
			"maximum": 1.5,
			"step": 0.05,
			"percentage": true,
			"postfix": " %"
		},
		"music_volume": {
			"name": tr("Music volume"),
			"description": tr("Volume for the music"),
			"minimum": 0.1,
			"maximum": 1.5,
			"step": 0.05,
			"percentage": true,
			"postfix": " %"
		},
		"enable_voice_fade": {
			"name": tr("Voice fade"),
			"description": tr("Make the voice fade when missing a note (only on supported charts).")
		},
		"disable_menu_music": {
			"name": tr("Disable menu music"),
			"description": tr("Disables all music in menus (requires restart)")
		},
	},
	tr("Video"): {
		"display_mode": {
			"name": tr("Display mode"),
			"description": tr("Whether or not the game should use all the available screen, this should have no difference in performance, except on Windows."),
			"options": ["borderless", "fullscreen", "windowed"],
			"options_pretty": [tr("Borderless fullscreen"), tr("Fullscreen"), tr("Windowed")],
			"type": "options"
		},
		"display": {
			"name": tr("Display"),
			"description": tr("Display to display the game in"),
			"minimum": 0,
			"maximum": OS.get_screen_count(),
			"step": 1,
		},
		"vsync_enabled": {
			"name": tr("Enable VSync"),
			"description": tr("Waits for vertical synchronization to render frame, can reduce screen tearing but will introduce extra input lag.")
		},
		"disable_video": {
			"name": tr("Disable Video"),
			"description": tr("Disables video playback and download, might yield more performance on some systems.")
		},
		"disable_ppd_video": {
			"name": tr("Disable Video for PPD songs"),
			"description": tr("Disables video playback and download for PPD songs, might yield more performance on some systems.")
		},
		"desired_video_fps": {
			"name": tr("Desired Video FPS"),
			"description": tr("The desired video framerate for downloaded videos."),
			"minimum": 30,
			"maximum": 60,
			"step": 30,
			"postfix": " FPS"
		},
		"desired_video_resolution": {
			"name": tr("Desired Video Resolution"),
			"description": tr("The desired video resolution for downloaded videos."),
			"options": [480, 720, 1080, 2160],
			"options_pretty": ["480p", "720p", "1080p", "4K"],
			"type": "options"
		},
		"use_visualizer_with_video": {
			"name": tr("Use visualizer with video"),
			"description": tr("Whether or not the game should display the visualizer on top of videos.")
		},
		"visualizer_enabled": {
			"name": tr("Visualizer"),
			"description": tr("Built-in audio visualization effects, disabling this setting might yield a considerable performance boost on more modest systems.")
		},
		"visualizer_resolution": {
			"name": tr("Visualizer Resolution"),
			"description": tr("How many points of data the audio visualization effects use, lowering this setting might yield a considerable performance boost on more modest systems."),
			"minimum": -64,
			"maximum": 64
		},
		"fps_limit":  {
			"name": tr("FPS Limit"),
			"description": tr("Limits the framerate, this might be useful to limit battery consumption on portable systems."),
			"minimum": 0,
			"maximum": 240,
			"step": 60,
			"text_overrides": {
				0: "Unlimited"
			}
		}
	},
	tr("Visual"): {
		"button_prompt_override": {
			"name": tr("Button prompts"),
			"description": tr("Overrides the button prompts shown for your controller to the specified type."),
			"options": ["default", "xbox", "playstation", "nintendo"],
			"options_pretty": ["Auto-detect", "Xbox™", "PlayStation™", "Nintendo™"],
			"type": "options"
		},
		"color_remap": {
			"name": tr("Color remap"),
			"description": tr("For color-blindness, remaps colors on the screen with others, it's an imperfect solution but it might be useful."),
			"options": [HBUserSettings.COLORBLIND_COLOR_REMAP.NONE, HBUserSettings.COLORBLIND_COLOR_REMAP.GBR, HBUserSettings.COLORBLIND_COLOR_REMAP.BRG, HBUserSettings.COLORBLIND_COLOR_REMAP.BGR],
			"options_pretty": ["None (Red/Green/Blue)", "Red/Green/Blue -> Green/Blue/Red", "Red/Green/Blue -> Blue/Red/Green", "Red/Green/Blue -> Blue/Green/Red"],
			"type": "options"
		},
		"lyrics_enabled": {
			"name": tr("Enable lyrics"),
			"description": tr("Enables showing lyrics in-game.")
		},
		"lyrics_position": {
			"name": tr("Lyrics position"),
			"description": tr("Changes where the lyrics are shown."),
			"options": ["top_left", "top_center", "top_right", "bottom_left", "bottom_center", "bottom_right"],
			"options_pretty": [tr("Top left"), tr("Top center"), tr("Top right"), tr("Bottom left"), tr("Bottom center"), tr("Bottom right")],
			"type": "options"
		},
		"lyrics_color": {
			"name": tr("Lyrics color"),
			"description": tr("Changes the color used to show the lyrics."),
			"options": UserSettings.user_settings.lyrics_color__possibilities,
			"options_pretty": [tr("Orange"), tr("Purple"), tr("Blue"), tr("Red"), tr("Green")],
			"type": "options"
		},
		"note_size": {
			"name": tr("Note Size"),
			"description": tr("How big the notes will appear in the game."),
			"minimum": 0.1,
			"maximum": 3.0,
			"step": 0.1,
			"postfix": " x"
		},
		"background_dim": {
			"name": tr("Background dim"),
			"description": tr("Dims the background, a higher percentage will make it darker, note this also includes video background."),
			"minimum": 0.0,
			"maximum": 1.0,
			"step": 0.05,
			"percentage": true,
			"postfix": " %"
		},
		"enable_multi_hint": {
			"name": tr("Enable multi note indicator"),
			"description": tr("Enables showing an indicator in the middle of the screen for what buttons should be pressed for a multi-note.")
		},
		"use_timing_arm": {
			"name": tr("Show clock arms"),
			"description": tr("Enables using clock arms instead of circles to show you when it's time to press a note.")
		},
		"leading_trail_enabled": {
			"name": tr("Enable leading lines"),
			"description": tr("Enables lines that show where the notes are going to go.")
		},
		"left_arrow_override_enabled": {
			"name": tr("Use arrow instead of left icon"),
			"description": tr("Replaces all instances of the left icon of the selected icon pack with a left arrow.")
		},
		"right_arrow_override_enabled": {
			"name": tr("Use arrow instead of right icon"),
			"description": tr("Replaces all instances of the right icon of the selected icon pack with a right arrow.")
		},
		"up_arrow_override_enabled": {
			"name": tr("Use arrow instead of up icon"),
			"description": tr("Replaces all instances of the up icon of the selected icon pack with a up arrow.")
		},
		"down_arrow_override_enabled": {
			"name": tr("Use arrow instead of down icon"),
			"description": tr("Replaces all instances of the down icon of the selected icon pack with a down arrow.")
		},
		"romanized_titles_enabled": {
			"name": tr("Romanized titles"),
			"description": tr("Shows romanized versions of foreign titles when available.")
		},
		"multi_laser_opacity": {
			"name": tr("Multi laser opacity"),
			"description": tr("Changes the opacity of the laser that connects multi notes."),
			"minimum": 0.0,
			"maximum": 1.0,
			"step": 0.05,
			"percentage": true,
			"postfix": " %"
		},
		"use_explicit_rating": {
			"name": tr("Explicit ratings"),
			"description": tr("Show the full name of the rating on the song list (Doesn't apply for a CHEAP rating).")
		},
	},
	tr("Res. Packs"): {
		"__section_override": preload("res://menus/options_menu/OptionResourcePacksSection.tscn").instance()
	},
	tr("Credits"): {
		"__section_override": preload("res://menus/options_menu/OptionCreditsSection.tscn").instance()
	}
}

onready var sections = get_node("Panel/Content")
onready var buttons = get_node("VBoxContainer")

const OptionMenuButton = preload("res://menus/options_menu/OptionMenuButton.tscn")
const OptionSection = preload("res://menus/options_menu/OptionSection.tscn")

var section_name_to_section_control = {}

func _set_sound_volume(volume, sound: String):
	UserSettings.user_settings.custom_sound_volumes[sound] = volume
	UserSettings.save_user_settings()

func _ready():
	if HBGame.platform_settings is HBPlatformSettingsSwitch:
		OPTIONS[tr("Game")].erase("timing_method")
	for sound_type in HBUserSettings.DEFAULT_SOUNDS.keys():
		var sound_pretty_name = sound_type.capitalize().to_lower()
		sound_pretty_name = sound_pretty_name.substr(0, 1).to_upper() + sound_pretty_name.substr(1)
		OPTIONS[OPTIONS.keys()[4]][sound_type + "_custom"] = {
			"name": tr("%s sound") % [sound_pretty_name],
			"description": tr("Sound to use. (Place custom sounds inside the custom_sounds folder in your user folder, only 16-bit WAV files are supported)"),
			"sound_name": sound_type,
			"type": "sound_type_selector"
		}
		OPTIONS[OPTIONS.keys()[4]][sound_type] = {
			"name": tr("%s sound volume") % [sound_pretty_name],
			"description": tr("Volume for this sound effect"),
			"minimum": 0.0,
			"maximum": 1.5,
			"step": 0.05,
			"percentage": true,
			"postfix": " %",
			"signal_method": "_set_sound_volume",
			"signal_object": self,
			"default_value": 1.0,
			"signal_binds": [sound_type],
			"value_source": UserSettings.user_settings.custom_sound_volumes
		}
	add_default_values()
	buttons.connect("hover", self, "_on_button_hover")
	for section_name in OPTIONS:
		var option_button = OptionMenuButton.instance()
		option_button.text = section_name
		option_button.connect("pressed", self, "_on_SectionButton_press", [section_name])
		buttons.add_child(option_button)
		if OPTIONS[section_name].has("__section_override"):
			var section = OPTIONS[section_name].__section_override
			# Some sections, such as controls remapping, use their own thing
			sections.add_child(section)
			section_name_to_section_control[section_name] = section
			section.connect("back", self, "_on_back")
		else:
			var section = OptionSection.instance()
			section.connect("back", self, "_on_back")
			section.connect("changed", self, "_on_value_changed")
			section.settings_source = UserSettings.user_settings
			sections.add_child(section)
			section.section_data = OPTIONS[section_name]
			
			section_name_to_section_control[section_name] = section
		
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$VBoxContainer.grab_focus()

func add_default_values():
	for section_name in OPTIONS:
		var section = OPTIONS[section_name]
		for option_name in section:
			# Section overrides manage all themselves
			if not OPTIONS[section_name].has("__section_override") and not "default_value" in OPTIONS[section_name][option_name]:
				OPTIONS[section_name][option_name]["default_value"] = UserSettings.user_settings.get(option_name)
			
func _show_section(section_name):
	for section_n in section_name_to_section_control:
		var section = section_name_to_section_control[section_n]
		if section_name == section_n:
			section.show()
			if section.has_method("show_section"):
				section.show_section()
		else:
			section.hide()

func _on_button_hover(button):
	_show_section(button.text)

func _on_SectionButton_press(section_name):
	section_name_to_section_control[section_name].grab_focus()

func _on_value_changed(property_name, new_value):
	UserSettings.user_settings.set(property_name, new_value)
	
	if property_name == "background_dim":
		get_tree().call_group("song_backgrounds", "_background_dim_changed", new_value)
#	if property_name == "icon_pack":
#		IconPackLoader.set_current_pack(new_value)
	if property_name.ends_with("_arrow_override_enabled"):
		ResourcePackLoader.soft_rebuild_final_atlas()
	if property_name == "button_prompt_override":
		UserSettings.set_joypad_prompts()
	if property_name == "color_remap":
		ColorBlindOverlay.update_overlay()
	UserSettings.apply_user_settings(property_name in ["display_mode", "display"])
	UserSettings.save_user_settings()

func _on_back():
	$VBoxContainer.grab_focus()

func _unhandled_input(event):
	if $VBoxContainer.has_focus():
		if event.is_action_pressed("gui_cancel"):
			get_tree().set_input_as_handled()
			change_to_menu("main_menu")

const CODE = ["gui_up", "gui_up", "gui_down", "gui_down", "gui_left", "gui_right", "gui_left", "gui_right", "note_down", "note_right", "pause"]
var code_p = 0
func _input(event):
	var next_code = CODE[code_p]
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed() and not event.is_echo():
			if event.is_action_pressed(next_code):
				code_p += 1
				if code_p == CODE.size():
					code_p = 0
					get_tree().set_input_as_handled()
					change_to_menu("staff_roll")
			else:
				code_p = 0

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for section_name in section_name_to_section_control:
			var section = section_name_to_section_control[section_name]
			if is_instance_valid(section) and not section.is_queued_for_deletion():
				section.queue_free()
		for section_name in OPTIONS:
			if OPTIONS[section_name].has("__section_override"):
				var section = OPTIONS[section_name].__section_override
				if is_instance_valid(section) and not section.is_queued_for_deletion():
					section.queue_free()
