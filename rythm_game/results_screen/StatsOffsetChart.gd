extends Control

class_name HBStatsOffsetChart

var task_id: int

@onready var offset_point_material := ShaderMaterial.new()

class SectionData:
	var section_name: String
	var section_color: Color

var multi_meshes: Array[MultiMeshInstance2D]

var hover_rects: Array[HBResultsScreenHoverRect]

var offset_map_times: PackedInt32Array:
	set(val):
		offset_map_times = val
		_queue_points_update()
		
var offset_map: PackedFloat32Array:
	set(val):
		offset_map = val
		_queue_points_update()

var judgement_map: PackedByteArray:
	set(val):
		judgement_map = val
		_queue_points_update()

var song: HBSong:
	set(val):
		song = val
		queue_redraw()

var end_time: int:
	set(val):
		end_time = val
		queue_redraw()

var min_time := 0
var max_time := 1

var points_update_queued := false
func _queue_points_update():
	if not points_update_queued:
		points_update_queued = true
		if not is_node_ready():
			await ready
		_update_points.call_deferred()
		
func _update_points():
	points_update_queued = false
	assert(offset_map_times.size() == offset_map.size() and offset_map.size() == judgement_map.size())
	if offset_map.size() > 0:
		task_id = WorkerThreadPool.add_task(_generate_multi_mesh.bind(offset_map_times, offset_map))
func _draw() -> void:
	var center := size * 0.5
	_update_material()
	
	if song:
		if hover_rects.size() != song.sections.size():
			for rect in hover_rects:
				rect.queue_free()
			hover_rects.clear()
			for section: HBChartSection in song.sections:
				var rect := HBResultsScreenHoverRect.new()
				rect.hover_text = section.name
				add_child(rect)
				hover_rects.push_back(rect)
		for i in range(song.sections.size()):
			var section: HBChartSection = song.sections[i]
			var section_start := remap(section.time, min_time, max_time, 0.0, 1.0)
			var section_end := 1.0
			
			if i < song.sections.size()-1:
				section_end = remap(song.sections[i+1].time, min_time, max_time, 0.0, 1.0)
			
			var rect_size_x := (section_end - section_start) * size.x
			var rect_size_y := size.y
			var rect_size := Vector2(rect_size_x, rect_size_y)
			var rect_color := section.color
			rect_color.a *= 0.25
			draw_rect(Rect2(Vector2(section_start * size.x, 0.0), rect_size), rect_color)
			
			var line_start := Vector2(size.x * section_start, 0.0)
			var line_end := line_start + Vector2(0.0, size.y)
			draw_line(line_start, line_end, section.color, 3.0)
	
			hover_rects[i].position = line_start
			hover_rects[i].size = rect_size
	for i in range(0, HBJudge.JUDGE_RATINGS.size()-2, 1):
		var color := Color(HBJudge.RATING_TO_COLOR[HBJudge.JUDGE_RATINGS.size() - i - 1])
		color = color.darkened(0.25)
		var window := 32.0 + 32.0 * i as float
		var window_offset := window / 128.0
		window_offset *= size.y * 0.5
		var window_size := 32.0 / 128.0
		window_size *= size.y * 0.5
		var rect_origin := Vector2(0.0, center.y - window_offset)
		var rect_size := Vector2(size.x, window_size)
		draw_line(rect_origin, rect_origin + Vector2(rect_size.x, 0.0), color, 3.0)
		#draw_rect(Rect2(rect_origin, rect_size), color)
		rect_origin = Vector2(0.0, center.y + window_offset)
		draw_line(rect_origin, rect_origin + Vector2(rect_size.x, 0.0), color, 3.0)
		#draw_rect(Rect2(rect_origin, rect_size), color)
		color.a = 1.0
	draw_line(Vector2(0.0, size.y * 0.5), Vector2(0.0, size.y * 0.5) + Vector2(size.x, 0.0), Color.WHITE.darkened(0.5), 3.0)

func _update_material():
	offset_point_material.set_shader_parameter(&"size", size)
	offset_point_material.set_shader_parameter(&"global_position", global_position)
	for mesh in multi_meshes:
		mesh.scale = Vector2.ONE
func _on_multi_mesh_generated(result: Array[MultiMesh]):
	for i in range(result.size()):
		var mm := result[i]
		var mm_2d := multi_meshes[i]
		mm_2d.multimesh = mm
		mm_2d.material = offset_point_material
		mm_2d.modulate = Color(HBJudge.RATING_TO_COLOR[i])
	WorkerThreadPool.wait_for_task_completion(task_id)
	queue_redraw()

func _generate_multi_mesh(offset_map_times: PackedInt32Array, offset_map: PackedFloat32Array):
	var result_meshes: Array[MultiMesh]
	var quad_mesh := PointMesh.new()
	#quad_mesh.size.x = 4
	#quad_mesh.size.y = 4
	#quad_mesh.center_offset = Vector3(2, 2, 0)
	for _rating in range(HBJudge.JUDGE_RATINGS.size()):
		var mesh := MultiMesh.new()
		mesh.mesh = quad_mesh
		result_meshes.push_back(mesh)
	
	var judge := HBJudge.new()
	
	var position_buckets: Array[PackedVector2Array]
	position_buckets.resize(result_meshes.size())
	
	min_time = song.start_time
	max_time = float(end_time)
	for i in range(offset_map_times.size()):
		var judgement := judgement_map[i]
		if judgement != -1:
			var mesh := result_meshes[judgement]
			var time := offset_map_times[i]
			var x := remap(time, min_time, max_time, 0.0, 1.0)
			var pos := Vector2(x, 0.5 + (offset_map[i] / 128.0) * 0.5)
			position_buckets[judgement].push_back(pos)
	
	for i in range(position_buckets.size()):
		var mesh := result_meshes[i]
		mesh.instance_count = position_buckets[i].size()
		var trf := Transform2D()
		
		for j in range(position_buckets[i].size()):
			trf.origin = position_buckets[i][j]
			mesh.set_instance_transform_2d(j, trf)
	
	_on_multi_mesh_generated.call_deferred(result_meshes)

func _ready() -> void:
	for i in range(HBJudge.JUDGE_RATINGS.size()):
		var mi := MultiMeshInstance2D.new()
		add_child(mi)
		multi_meshes.push_back(mi)
	resized.connect(self._update_material)
	offset_point_material.shader = preload("res://rythm_game/results_screen/stats_offset_chart.gdshader")
	_update_material()
	
