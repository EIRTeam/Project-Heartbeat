extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var color_picker_button = get_node("ColorPickerButton")
var color_picker: ColorPicker
var default_presets = []

func sync_value(value):
	color_picker_button.set_block_signals(true)
	color_picker_button.color = value
	color_picker_button.set_block_signals(false)

func _ready():
	color_picker = color_picker_button.get_picker()
	for preset in UserSettings.user_settings.color_presets:
		color_picker.add_preset(Color(preset))
	
	color_picker_button.connect("popup_closed", self, "_on_colorpicker_value_changed")
	color_picker.connect("preset_added", self, "_on_colorpicker_preset_added")
	color_picker.connect("preset_removed", self, "_on_colorpicker_preset_removed")

func emit_value_changed_signal():
	emit_signal("value_changed", color_picker_button.color)
	emit_signal("value_change_committed")

func _on_colorpicker_value_changed():
	emit_value_changed_signal()

func _on_colorpicker_preset_added(color: Color):
	if not color.to_html() in default_presets:
		UserSettings.user_settings.color_presets.append(color.to_html())
		UserSettings.save_user_settings()
	print(UserSettings.user_settings.color_presets)
func _on_colorpicker_preset_removed(color: Color):
	if not color.to_html() in default_presets:
		UserSettings.user_settings.color_presets.erase(color.to_html())
		UserSettings.save_user_settings()
	print(UserSettings.user_settings.color_presets)

func set_params(params):
	if "presets" in params:
		default_presets = params.presets
		
		color_picker.set_block_signals(true)
		for preset in default_presets:
			color_picker.add_preset(Color(preset))
		color_picker.set_block_signals(false)
