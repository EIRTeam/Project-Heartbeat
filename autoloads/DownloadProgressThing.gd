extends Control

var text setget set_text

class_name HBDownloadProgressThing

const ROTATION_SPEED = 90 # degrees a second
var spinning = false setget set_spinning
onready var label = get_node("Panel/Label")
onready var panel = get_node("Panel")
onready var icon_panel = get_node("Control")
onready var icon_texture_rect = get_node("Control/TextureRect")
export(float, EASE) var easing
signal disappear
func set_spinning(val):
	spinning = val
	if not spinning:
		icon_texture_rect.rect_rotation = 0.0

enum TYPE {
	NORMAL,
	ERROR,
	SUCCESS
}

var type_settings = {
	TYPE.NORMAL: {
		"icon": preload("res://graphics/icons/refresh-big.svg"),
		"bg_color": "#4f30ae",
		"border_color": "#2d1b61"
	},
	TYPE.ERROR: {
		"icon": preload("res://graphics/alert.svg"),
		"bg_color": "#ad3133",
		"border_color": "#611b1c"
	},
	TYPE.SUCCESS: {
		"icon": preload("res://graphics/check.svg"),
		"bg_color": "#103312",
		"border_color": "#35611b"
	}
}

var type setget set_type

const APPEAR_TIME = 0.4
var move_time = 1.5

var move_t = 0.0

var opacity_t_sign = -1.0
var target_offset = 0
var appear_t = 0.0
var move_start_position: Vector2
var move_target_position: Vector2
var disappearing = false
var life_timer = -1

const MARGIN = Vector2(50, -50)

func _process(delta):
	appear_t = clamp(appear_t+delta*opacity_t_sign, 0, APPEAR_TIME)
	modulate.a = clamp( appear_t / APPEAR_TIME, 0.0, 1.0)
	
	move_t = clamp(move_t+delta, 0, move_time)
	rect_position = move_start_position.linear_interpolate(move_target_position, ease(move_t / move_time, easing))
	if spinning:
		icon_texture_rect.rect_rotation += ROTATION_SPEED * delta
	if modulate.a == 0.0 and disappearing:
		queue_free()
	if life_timer != -1:
		life_timer -= delta
		if life_timer <= 0.0:
			disappear()
			life_timer = -1
	
func set_type(val):
	type = val
	var settings = type_settings[val]
	var stylebox = $Control.get_stylebox("panel") as StyleBoxFlat
	stylebox.bg_color = settings.bg_color
	stylebox.border_color = settings.border_color
	$Control/TextureRect.texture = settings.icon
	
func move_to(position: Vector2):
	pass

func set_text(val):
	text = val
	$Panel/Label.text = val
	$Panel.rect_size.x = $Panel/Label.get_minimum_size().x + 10

func _ready():
	set_type(TYPE.SUCCESS)
	modulate.a = 0.0

func move_to_offset(to_offset, time=0.75):
	var parent = get_parent()
	move_target_position = Vector2(0, parent.rect_size.y - to_offset) + MARGIN
	move_start_position = rect_position
	move_t = 0.0
	move_time = time
	target_offset = to_offset
func appear(to_offset: float):
	opacity_t_sign = 1.0
	modulate.a = 0.0
	appear_t = 0.0
	rect_position = Vector2(MARGIN.x, get_parent().rect_size.y)
	move_to_offset(to_offset)
func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float):
	var q0 = p0.linear_interpolate(p1, t)
	var q1 = p1.linear_interpolate(p2, t)
	var r = q0.linear_interpolate(q1, t)
	return r
func disappear():
	var parent = get_parent()
	move_time = 1.5
	move_to_offset(target_offset+50)
	opacity_t_sign = -1.0
	disappearing = true
	emit_signal("disappear")
