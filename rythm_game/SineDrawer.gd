extends MeshInstance2D

const BASE_SIZE = 128

var distance: float = 300.0
var thickness: float = 0.002
var amplitude = 100.0
var color_start: Color = Color.green
var color_end: Color = Color.yellow
var time: float = 0.5 setget set_time
var height = 1080
var margin = 0.0
var leading_enabled: bool = false
func set_time(val):
	time = val
	var mat = material as ShaderMaterial
	mat.set_shader_param("time", time)

var frequency: float = 2.0

func get_scaled_thickness():
	var max_height = amplitude
	var thick_scale = 1.0 - (max_height / 1080.0)
	print("AMP ", amplitude, " thick_scale ", thick_scale, "thick", thickness)
	return thick_scale*thickness
func update_shader_values():
	var mat = material as ShaderMaterial
	mat.set_shader_param("thickness", thickness)
	mat.set_shader_param("amplitude", amplitude)
	mat.set_shader_param("size", Vector2(distance, height))
	mat.set_shader_param("color_start", color_start)
	mat.set_shader_param("color_end", color_end)
	mat.set_shader_param("time", time)
	mat.set_shader_param("frequency", frequency)
	mat.set_shader_param("margin", margin)
	mat.set_shader_param("leading_enabled", leading_enabled)
func reconstruct_mesh():
	var m = mesh as ArrayMesh
	var arrays = mesh.surface_get_arrays(0)
	var new_vertices = PoolVector2Array()
	var length = distance
	var real_height = height / 2.0
	new_vertices.push_back(Vector2(length, real_height))
	new_vertices.push_back(Vector2(-length, real_height))
	new_vertices.push_back(Vector2(-length, -real_height))
	new_vertices.push_back(Vector2(length, -real_height))

	arrays[Mesh.ARRAY_VERTEX] = new_vertices
	m.surface_remove(0)
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	update()
func _draw():
	pass
#	draw_line(Vector2(0,0), Vector2(distance, 0.0), Color.yellow, 10.0)
func _ready():
	reconstruct_mesh()
	update_shader_values()
