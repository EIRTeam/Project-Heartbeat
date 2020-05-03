extends HBMenu

var OPTIONS = {
	"Game": {
		"input_poll_more_than_once_per_frame": {
			"name": tr("Poll for input more than once per frame"),
			"description": "If this is enabled the game polls for input more than once per frame, it can reduce input lag but it will increase CPU usage."
		},
		"lag_compensation": {
			"name": tr("Latency compensation"),
			"description": "Delay applied to note timing, in miliseconds higher values means notes come later. Keep in mind the game already somewhat compensates for hardware delay (by, for example, already compensating for pulseaudio latency).",
			"minimum": -300,
			"maximum": 300,
			"step": 1,
			"postfix": " ms"
		},
		"tap_deadzone": {
			"name": tr("Slide analog deadzone"),
			"description": "From 0 to 1, how much travel is required for the analog sticks (and other analog inputs) to be considered on/off when being used for slides.",
			"minimum": 0.1,
			"maximum": 0.9,
			"step": 0.1,
		},
		"analog_translation_deadzone": {
			"name": tr("Analog deadzone"),
			"description": "From 0 to 1, how much travel is required for the analogic triggers (and other analog inputs) to be considered on/off when being used normal notes.",
			"minimum": 0.1,
			"maximum": 0.9,
			"step": 0.1,
		},
		"show_latency": {
			"name": tr("Show latency"),
			"description": tr("Shows how late or how early you were when hitting notes."),
		},
		"enable_voice_fade": {
			"name": tr("Voice fade"),
			"description": tr("Make the voice fade when missing a note (only on supported charts).")
		}
	},
	"Controls": {
		"__section_override": preload("res://menus/options_menu/OptionControlsSection.tscn").instance()
	},
	"Audio": {
		"master_volume": {
			"name": tr("Master volume"),
			"description": tr("Global game volume"),
			"minimum": 0.1,
			"maximum": 1.5,
			"step": 0.05,
			"percentage": true,
			"postfix": " %"
		},
		"sfx_volume": {
			"name": tr("Sound effects volume"),
			"description": tr("Volume for the sound effects"),
			"minimum": 0.1,
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
		}
	},
	"Video": {
		"fullscreen": {
			"name": tr("Fullscreen"),
			"description": tr("Whether or not the game should use all the available screen, this should have no difference in performance from windowed mode.")
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
			"options": [720, 1080, 2160],
			"options_pretty": ["720p", "1080p", "4K"],
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
			"description": "Limits the framerate, this might be useful to limit battery consumption on portable systems.",
			"minimum": 0,
			"maximum": 240,
			"step": 60,
			"text_overrides": {
				0: "Unlimited"
			}
		}
	},
	"Visual": {
		"icon_pack": {
			"name": tr("Icons"),
			"description": tr("Switches between available Icon-Sets."),
			"type": "icon_type_selector"
		},
		"note_size": {
			"name": tr("Note Size"),
			"description": "How big the notes will appear in the game.",
			"minimum": 0.1,
			"maximum": 3.0,
			"step": 0.1,
			"postfix": " x"
		},
		"enable_hold_hint": {
			"name": tr("Enable hold indicator"),
			"description": "Enables showing an indicator in the middle of the screen for what buttons should be pressed for a multi-note."
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
		}
	}
}

onready var sections = get_node("Panel/Content")
onready var buttons = get_node("VBoxContainer")

const OptionMenuButton = preload("res://menus/options_menu/OptionMenuButton.tscn")
const OptionSection = preload("res://menus/options_menu/OptionSection.tscn")

var section_name_to_section_control = {}

func _ready():
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
			if not OPTIONS[section_name].has("__section_override"):
				OPTIONS[section_name][option_name]["default_value"] = UserSettings.user_settings.get(option_name)
			
func _show_section(section_name):
	for section_n in section_name_to_section_control:
		var section = section_name_to_section_control[section_n]
		if section_name == section_n:
			section.show()
		else:
			section.hide()

func _on_button_hover(button):
	_show_section(button.text)

func _on_SectionButton_press(section_name):
	section_name_to_section_control[section_name].grab_focus()

func _on_value_changed(property_name, new_value):
	UserSettings.user_settings.set(property_name, new_value)
	UserSettings.apply_user_settings()
	UserSettings.save_user_settings()

func _on_back():
	$VBoxContainer.grab_focus()

func _unhandled_input(event):
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
