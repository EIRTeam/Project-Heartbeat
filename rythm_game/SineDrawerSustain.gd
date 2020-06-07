extends "SineDrawerCPU.gd"

var trail_position setget set_trail_position
func set_trail_position(val):
	trail_position = val
	var shad_mat = material as ShaderMaterial
	shad_mat.set_shader_param("trail_position", val)

func _on_resized():
	line1.width = 100.0
	position = game.remap_coords(note_data.position)
	scale = game.remap_coords(Vector2(1.0, 1.0)) - game.remap_coords(Vector2.ZERO)
#	line1.width = (scale.length() / 1.0) * 80.0
func setup():
	.setup()
	line1.texture = preload("res://graphics/Sustain_trail.png")
	line1.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	line1.default_color = Color.white
	material.shader = preload("res://rythm_game/SustainTrailShader.shader")
	line2.hide()
	material.set_shader_param("trail_color", IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)))
