extends MarginContainer

var editor: HBEditor setget set_editor

func set_editor(value):
	for preset in dynamic_sync_presets:
		dynamic_sync_presets[preset].editor = value

var static_sync_presets = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().static_presets
# presets presented as two buttons side by side
var static_sync_presets_dual = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().dual_presets
var dynamic_sync_presets = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().dynamic_presets

onready var sync_button_container = get_node("ScrollContainer/SyncButtonContainer")

signal show_transform(transform_data)
signal hide_transform()
signal apply_transform(transform_data)

func make_button(preset_name: String, preset_list) -> Button:
	var button = Button.new()
	button.text = preset_name
	var transformation = EditorTransformationTemplate.new()
	transformation.template = preset_list[preset_name]
	
	button.connect("mouse_entered", self, "_show_preset_preview", [transformation])
	button.connect("pressed", self, "_apply_transform", [transformation])
	button.connect("mouse_exited", self, "_hide_preset_preview")

	return button

func make_dynamic_button(preset_name: String, transformation: EditorTransformation) -> Button:
	var button = Button.new()
	button.text = preset_name
	
	button.connect("mouse_entered", self, "_show_preset_preview", [transformation])
	button.connect("pressed", self, "_apply_transform", [transformation])
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
		var button = make_dynamic_button(preset_name, dynamic_sync_presets[preset_name])
		var button2 = make_dynamic_button(preset_name2, dynamic_sync_presets[preset_name2])
		add_button_row(button, button2)
	
func _show_preset_preview(transformation):
	emit_signal("show_transform", transformation)
func _hide_preset_preview():
	emit_signal("hide_transform")
func _apply_transform(transformation):
	emit_signal("apply_transform", transformation)

func _unhandled_input(event):
	if event.is_action("editor_vertical_multi_left", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Vertical multi left"])
	if event.is_action("editor_vertical_multi_right", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Vertical multi right"])
	
	if event.is_action("editor_horizontal_multi_top", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Horizontal multi top"])
	if event.is_action("editor_horizontal_multi_bottom", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Horizontal multi bottom"])
	
	if event.is_action("editor_slider_multi_top", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Slider multi top"])
	if event.is_action("editor_slider_multi_bottom", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Slider multi bottom"])
	if event.is_action("editor_inner_slider_multi_top", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Inner slider multi top"])
	if event.is_action("editor_inner_slider_multi_bottom", true) and event.pressed and not event.echo:
		emit_signal("apply_transform", dynamic_sync_presets["Inner slider multi bottom"])
	
	if event.is_action("editor_quad", true) and event.pressed and not event.echo:
		var transformation = EditorTransformationTemplate.new()
		transformation.template = static_sync_presets["Quad"]
		emit_signal("apply_transform", transformation)
	
	if event.is_action("editor_triangle_left", true) and event.pressed and not event.echo:
		var transformation = EditorTransformationTemplate.new()
		transformation.template = static_sync_presets_dual["Triangle left"]
		emit_signal("apply_transform", transformation)
	if event.is_action("editor_triangle_right", true) and event.pressed and not event.echo:
		var transformation = EditorTransformationTemplate.new()
		transformation.template = static_sync_presets_dual["Triangle right"]
		emit_signal("apply_transform", transformation)
