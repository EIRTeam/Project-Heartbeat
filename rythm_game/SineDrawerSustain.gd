extends "SineDrawerCPU.gd"

class_name SineDrawerSustain

var trail_position : set = set_trail_position
func set_trail_position(val):
	trail_position = val
	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_parameter("trail_position", val)

func _on_resized():
	line.width = 100.0
	position = note_data.position
func setup():
	super.setup()
	line.texture = ResourcePackLoader.get_graphic("sustain_trail.png")
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.default_color = Color.WHITE
	line.material.shader = preload("res://rythm_game/SustainTrailShader.gdshader")
	line.material.set_shader_parameter("trail_color", ResourcePackLoader.get_note_trail_color(note_data.note_type))
