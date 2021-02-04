extends Control

var max_latency = 128
const JUDGEMENTS_TO_COUNT = 40
var last_judgements = []

const RATING_LINE_WIDTH = 3

const GRADIENT_COLOR_COOL = Color.deepskyblue
const GRADIENT_COLOR_FINE = Color.green
const GRADIENT_COLOR_SAFE = Color.orange
const GRADIENT_COLOR_SAD = Color.gold
const LINE_GRAD_COLORS = [GRADIENT_COLOR_SAD, GRADIENT_COLOR_SAFE, GRADIENT_COLOR_FINE, GRADIENT_COLOR_COOL,
						GRADIENT_COLOR_COOL, GRADIENT_COLOR_FINE, GRADIENT_COLOR_SAFE, GRADIENT_COLOR_SAD]
var gradient_texture: Texture

const GRADIENT_LINE_HEIGHT = 12

func set_judge(judge: HBJudge):
	max_latency = judge.get_target_window_msec()

func reset():
	last_judgements = []

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
func _ready():
	var img = Image.new()
	img.create(LINE_GRAD_COLORS.size(), 1, false, Image.FORMAT_RGB8)
	img.lock()
	for i in range(LINE_GRAD_COLORS.size()):
		img.set_pixel(i, 0, LINE_GRAD_COLORS[i])
	img.unlock()
	var texture = ImageTexture.new()
	texture.create_from_image(img, 0)
	gradient_texture = texture
func _draw():
	# draw the background
	var background_color = Color.black
	background_color.a = 0.5
	draw_rect(Rect2(Vector2.ZERO, rect_size), background_color)
	
	# draw the gradient line
	var gradient_line_rect = Rect2(Vector2(0, (rect_size.y / 2.0) - (GRADIENT_LINE_HEIGHT / 2.0)), Vector2(rect_size.x, GRADIENT_LINE_HEIGHT))
	draw_texture_rect(gradient_texture, gradient_line_rect, false)
	
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
		var color_i = clamp(judgement * LINE_GRAD_COLORS.size(), 0, LINE_GRAD_COLORS.size()-1)
		var color = LINE_GRAD_COLORS[int(color_i)]
		color.a -= 0.95 * (i / float(JUDGEMENTS_TO_COUNT-1))
		draw_line(starting_pos, ending_pos, color, RATING_LINE_WIDTH)
		average_count += 1
		average_sum += judgement
	# draw the center line
	draw_line(Vector2(rect_size.x * 0.5, 0.0), Vector2(rect_size.x * 0.5, rect_size.y), Color.white, RATING_LINE_WIDTH)

	# draw the average arrow

	var average = 0.5

	if last_judgements.size() > 0: 
		average = average_sum / average_count
	var triangle_height = gradient_line_rect.position.y
	var point1 = Vector2(average * rect_size.x, 0.0) + Vector2(0, triangle_height)
	var point2 = Vector2(average * rect_size.x, 0.0) + Vector2(triangle_height, 0)
	var point3 = Vector2(average * rect_size.x, 0.0) + Vector2(-triangle_height, 0)
	
	draw_colored_polygon(PoolVector2Array([point1, point2, point3]), Color.white, PoolVector2Array(), null, null, true)
