extends HBMenu

var OPTIONS = {
	"Game": {
		"lag_compensation": {
			"name": tr("Latency compensation"),
			"description": "Delay applied to gameplay relative to audio, in miliseconds. Keep in mind the game already somewhat compensates for hardware delay (by, for example, already compensating for pulseaudio latency).",
			"minimum": -30,
			"maximum": 30,
			"step": 1
		}
	},
	"Controls": {
	},
	"Visual": {
		"icon_pack": {
			"name": tr("Icons"),
			"description": tr("Switches between available Icon-Sets."),
			"type": "icon_type_selector"
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
		var section = OptionSection.instance()
		section.connect("back", self, "_on_back")
		section.section_data = OPTIONS[section_name]
		section.connect("changed", self, "_on_value_changed")
		sections.add_child(section)
		
		section_name_to_section_control[section_name] = section
		
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$VBoxContainer.grab_focus()

func add_default_values():
	for section_name in OPTIONS:
		var section = OPTIONS[section_name]
		for option_name in section:
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
	UserSettings.save_user_settings()

func _on_back():
	$VBoxContainer.grab_focus()

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		get_tree().set_input_as_handled()
		change_to_menu("main_menu")
