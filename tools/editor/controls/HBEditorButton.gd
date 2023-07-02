@tool
extends Container

class_name HBEditorButton

signal min_x_size_changed

var aspect_ratio_container: AspectRatioContainer
var button: Button
var label: Label
var module: HBEditorModule: set = set_module

@export var text: String : set = set_text
@export var tooltip: String : set = set_tooltip
@export var texture: CompressedTexture2D: set = set_texture

@export var disable_when_playing: bool = true
@export var disable_with_popup: bool = true

@export var button_mode = "transform" # (String, "transform", "function")
@export var transform_id: int = 0
@export var function_name: String = ""
@export var params: Array

@export var action: String = ""
@export var echo_action: bool = false

func _init():
	aspect_ratio_container = AspectRatioContainer.new()
	aspect_ratio_container.alignment_vertical = AspectRatioContainer.ALIGNMENT_BEGIN
	aspect_ratio_container.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	aspect_ratio_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	button = Button.new()
	button.icon = texture
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	
	label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	
	aspect_ratio_container.add_child(button)
	add_child(aspect_ratio_container)
	add_child(label)

func _ready():
	custom_minimum_size.x = label.size.x
	custom_minimum_size.y = custom_minimum_size.x + get_theme_constant("separation") + label.size.y
	
	button.tooltip_text = tooltip
	
	if disable_when_playing:
		button.add_to_group("disabled_ui")
	elif disable_with_popup:
		button.add_to_group("extended_disabled_ui")

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		var label_offset := Vector2(0, aspect_ratio_container.size.y + get_theme_constant("separation"))
		fit_child_in_rect(aspect_ratio_container, Rect2(Vector2(), Vector2(size.x, size.x)))
		fit_child_in_rect(label, Rect2(label_offset, size - label_offset))

func _process(_delta):
	custom_minimum_size.y = size.x + get_theme_constant("separation") + label.size.y

func get_button():
	return button

func set_text(new_text):
	text = new_text
	label.text = new_text
	
	custom_minimum_size.x = label.size.x
	custom_minimum_size.y = custom_minimum_size.x + get_theme_constant("separation") + label.size.y
	emit_signal("min_x_size_changed")

func set_tooltip(new_tooltip):
	button.tooltip_text = tooltip
	
	tooltip = new_tooltip

func set_texture(new_texture):
	texture = new_texture
	button.icon = new_texture

func set_disabled(disabled: bool):
	button.disabled = disabled

func set_module(_module):
	module = _module
	
	if button_mode == "transform":
		button.connect("pressed", Callable(module, "apply_transform").bind(transform_id))
		button.connect("mouse_entered", Callable(module, "show_transform").bind(transform_id))
		button.connect("mouse_exited", Callable(module, "hide_transform"))
		
		if action:
			module.add_shortcut(action, "apply_transform", [transform_id], echo_action, button)
	if button_mode == "function":
		button.connect("pressed", Callable(module, function_name).bind(params))
		
		if action:
			module.add_shortcut(action, function_name, params, echo_action, button)

func update_shortcut(event_text: String):
	button.tooltip_text = tooltip + "\nShortcut: " + event_text
