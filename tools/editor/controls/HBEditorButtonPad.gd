extends HBEditorButton

class_name HBEditorButtonPad

@onready var button_pad_shader: Shader = preload("res://tools/editor/controls/button_pad_shader.gdshader")

@export_category("UI")
@export_custom(PROPERTY_HINT_RANGE, "1,10,1,or_greater") var pad_division: int = 3 : 
	set(v): 
		pad_division = max(v, 1)

var _pressed = false

func _ready() -> void:
	button.material = ShaderMaterial.new()
	button.material.shader = button_pad_shader
	
	button.material.set_shader_parameter("pressed_color", button.get_theme_color("icon_pressed_color"))
	
	self._set_texture(self.texture)
	
	button.gui_input.connect(button_gui_input)
	button.mouse_entered.connect(button_mouse_entered)
	button.mouse_exited.connect(button_mouse_exited)
	button.button_down.connect(button_pressed)
	button.button_up.connect(button_released)

# This version of _set_texture doesnt set the button icon, only the shader icon.
func _set_texture(new_texture: CompressedTexture2D):
	if button and button.material:
		button.material.set_shader_parameter("icon_texture", new_texture)

func button_gui_input(_event: InputEvent) -> void:
	# Lock the highlight pos when holding down the button
	if _pressed: 
		return
	
	if pad_division == 1:
		button.material.set_shader_parameter("highlight_pos", Vector2(0.5, 0.5))
		button.material.set_shader_parameter("highlight_idx", Vector2(0, 0))
		button.material.set_shader_parameter("highlight_area_size", 1.0)
		
		return
	
	var normalized_mouse_pos := button.get_local_mouse_position() / button.get_size()
	
	# Divides the pad into the given number of buttons
	var highlight_idx := floor(normalized_mouse_pos * self.pad_division)
	
	highlight_idx = clamp(highlight_idx, Vector2(0, 0), Vector2(self.pad_division - 1, self.pad_division - 1))
	
	var highlight_pos = highlight_idx / (self.pad_division - 1)
	button.material.set_shader_parameter("highlight_pos", highlight_pos)
	button.material.set_shader_parameter("highlight_idx", highlight_idx)
	button.material.set_shader_parameter("highlight_area_size", 1.0 / self.pad_division)

func button_mouse_entered():
	button.material.set_shader_parameter("hover", true)

func button_mouse_exited():
	button.material.set_shader_parameter("hover", false)

func button_pressed():
	button.material.set_shader_parameter("pressed", true)
	
	_pressed = true

func button_released():
	button.material.set_shader_parameter("pressed", false)
	
	_pressed = false
	self.button_gui_input(InputEventMouseMotion.new())

func set_module(_module) -> void:
	module = _module
	
	if button_mode == "transform":
		button.connect("pressed", Callable(module, "apply_transform").bind(transform_id))
		button.connect("mouse_entered", Callable(module, "show_transform").bind(transform_id))
		button.connect("mouse_exited", Callable(module, "hide_transform"))
		
		if action:
			module.add_shortcut(action, "apply_transform", [transform_id], echo_action, button)
	if button_mode == "function":
		button.connect("pressed", Callable(module, function_name).bindv(params))
		
		if action:
			module.add_shortcut(action, function_name, params, echo_action, button)
