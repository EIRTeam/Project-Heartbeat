extends Control

class_name HBDownloadProgressThing

var text : set = set_text

const ROTATION_SPEED = 90 # degrees a second
var spinning = false: set = set_spinning
@onready var label = get_node("Panel/Label")
@onready var panel = get_node("Panel")
@onready var icon_panel = get_node("Control")
@onready var icon_texture_rect = get_node("Control/TextureRect")
@onready var progress_bar = get_node("%ProgressBar")
@export_exp_easing var easing # (float, EASE)
signal disappeared
func set_spinning(val):
	spinning = val
	if not spinning:
		icon_texture_rect.rotation = 0.0

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

var type : set = set_type

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
	position = move_start_position.lerp(move_target_position, ease(move_t / move_time, easing))
	if spinning:
		icon_texture_rect.rotation += ROTATION_SPEED * delta
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
	var stylebox = $Control.get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.bg_color = settings.bg_color
	stylebox.border_color = settings.border_color
	$Control/TextureRect.texture = settings.icon
	
func move_to(position: Vector2):
	pass

func set_text(val):
	text = val
	$Panel/Label.text = text
	recalculate_label_size()
	var minimum_size = $Panel/Label.get_minimum_size().x
	if $Panel/Label.autowrap_mode != TextServer.OVERRUN_NO_TRIM:
		if get_parent():
			minimum_size = get_parent().size.x / 2.0
	$Panel.size.x = minimum_size
	$Panel/Label.size.y = 0
	
func _ready():
	set_type(TYPE.SUCCESS)
	modulate.a = 0.0
	get_viewport().connect("size_changed", Callable(self, "_on_vp_size_changed"))
	recalculate_label_size()
	
func _on_vp_size_changed():
	await get_tree().process_frame
	move_to_offset(target_offset)
	move_t = move_time
	
func recalculate_label_size():
	if label:
		label.autowrap_mode = TextServer.OVERRUN_NO_TRIM
		var size = label.get_combined_minimum_size()
		if size.x > (get_parent().size.x / 2.0):
			label.autowrap_mode = TextServer.OVERRUN_ADD_ELLIPSIS
			label.size.x = get_parent().size.x / 2.0
		
func move_to_offset(to_offset, time=0.75):
	var parent = get_parent()
	move_target_position = Vector2(0, parent.size.y - to_offset) + MARGIN
	move_start_position = position
	move_t = 0.0
	move_time = time
	target_offset = to_offset
func appear(to_offset: float):
	opacity_t_sign = 1.0
	modulate.a = 0.0
	appear_t = 0.0
	position = Vector2(MARGIN.x, get_parent().size.y)
	move_to_offset(to_offset)

func disappear():
	move_time = 1.5
	move_to_offset(target_offset+50)
	opacity_t_sign = -1.0
	disappearing = true
	emit_signal("disappeared")

func set_progress(val: float):
	progress_bar.value = val
