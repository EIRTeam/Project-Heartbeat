extends Node2D

class_name SineDrawerCPU

var note_data: HBBaseNote

var time_out
var game

var time = 0.0: set = set_time

var line = Line2D.new()
var trail_margin = 0.0: set = set_trail_margin
func set_time(val):
	time = val
	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_parameter("time", time)
func set_trail_margin(val):
	trail_margin = val
	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_parameter("trail_margin", val)
	
func _init():
	name = "SineDrawerCPU"
	
func contrast(p_color: Color):
	var color = Color(p_color)
	color.r = fmod(color.r + 0.5, 1.0);
	color.g = fmod(color.g + 0.5, 1.0);
	color.b = fmod(color.b + 0.5, 1.0);
	return color
func generate_trail_points():
	var points = game.get_note_trail_points(note_data)
	line.points = points.points1
	var color = ResourcePackLoader.get_note_trail_color(note_data.note_type)
	var color_late = contrast(color)
	var color_early = color
	color_late.a = 0.0
	color_early.a = 0.7

	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_parameter("color_start", color_early)
	shad_mat.set_shader_parameter("color_end", color_late)
	shad_mat.set_shader_parameter("texture_scale", note_data.oscillation_frequency*2)
	
	_on_resized()
	
func _on_resized():
	position = note_data.position
	var factor = 40
#	print(game.remap_coords(Vector2(1920/2, 1080/2)))
	line.width = scale.x * factor

func setup():
	var new_material = ShaderMaterial.new()
	new_material.shader = preload("res://rythm_game/CPUTrailShader.gdshader")
	line.material = new_material
	
	line.texture = ResourcePackLoader.get_graphic("note_trail.png")
	
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	if not line in get_children():
		add_child(line)

	generate_trail_points()
	line.material.set_shader_parameter("leading", float(int(UserSettings.user_settings.leading_trail_enabled)))
	z_index = -2
	z_as_relative = false
func _ready():
	setup()
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(line) and not line.is_queued_for_deletion():
			line.queue_free()

#	scale = Vector2(game.get_note_scale(), game.get_note_scale())
