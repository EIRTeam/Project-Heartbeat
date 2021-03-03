extends "SineDrawerCPU.gd"

var trail_position setget set_trail_position
func set_trail_position(val):
	trail_position = val
	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_param("trail_position", val)

func _on_resized():
	line.width = 100.0
	position = game.remap_coords(note_data.position)
	scale = game.remap_coords(Vector2(1.0, 1.0)) - game.remap_coords(Vector2.ZERO)
func setup():
	.setup()
	line.texture = ResourcePackLoader.get_graphic("sustain_trail.png")
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line.default_color = Color.white
	line.material.shader = preload("res://rythm_game/SustainTrailShader.shader")
	line.material.set_shader_param("trail_color", ResourcePackLoader.get_note_trail_color(note_data.note_type))
