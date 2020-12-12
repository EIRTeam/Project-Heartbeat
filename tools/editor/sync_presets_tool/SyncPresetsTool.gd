extends MarginContainer

var static_sync_presets = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().static_presets
# presets presented as two buttons side by side
var static_sync_presets_dual = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().dual_presets
var dynamic_sync_presets = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().dynamic_presets

onready var sync_button_container = get_node("ScrollContainer/SyncButtonContainer")

signal show_transform(transform_data)
signal hide_transform()
signal apply_transform(transform_data)
signal show_transform_dynamic(transform_data)
signal apply_transform_dynamic(transform_data)

func make_button(preset_name: String, preset_list, dynamic_preset = false) -> Button:
	var button = Button.new()
	button.text = preset_name
	if not dynamic_preset:
		button.connect("mouse_entered", self, "_show_preset_preview", [preset_name, preset_list])
		button.connect("pressed", self, "_apply_transform", [preset_name, preset_list])
	else:
		button.connect("mouse_entered", self, "_show_preset_preview_dynamic", [preset_name, preset_list])
		button.connect("pressed", self, "_apply_transform_dynamic", [preset_name, preset_list])
	button.connect("mouse_exited", self, "_hide_preset_preview")

	return button
	
func add_button_row(button, button2):
	var hbox_container = HBoxContainer.new()
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button2.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox_container.add_child(button)
	hbox_container.add_child(button2)
	sync_button_container.add_child(hbox_container)
	
func _ready():
	for preset_name in static_sync_presets:
		sync_button_container.add_child(make_button(preset_name, static_sync_presets))
	if static_sync_presets_dual.size() % 2 != 0:
		assert("Dual static sync presets should be two per row")
	for i in range(0, static_sync_presets_dual.size(), 2):
		var preset_name = static_sync_presets_dual.keys()[i]
		var preset_name2 = static_sync_presets_dual.keys()[i+1]
		var button = make_button(preset_name, static_sync_presets_dual)
		var button2 = make_button(preset_name2, static_sync_presets_dual)
		add_button_row(button, button2)
	
	var dynamic_preset_label = Label.new()
	dynamic_preset_label.text = "Dynapresets™"
	sync_button_container.add_child(dynamic_preset_label)
	
	if dynamic_sync_presets.size() % 2 != 0:
		assert("Dynamic sync presets should be two per row")
		
	for i in range(0, dynamic_sync_presets.size(), 2):
		var preset_name = dynamic_sync_presets.keys()[i]
		var preset_name2 = dynamic_sync_presets.keys()[i+1]
		var button = make_button(preset_name, dynamic_sync_presets, true)
		var button2 = make_button(preset_name2, dynamic_sync_presets, true)
		add_button_row(button, button2)
func _show_preset_preview(preset_name: String, preset_list):
	emit_signal("show_transform", preset_list[preset_name])
func _hide_preset_preview():
	emit_signal("hide_transform")
func _apply_transform(preset_name: String, preset_list):
	emit_signal("apply_transform", preset_list[preset_name])
func _show_preset_preview_dynamic(preset_name: String, preset_list):
	emit_signal("show_transform_dynamic", preset_list[preset_name])
func _apply_transform_dynamic(preset_name: String, preset_list):
	emit_signal("apply_transform_dynamic", preset_list[preset_name])
