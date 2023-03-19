tool
extends Container

class_name HBEditorButton

signal min_x_size_changed

var aspect_ratio_container: AspectRatioContainer
var button: Button
var label: Label
var module: HBEditorModule setget set_module

export(String, MULTILINE) var text setget set_text
export(String, MULTILINE) var tooltip setget set_tooltip
export var texture: StreamTexture setget set_texture

export(bool) var disable_when_playing = true
export(bool) var disable_with_popup = true

export(String, "transform", "function") var button_mode = "transform"
export(int) var transform_id = 0
export(String) var function_name = ""
export(Array) var params

export(String) var action = ""
export(bool) var echo_action = false

func _init():
	aspect_ratio_container = AspectRatioContainer.new()
	aspect_ratio_container.alignment_vertical = AspectRatioContainer.ALIGN_BEGIN
	aspect_ratio_container.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	aspect_ratio_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	button = Button.new()
	button.icon = texture
	button.icon_align = Button.ALIGN_CENTER
	button.expand_icon = true
	
	label = Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	
	aspect_ratio_container.add_child(button)
	add_child(aspect_ratio_container)
	add_child(label)

func _ready():
	rect_min_size.x = label.rect_size.x
	rect_min_size.y = rect_min_size.x + get_constant("separation") + label.rect_size.y
	
	button.hint_tooltip = tooltip
	
	if disable_when_playing:
		button.add_to_group("disabled_ui")
	elif disable_with_popup:
		button.add_to_group("extended_disabled_ui")

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		var label_offset := Vector2(0, aspect_ratio_container.rect_size.y + get_constant("separation"))
		fit_child_in_rect(aspect_ratio_container, Rect2(Vector2(), Vector2(rect_size.x, rect_size.x)))
		fit_child_in_rect(label, Rect2(label_offset, rect_size - label_offset))

func _process(_delta):
	rect_min_size.y = rect_size.x + get_constant("separation") + label.rect_size.y

func get_button():
	return button

func set_text(new_text):
	text = new_text
	label.text = new_text
	
	rect_min_size.x = label.rect_size.x
	rect_min_size.y = rect_min_size.x + get_constant("separation") + label.rect_size.y
	emit_signal("min_x_size_changed")

func set_tooltip(new_tooltip):
	button.hint_tooltip = tooltip
	
	tooltip = new_tooltip

func set_texture(new_texture):
	texture = new_texture
	button.icon = new_texture

func set_disabled(disabled: bool):
	button.disabled = disabled

func set_module(_module):
	module = _module
	
	if button_mode == "transform":
		button.connect("pressed", module, "apply_transform", [transform_id])
		button.connect("mouse_entered", module, "show_transform", [transform_id])
		button.connect("mouse_exited", module, "hide_transform")
		
		if action:
			module.add_shortcut(action, "apply_transform", [transform_id], echo_action, button)
	if button_mode == "function":
		button.connect("pressed", module, function_name, params)
		
		if action:
			module.add_shortcut(action, function_name, params, echo_action, button)

func update_shortcut(event_text: String):
	button.hint_tooltip = tooltip + "\nShortcut: " + event_text
