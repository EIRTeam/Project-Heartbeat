extends Control

var max_latency = 128
const JUDGEMENTS_TO_COUNT = 40
var last_judgements = []

const RATING_LINE_WIDTH = 3

const GRADIENT_COLOR_COOL = Color.DEEP_SKY_BLUE
const GRADIENT_COLOR_FINE = Color.GREEN
const GRADIENT_COLOR_SAFE = Color.ORANGE
const GRADIENT_COLOR_SAD = Color.GOLD
const LINE_GRAD_COLORS = [GRADIENT_COLOR_SAD, GRADIENT_COLOR_SAFE, GRADIENT_COLOR_FINE, GRADIENT_COLOR_COOL,
						GRADIENT_COLOR_COOL, GRADIENT_COLOR_FINE, GRADIENT_COLOR_SAFE, GRADIENT_COLOR_SAD]
var gradient_texture: Texture2D

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
		latency_diff = remap(latency_diff, -max_latency, max_latency, 0.0, 1.0)
		if latency_diff > 1.0:
			return
		if last_judgements.size() >= JUDGEMENTS_TO_COUNT:
			last_judgements.pop_back()
		last_judgements.push_front(latency_diff)
		queue_redraw()
func _ready():
	var img = Image.create(LINE_GRAD_COLORS.size(), 1, false, Image.FORMAT_RGB8)
	false # img.lock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	for i in range(LINE_GRAD_COLORS.size()):
		img.set_pixel(i, 0, LINE_GRAD_COLORS[i])
	false # img.unlock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var texture = ImageTexture.create_from_image(img) #,0
	gradient_texture = texture
func _draw():
	# draw the background
	var background_color = Color.BLACK
	background_color.a = 0.5
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	
	# draw the gradient line
	var gradient_line_rect = Rect2(Vector2(0, (size.y / 2.0) - (GRADIENT_LINE_HEIGHT / 2.0)), Vector2(size.x, GRADIENT_LINE_HEIGHT))
	draw_texture_rect(gradient_texture, gradient_line_rect, false)
	
	# draw the rating lines
	var starting_pos = Vector2.ZERO
	var ending_pos = Vector2.ZERO
	ending_pos.y = size.y
	var average_sum := 0.0
	var average_count := 0.0
	for i in range(last_judgements.size()):
		var judgement = last_judgements[i]
		starting_pos.x = judgement * size.x
		ending_pos.x = starting_pos.x
		var color_i = clamp(judgement * LINE_GRAD_COLORS.size(), 0, LINE_GRAD_COLORS.size()-1)
		var color = LINE_GRAD_COLORS[int(color_i)]
		color.a -= 0.95 * (i / float(JUDGEMENTS_TO_COUNT-1))
		draw_line(starting_pos, ending_pos, color, RATING_LINE_WIDTH)
		average_count += 1
		average_sum += judgement
	# draw the center line
	draw_line(Vector2(size.x * 0.5, 0.0), Vector2(size.x * 0.5, size.y), Color.WHITE, RATING_LINE_WIDTH)

	# draw the average arrow

	var average = 0.5

	if last_judgements.size() > 0: 
		average = average_sum / average_count
	var triangle_height = gradient_line_rect.position.y
	var point1 = Vector2(average * size.x, 0.0) + Vector2(0, triangle_height)
	var point2 = Vector2(average * size.x, 0.0) + Vector2(triangle_height, 0)
	var point3 = Vector2(average * size.x, 0.0) + Vector2(-triangle_height, 0)
	
	draw_colored_polygon(PackedVector2Array([point1, point2, point3]), Color.WHITE)
