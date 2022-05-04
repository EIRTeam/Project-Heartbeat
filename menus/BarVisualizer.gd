extends Control

const DEFINITION = 256

const COLOR_LUT: Texture = preload("res://graphics/logo_visualizer_color_lut.png")
var lut_img: Image = COLOR_LUT.get_data()
var snapshot: HBSpectrumSnapshot

func _ready():
	snapshot = HBGame.spectrum_snapshot
	
func _process(delta: float):
	update()
#	$Sprite.scale = $Sprite.scale.linear_interpolate(Vector2.ONE + Vector2.ONE * range_lerp(avg, 0.0, 1.0, 0.0, 0.5), delta * 16)
#	$Sprite.scale = $Sprite.scale.linear_interpolate(Vector2.ONE * 0.75 + (Vector2.ONE * 0.4) * range_lerp(avg, 0.0, 1.0, 0.0, 0.5), delta * 16)

const VISUALIZER_ROUNDS = 5
const BARS_PER_VISUALIZER = 200
var inside_percentage := 0.4
	
func _draw():
	var inside_radius := inside_percentage * rect_size.x * 0.5
	var width := (2 * PI * inside_radius) / BARS_PER_VISUALIZER
	
	var rot_extra = deg2rad(fmod(10.0 * (OS.get_ticks_msec() / 1000.0), 360.0))
	
	for j in range(VISUALIZER_ROUNDS):
		for i in range(BARS_PER_VISUALIZER):
			
			var magnitude := snapshot.get_value_at_i(i)
			var energy = magnitude
			
			var rotation = deg2rad(i / float(BARS_PER_VISUALIZER) * 360.0 + j * 360.0 / float(VISUALIZER_ROUNDS))
			var r = Vector2.RIGHT * (inside_percentage * (rect_size.x * 0.5))
			var r2 = r + Vector2(energy * ((1.0 - inside_percentage) * (rect_size.x * 0.5)), 0.0)
			r = r.rotated(rotation)
			r2 = r2.rotated(rotation)
			r += rect_size * 0.5
			r2 += rect_size * 0.5
			lut_img.lock()
			var col := lut_img.get_pixel(i % 32, 0)
			col.a = (0.1 * energy) + energy * 0.75
			lut_img.unlock()
			draw_line(rect_size * 0.5, r2, col, width, true)
	
