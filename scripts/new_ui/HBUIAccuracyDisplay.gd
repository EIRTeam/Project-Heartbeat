extends HBUIComponent

class_name HBUIAccuracyDisplay

var max_latency = 128
const JUDGEMENTS_TO_COUNT = 40
var last_judgements = []

var gradient_color_cool := Color.deepskyblue setget set_gradient_color_cool
var gradient_color_fine := Color.green setget set_gradient_color_fine
var gradient_color_safe := Color.orange setget set_gradient_color_safe
var gradient_color_sad := Color.gold setget set_gradient_color_sad
var gradient_line_height := 12 setget set_gradient_line_height
var rating_line_width := 3 setget set_rating_line_width

var line_grad_colors := []

var line_grad_img: Image
var line_grad_tex: ImageTexture

static func get_component_id() -> String:
	return "accuracy_display"
	
static func get_component_name() -> String:
	return "Accuracy Display"

func get_hb_inspector_whitelist() -> Array:
	var whitelist := .get_hb_inspector_whitelist()
	whitelist.append_array([
		"rating_line_width", "gradient_color_cool", "gradient_color_fine",
		"gradient_color_safe", "gradient_color_sad", "gradient_line_height"
	])
	return whitelist
	
func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := ._to_dict(resource_storage)
	
	out_dict["rating_line_width"] = rating_line_width
	out_dict["gradient_line_height"] = gradient_line_height
	out_dict["gradient_color_cool"] = gradient_color_cool.to_html()
	out_dict["gradient_color_fine"] = gradient_color_fine.to_html()
	out_dict["gradient_color_safe"] = gradient_color_safe.to_html()
	out_dict["gradient_color_sad"] = gradient_color_sad.to_html()
	return out_dict

func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	._from_dict(dict, cache)
	
	rating_line_width = dict.get("rating_line_width", 3)
	gradient_line_height = dict.get("gradient_line_height", 12)
	gradient_color_cool = get_color_from_dict(dict, "gradient_color_cool", Color.deepskyblue)
	gradient_color_fine = get_color_from_dict(dict, "gradient_color_fine", Color.green)
	gradient_color_safe = get_color_from_dict(dict, "gradient_color_safe", Color.orange)
	gradient_color_sad = get_color_from_dict(dict, "gradient_color_sad", Color.gold)
	gradient_line_height = dict.get("gradient_line_height", 12)

func update_line_grad_colors():
	line_grad_colors = [gradient_color_sad, gradient_color_safe, gradient_color_fine, gradient_color_cool,
						gradient_color_cool, gradient_color_fine, gradient_color_safe, gradient_color_sad]
	if not line_grad_img:
		line_grad_img = Image.new()
		line_grad_img.create(line_grad_colors.size(), 1, false, Image.FORMAT_RGB8)
	line_grad_img.lock()
	for i in range(line_grad_colors.size()):
		line_grad_img.set_pixel(i, 0, line_grad_colors[i])
	line_grad_img.unlock()
	if not line_grad_tex:
		line_grad_tex = ImageTexture.new()
		line_grad_tex.create_from_image(line_grad_img, 0)
	else:
		line_grad_tex.set_data(line_grad_img)
	update()

func set_rating_line_width(val):
	rating_line_width = val
	update()

func set_gradient_color_cool(val):
	gradient_color_cool = val
	update_line_grad_colors()
	
func set_gradient_color_fine(val):
	gradient_color_fine = val
	update_line_grad_colors()
	
func set_gradient_color_safe(val):
	gradient_color_safe = val
	update_line_grad_colors()
	
func set_gradient_color_sad(val):
	gradient_color_sad = val
	update_line_grad_colors()
	
func set_gradient_line_height(val):
	gradient_line_height = val
	update()

func _ready():
	set_rating_line_width(rating_line_width)
	set_gradient_color_cool(gradient_color_cool)
	set_gradient_color_fine(gradient_color_fine)
	set_gradient_color_safe(gradient_color_safe)
	set_gradient_color_sad(gradient_color_sad)
	set_gradient_line_height(gradient_line_height)

func _draw():
	# draw the background
	var background_color = Color.black
	background_color.a = 0.5
	draw_rect(Rect2(Vector2.ZERO, rect_size), background_color)
	if not line_grad_tex:
		return
	# draw the gradient line
	var gradient_line_rect = Rect2(Vector2(0, (rect_size.y / 2.0) - (gradient_line_height / 2.0)), Vector2(rect_size.x, gradient_line_height))
	draw_texture_rect(line_grad_tex, gradient_line_rect, false)
	
	# draw the rating lines
	var starting_pos = Vector2.ZERO
	var ending_pos = Vector2.ZERO
	ending_pos.y = rect_size.y
	var average_sum := 0.0
	var average_count := 0.0
	for i in range(last_judgements.size()):
		var judgement = last_judgements[i]
		starting_pos.x = judgement * rect_size.x
		ending_pos.x = starting_pos.x
		var color_i = clamp(judgement * line_grad_colors.size(), 0, line_grad_colors.size()-1)
		var color = line_grad_colors[int(color_i)]
		color.a -= 0.95 * (i / float(JUDGEMENTS_TO_COUNT-1))
		draw_line(starting_pos, ending_pos, color, rating_line_width)
		average_count += 1
		average_sum += judgement
	# draw the center line
	draw_line(Vector2(rect_size.x * 0.5, 0.0), Vector2(rect_size.x * 0.5, rect_size.y), Color.white, rating_line_width)

	# draw the average arrow

	var average = 0.5

	if last_judgements.size() > 0: 
		average = average_sum / average_count
	var triangle_height = gradient_line_rect.position.y
	var point1 = Vector2(average * rect_size.x, 0.0) + Vector2(0, triangle_height)
	var point2 = Vector2(average * rect_size.x, 0.0) + Vector2(triangle_height, 0)
	var point3 = Vector2(average * rect_size.x, 0.0) + Vector2(-triangle_height, 0)
	
	draw_colored_polygon(PoolVector2Array([point1, point2, point3]), Color.white, PoolVector2Array(), null, null, true)

func set_judge(judge: HBJudge):
	max_latency = judge.get_target_window_msec()

func reset():
	last_judgements = []
	update()

func _on_note_judged(judgement_info):
	if UserSettings.user_settings.show_latency:
		if judgement_info.wrong or judgement_info.judgement < HBJudge.JUDGE_RATINGS.SAD:
			return
		var latency_diff = judgement_info.time-judgement_info.target_time
		latency_diff = range_lerp(latency_diff, -max_latency, max_latency, 0.0, 1.0)
		if latency_diff > 1.0:
			return
		if last_judgements.size() >= JUDGEMENTS_TO_COUNT:
			last_judgements.pop_back()
		last_judgements.push_front(latency_diff)
		update()
