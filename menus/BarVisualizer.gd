extends Control

const DEFINITION = 256

const COLOR_LUT: Texture2D = preload("res://graphics/logo_visualizer_color_lut.png")
var lut_img: Image = COLOR_LUT.get_image()
var snapshot: HBSpectrumSnapshot

@onready var multi_mesh_instance := MultiMeshInstance2D.new()
@onready var multi_mesh := MultiMesh.new()
@onready var quad_mesh := QuadMesh.new()

var color_lut := []

func _ready():
	snapshot = HBGame.spectrum_snapshot
	add_child(multi_mesh_instance)
	#multi_mesh.color_format = MultiMesh.COLOR_FLOAT
	multi_mesh.use_colors = true
	multi_mesh_instance.multimesh = multi_mesh
	multi_mesh.instance_count = VISUALIZER_ROUNDS * BARS_PER_VISUALIZER
	multi_mesh.mesh = quad_mesh
	
	connect("resized", Callable(self, "_on_resized"))
	call_deferred("_on_resized")
	# Cache the LUT now so we don't have to lock the VisualServer
	var img := COLOR_LUT.get_image()
	false # img.lock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for i in range(img.get_width()):
		color_lut.append(img.get_pixel(i, 0))
	false # img.unlock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
		
func _process(delta: float):
	for j in range(VISUALIZER_ROUNDS):
		for i in range(BARS_PER_VISUALIZER):
			var trf := Transform2D.IDENTITY
			var magnitude := snapshot.get_value_at_i(i)
			var energy = magnitude

			var rotation = deg_to_rad(i / float(BARS_PER_VISUALIZER) * 360.0 + j * 360.0 / float(VISUALIZER_ROUNDS))
			var r = Vector2.RIGHT * (inside_percentage * (size.x * 0.5))
			var r2 = r + Vector2(energy * ((1.0 - inside_percentage) * (size.x * 0.5)), 0.0)
			trf = trf.scaled(Vector2(1.0 + r2.x, 1.0))
			trf = trf.rotated(rotation)
			var instance_i := (j*BARS_PER_VISUALIZER) + i
			multi_mesh.set_instance_transform_2d(instance_i, trf)
			var col := color_lut[i % color_lut.size()] as Color
			col.a = (0.1 * energy) + energy * 0.5
			multi_mesh.set_instance_color(instance_i, col)

const VISUALIZER_ROUNDS = 5
const BARS_PER_VISUALIZER = 200
var inside_percentage := 0.4
	
func _on_resized():
	var inside_radius := inside_percentage * size.x * 0.5
	var width := (2 * PI * inside_radius) / BARS_PER_VISUALIZER
	quad_mesh.size.y = width
	quad_mesh.center_offset = Vector3(quad_mesh.size.x / 2.0, 0, 0)
	multi_mesh_instance.position = size * 0.5
