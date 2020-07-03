extends Node2D

class_name SineDrawerCPU

var note_data: HBBaseNote

var points: PoolVector2Array
var points2: PoolVector2Array
var points_leading: PoolVector2Array

var time_out
var game

var time = 0.0 setget set_time

var line = Line2D.new()
var trail_margin = 0.0 setget set_trail_margin
func set_time(val):
	time = val
	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_param("time", time)
func set_trail_margin(val):
	trail_margin = val
	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_param("trail_margin", val)
	
func generate_trail_points():
	var points = game.get_note_trail_points(note_data)
	line.points = points.points1
	var color_late = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)).contrasted()
	var color_early = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	color_late.a = 0.0
	color_early.a = 0.7

	var shad_mat = line.material as ShaderMaterial
	shad_mat.set_shader_param("color_start", color_early)
	shad_mat.set_shader_param("color_end", color_late)
	shad_mat.set_shader_param("texture_scale", note_data.oscillation_frequency*2)
	
	_on_resized()
	
func _on_resized():
	var shad_mat = line.material as ShaderMaterial
	position = game.remap_coords(note_data.position)
	scale = game.remap_coords(Vector2(1.0, 1.0)) - game.remap_coords(Vector2.ZERO)
	var factor = 40
#	print(game.remap_coords(Vector2(1920/2, 1080/2)))
	line.width = scale.x * factor

func setup():
	var new_material = ShaderMaterial.new()
	new_material.shader = preload("res://rythm_game/CPUTrailShader.shader")
	line.material = new_material
	
	line.texture = preload("res://graphics/sine_wave.svg")
	
	line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	
	add_child(line)

	generate_trail_points()
	line.material.set_shader_param("leading", float(int(UserSettings.user_settings.leading_trail_enabled)))
	z_index = -1
func _ready():
	setup()

#	scale = Vector2(game.get_note_scale(), game.get_note_scale())
