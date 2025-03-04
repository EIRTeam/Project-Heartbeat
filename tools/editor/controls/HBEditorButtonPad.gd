extends HBEditorButton

class_name HBEditorButtonPad

signal hover_changed(direction: int)

@onready var button_pad_shader: Shader = preload("res://tools/editor/controls/button_pad_shader.gdshader")

@export_category("UI")
@export_custom(PROPERTY_HINT_RANGE, "1,10,1,or_greater") var pad_division: int = 3 : 
	set(v): 
		pad_division = max(v, 1)

var highlight_idx := Vector2.ZERO
var _pressed = false

func _ready() -> void:
	super._ready()
	
	button.material = ShaderMaterial.new()
	button.material.shader = button_pad_shader
	
	button.theme_changed.connect(_theme_changed)
	_theme_changed()
	
	self._set_texture(self.texture)
	
	button.gui_input.connect(button_gui_input)
	button.mouse_entered.connect(button_mouse_entered)
	button.mouse_exited.connect(button_mouse_exited)
	button.button_down.connect(button_pressed)
	button.button_up.connect(button_released)

var pressed_callback: Callable
func set_module(_module) -> void:
	module = _module
	
	if button_mode == "transform":
		pressed_callback = Callable(module, "apply_transform").bind(transform_id)
	if button_mode == "function":
		pressed_callback = Callable(module, function_name).bindv(params)
	
	if disable_when_playing:
		module.editor.disable_ui.connect(self._disable_button)
		module.editor.enable_ui.connect(self._enable_button)
	elif disable_with_popup:
		module.editor.disable_extended_ui.connect(self._disable_button)
		module.editor.enable_extended_ui.connect(self._enable_button)
	
	#if action:
		#module.add_shortcut(action, function_name, params, echo_action, button)

func _theme_changed():
	button.material.set_shader_parameter("pressed_color", button.get_theme_color("icon_pressed_color"))
	button.material.set_shader_parameter("disabled_color", button.get_theme_color("icon_disabled_color"))

# This version of _set_texture doesnt set the button icon, only the shader icon.
func _set_texture(new_texture: CompressedTexture2D):
	if button and button.material:
		button.material.set_shader_parameter("icon_texture", new_texture)

func _disable_button():
	if button and button.material:
		button.material.set_shader_parameter("disabled", true)

func _enable_button():
	if button and button.material:
		button.material.set_shader_parameter("disabled", false)

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
	var _highlight_idx = floor(normalized_mouse_pos * self.pad_division)
	
	_highlight_idx.x = clamp(_highlight_idx.x, 0, self.pad_division - 1)
	_highlight_idx.y = clamp(_highlight_idx.y, 0, self.pad_division - 1)
	
	if highlight_idx != _highlight_idx:
		highlight_idx = _highlight_idx
		
		# The default editor Focus Trap has to be disabled here, because if the
		# signal triggers a focus loss the button will be release instantly,
		# preventing the hover state from showing correctly.
		module.toggle_focus_loss()
		
		hover_changed.emit(highlight_idx.y * self.pad_division + highlight_idx.x)
		
		module.toggle_focus_loss()
	
	var highlight_pos = highlight_idx / (self.pad_division - 1)
	button.material.set_shader_parameter("highlight_pos", highlight_pos)
	button.material.set_shader_parameter("highlight_idx", highlight_idx)
	button.material.set_shader_parameter("highlight_area_size", 1.0 / self.pad_division)
	
	if button_mode == "transform":
		module.transforms[transform_id].set("hover_position", highlight_idx)

func button_mouse_entered():
	button.material.set_shader_parameter("hover", true)
	
	if button_mode == "transform":
		module.show_transform(transform_id)
	
	hover_changed.emit(highlight_idx.y * self.pad_division + highlight_idx.x)

func button_mouse_exited():
	button.material.set_shader_parameter("hover", false)
	
	if button_mode == "transform":
		module.hide_transform(transform_id)

func button_pressed():
	button.material.set_shader_parameter("pressed", true)
	
	_pressed = true
	
	if pressed_callback:
		# The default editor Focus Trap has to be disabled here, because if the
		# called function triggers a focus loss the button will be release instantly,
		# preventing the pressed state from showing correctly.
		module.toggle_focus_loss()
		
		if button_mode == "function":
			pressed_callback.call(highlight_idx.y * self.pad_division + highlight_idx.x)
		else:
			pressed_callback.call()
		
		module.toggle_focus_loss()


func button_released():
	button.material.set_shader_parameter("pressed", false)
	
	_pressed = false
	self.button_gui_input(InputEventMouseMotion.new())
