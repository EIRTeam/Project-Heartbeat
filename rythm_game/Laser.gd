extends Node2D

class_name MultiLaser

const LASER_RES = 16

var positions = []: set = set_positions
var line_2ds = []
@export var disable_animation: bool = false
@export var phase_shift: float = 0.0
@export var frequency: float = 5.0
@export var timescale: float = 1.0
var width_scale = 1.0: set = set_width_scale
var t = 0.0

@export var color: Color = Color("#0567ff"): set = set_color

func set_color(val):
	color = val
	
func _ready():
	set_color(color)
	modulate.a = UserSettings.user_settings.multi_laser_opacity
	z_index = -2
	z_as_relative = false
func set_positions(val):
	positions = val
	while line_2ds.size() < positions.size():
		var line_2d = Line2D.new()
		line_2d.texture = ResourcePackLoader.get_graphic("multi_laser.png")
		line_2d.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
		line_2d.texture_mode = Line2D.LINE_TEXTURE_STRETCH
		
		line_2d.default_color = Color.WHITE
		if not disable_animation:
			line_2d.material = preload("res://rythm_game/Laser_material.tres")
		add_child(line_2d)
		line_2ds.append(line_2d)
		
func set_width_scale(val):
	for line in line_2ds:
		line.width = 30 * val
	
func _process(delta):
	t += delta
	for i in range(positions.size()):
		if i < positions.size()-1:
			var current_position = positions[i]
			var target_position = positions[i+1]
			var line_2d = line_2ds[i] as Line2D
			line_2d.set_point_position(0, current_position)
			line_2d.set_point_position(1, target_position)
