extends Button

class_name HBHovereableButton

@export var normal_style: StyleBox = preload("res://styles/PanelStyleTransparentIcon.tres")
@export var hover_style: StyleBox = preload("res://styles/PanelStyleTransparentIconHover.tres")
@export var hover_style_animation: StyleBox = preload("res://styles/PanelStyleTransparentHoverAnimation.tres")

signal hovered

class ButtonHoverAnimationProxy:
	extends Control
	var animation_stylebox: StyleBox
	
	func _init(_animation_stylebox: StyleBox):
		animation_stylebox = _animation_stylebox
	func _draw():
		animation_stylebox.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

@onready var button_hover_animation_proxy: ButtonHoverAnimationProxy

var target_opacity = 1.0

const LERP_SPEED = 3.0
	
func _process(delta):
	modulate.a = lerp(modulate.a, target_opacity, LERP_SPEED*delta)
	button_hover_animation_proxy.modulate.a = sin((Time.get_ticks_msec()/1000.0) * PI / 1.0) / 2.0 + 0.5
	button_hover_animation_proxy.modulate.a *= 0.75
	button_hover_animation_proxy.modulate.a += 0.25
	button_hover_animation_proxy.show_behind_parent = true
	#button_hover_animation_proxy.modulate.a = 0.0

func hover():
	add_theme_stylebox_override("normal", hover_style)
	emit_signal("hovered")
	button_hover_animation_proxy.show()
	button_hover_animation_proxy.queue_redraw()
func stop_hover():
	add_theme_stylebox_override("normal", normal_style)
	button_hover_animation_proxy.hide()

func _ready():
	button_hover_animation_proxy = ButtonHoverAnimationProxy.new(hover_style_animation)
	add_child(button_hover_animation_proxy)
	button_hover_animation_proxy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button_hover_animation_proxy.hide()
	stop_hover()
	add_theme_stylebox_override("hover", hover_style)
	focus_mode = FOCUS_NONE
