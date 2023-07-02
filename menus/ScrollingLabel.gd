extends Control


@export var font_1: FontFile
@export var font_2: FontFile

@export var text_1: String = "asd": set = set_text_1
@export var text_2: String = "asd": set = set_text_2

@onready var movement_tween := Threen.new()

var text_x_offset := 0.0

var margin := 15.0

const FADE_SIZE := 20

const DURATION_FACTOR := 100.0

const TRANSITION_TYPE = Threen.TRANS_SINE

func set_text_1(value):
	text_1 = value
	if movement_tween in get_children():
		_on_text_updated()
func set_text_2(value):
	text_2 = value
	if movement_tween in get_children():
		_on_text_updated()
	
func get_text_margin() -> float:
	if text_1.length() == 0 or text_2.length() == 0:
		return 0.0
	else:
		return margin
	
func _on_text_updated():
	movement_tween.remove_all()
	var size_1 := font_1.get_string_size(text_1)
	var size_2 := font_2.get_string_size(text_2)
	
	var total_size = size_1.x + margin + size_2.x
	
	var mat = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("enabled", total_size > size.x)
	
	text_x_offset = 0.0
	
	if total_size > size.x:
		text_x_offset = 0.0 + FADE_SIZE
		queue_redraw()
		move_left(total_size)
		movement_tween.start()
	else:
		queue_redraw()
func _ready():
	print(material)
	connect("resized", Callable(self, "_on_resized"))
	add_child(movement_tween)
	movement_tween.connect("tween_all_completed", Callable(self, "_on_tween_all_completed"))
	movement_tween.connect("tween_step", Callable(self, "_on_tween_step"))
	_on_resized()
func _on_tween_step(object, key, elapsed, value):
	queue_redraw()
	
func get_duration(total_size):
	return total_size / DURATION_FACTOR
	
func move_left(size_X):
	movement_tween.interpolate_property(self, "text_x_offset", 0.0 + FADE_SIZE, size.x - size_X - FADE_SIZE, get_duration(size_X), TRANSITION_TYPE)
func move_right(size_X):
	movement_tween.interpolate_property(self, "text_x_offset", size.x - size_X - FADE_SIZE, 0.0 + FADE_SIZE, get_duration(size_X), TRANSITION_TYPE)
func _on_tween_all_completed():
	var size_1 := font_1.get_string_size(text_1)
	var size_2 := font_2.get_string_size(text_2)

	var total_size = size_1.x + margin + size_2.x
	if text_x_offset < 0.0:
		move_right(total_size)
	else:
		move_left(total_size)
	movement_tween.start()
func _draw():
	var size_1 := font_1.get_string_size(text_1)
	var size_2 := font_2.get_string_size(text_2)
	var text_1_pos = Vector2(text_x_offset, size.y/2.0)
	var text_2_pos = Vector2(text_x_offset, 0.0)
	text_2_pos.x += size_1.x
	text_2_pos.x += margin
	
	var y_pos = max(size.y / 2.0 + size_2.y / 4.0, size.y / 2.0 + size_1.y / 4.0)
	
	text_2_pos.y = y_pos
	text_1_pos.y = y_pos
	draw_string(font_1, text_1_pos, text_1)
	draw_string(font_2, text_2_pos, text_2)
	var mat = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("size", size)
		mat.set_shader_parameter("pos", global_position)
		mat.set_shader_parameter("res", get_viewport_rect().size)
func _on_resized():
	var mat = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("fade_size", FADE_SIZE / float(size.x))
	_on_text_updated()
