extends Control

class_name HBStatsHistogram

var offset_map := PackedFloat32Array():
	set(val):
		offset_map = val
		_queue_mesh_update()
var histogram_material := ShaderMaterial.new()
@onready var multimesh := MultiMeshInstance2D.new()

var mean: float:
	set(val):
		mean = val
		_queue_text_update()

var median: float:
	set(val):
		median = val
		_queue_text_update()

var std_dev: float:
	set(val):
		std_dev = val
		_queue_text_update()

@onready var mean_label: Label = get_node("%MeanLabel")
@onready var median_label: Label = get_node("%MedianLabel")
@onready var std_dev_label: Label = get_node("%StdDevLabel")

var text_update_queued := false
func _queue_text_update():
	if not text_update_queued:
		text_update_queued = true
		if not is_node_ready():
			await ready
		_update_text.call_deferred()

func _update_text():
	text_update_queued = false
	mean_label.text = tr(&"Mean: {mean_in_ms} ms", &"Results screen stats tab mean").format({"mean_in_ms": "%.2f" % mean})
	median_label.text = tr(&"Median: {median_in_ms} ms", &"Results screen stats tab median").format({"median_in_ms": "%.2f" % median})
	std_dev_label.text = tr(&"Std Dev: {std_dev_label} ms", &"Results screen stats tab std dev").format({"std_dev_label": "%.2f" % std_dev})
	queue_redraw()

var mesh_update_queued := false
func _queue_mesh_update():
	if not mesh_update_queued:
		mesh_update_queued = true
		if not is_node_ready():
			await ready
		_update_mesh.call_deferred()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	histogram_material.shader = preload("res://rythm_game/results_screen/stats_histogram.gdshader")
	histogram_material.set_shader_parameter("global_position", global_position)
	histogram_material.set_shader_parameter("size", size)
	
	multimesh.multimesh = MultiMesh.new()
	multimesh.material = histogram_material
	multimesh.show_behind_parent = true
	add_child(multimesh)

	
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	var colors_darker := PackedColorArray()
	for i in range(HBJudge.JUDGE_RATINGS.size()-1):
		var offset := (32.0 * i)
		var color := Color(HBJudge.RATING_TO_COLOR[i+1])
		offsets.push_back(offset / 256.0)
		colors.push_back(color)
		colors_darker.push_back(color.darkened(0.5))
		if i > 0:
			offsets.push_back(1.0 - (offset / 256.0))
			colors.push_back(Color(HBJudge.RATING_TO_COLOR[i]))
			colors_darker.push_back(Color(HBJudge.RATING_TO_COLOR[i]).darkened(0.5))
	var gradient_tex := GradientTexture1D.new()
	gradient_tex.gradient = Gradient.new()
	var gradient := gradient_tex.gradient
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = offsets
	gradient.colors = colors
	
	var gradient_tex_darker := GradientTexture1D.new()
	gradient_tex_darker.gradient = gradient.duplicate()
	gradient_tex_darker.gradient.colors = colors_darker
	histogram_material.set_shader_parameter("color_gradient_top", gradient_tex)
	histogram_material.set_shader_parameter("color_gradient_bottom", gradient_tex_darker)
	#const TEST_SIZE := 4000
	#
	#const TEST_MAX_T := 100_000
	#
	#offset_map.resize(TEST_SIZE)
	#
	#for i in range(TEST_SIZE):
		#offset_map[i] = randf_range(-128.0, 128.0)
	#_update_mesh.call_deferred()
	#_update_multimesh_scale_and_params.call_deferred()
	resized.connect(_update_multimesh_scale_and_params)

func _update_multimesh_scale_and_params():
	const TOP_MARGIN := 0.25
	const SIZE := 1.0 - TOP_MARGIN
	multimesh.global_position = global_position + Vector2(0.0, size.y*TOP_MARGIN)
	multimesh.scale = size * Vector2(1.0, SIZE)
	histogram_material.set_shader_parameter("global_position", global_position + Vector2(0.0, size.y*TOP_MARGIN))
	histogram_material.set_shader_parameter("size", size * Vector2(1.0, SIZE))

func _update_mesh() -> void:
	mesh_update_queued = false
	multimesh.multimesh = null
	
	if offset_map.is_empty():
		print("OFFSETTI!")
		return
	
	var ref_size := size
	var center := ref_size * 0.5
	const MARGIN = 2.0
	const TOTAL_BUCKETS := 256.0 / 8.0
	
	var buckets := PackedInt32Array()
	buckets.resize(TOTAL_BUCKETS)
	
	var count_max := 0
	
	for offset in offset_map:
		var i: int = min(((offset+128.0) / 256.0) * (TOTAL_BUCKETS), TOTAL_BUCKETS-1)
		buckets[i] += 1
		count_max = max(buckets[i], count_max)
	
	
	var bar_size := ((ref_size.x / TOTAL_BUCKETS)) - (MARGIN*2.0)
	var bucket_r_y := ref_size.y / count_max
	
	var mm := MultiMesh.new()
	mm.instance_count = buckets.size()
	var qm := QuadMesh.new()
	mm.mesh = qm
	qm.size.x = 1
	qm.size.y = 1
	qm.center_offset = Vector3(qm.size.x * 0.5, qm.size.y * 0.5, 0.0)
	
	for i in range(buckets.size()):
		var count := buckets[i]
		var rect_origin := Vector2(bar_size * i + (i*MARGIN*2), ref_size.y - bucket_r_y * count)
		rect_origin.x += MARGIN
		var rect_size := Vector2(bar_size, bucket_r_y*count)
		var trf := Transform2D()
		trf = trf.scaled(rect_size / ref_size)
		trf.origin = rect_origin / ref_size
		mm.set_instance_transform_2d(i, trf)
	multimesh.multimesh = mm


func _draw_time_line(time: float, color: Color, width := 6.0):
	var x := time
	x += 128.0
	x /= 256.0
	var s := Vector2(x * size.x, 0.0)
	draw_dashed_line(s, s + Vector2(0.0, size.y), color, width, 24.0)

func _draw() -> void:
	# mean
	_draw_time_line(mean, Color.RED)
	#median
	_draw_time_line(median, Color.GREEN)
	#std dev
	_draw_time_line(mean + std_dev, Color.PURPLE)
	_draw_time_line(mean - std_dev, Color.PURPLE)
