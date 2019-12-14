extends Node2D

const LASER_RES = 16

var positions = []

export(float) var phase_shift = 0.0
export(float) var frequency = 5.0
export(float) var timescale = 1.0

var t = 0.0

export(Color) var color = Color("#0567ff") setget set_color

func set_color(val):
	color = val
	$LineGlow.default_color = val
	
func _ready():
	set_color(color)


# Interpolates from a to b along a sine wave
static func sin_pos_interp(from: Vector2, to: Vector2, amplitude: float, frequency: float, value: float, phase_shift_angle: float = 0.0) -> Vector2:
	var dist = (from - to).length()
	var period = 1/frequency
	var phase_shift = (phase_shift_angle/180.0)*(period)
	if dist != 0:
		var t = value * dist
		var x = t
		var angle = from.angle_to_point(to)
		var y = amplitude * sin((((t/dist) + phase_shift)*(PI*frequency)))
		var xp = (x * cos(angle)) - (y * sin(angle))
		var yp = (x * sin(angle)) + (y * cos(angle))
		return from-Vector2(xp, yp)
	else:
		return to
	
func _process(delta):
	var new_points = PoolVector2Array()
	for i in range(positions.size()):
		if i < positions.size()-1:
			var current_position = positions[i]
			var target_position = positions[i+1]
			for laser_i in range(LASER_RES+1):
				new_points.append(sin_pos_interp(current_position, target_position, 5, frequency, laser_i/float(LASER_RES), phase_shift + t*360 * timescale))
	$LineGlow.points = new_points
	$Line2D.points = new_points
	t += delta
