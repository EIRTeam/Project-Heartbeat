extends Label

var last_latency_diff = 0
var max_latency
const LATENCY_RECT_HEIGHT = 3
func _on_note_judged(judgement_info):
	if UserSettings.user_settings.show_latency:
		show()
		var message = "Perfect! %+d ms"
		if judgement_info.target_time < judgement_info.time:
			message = "Late! %+d ms"
		elif judgement_info.target_time > judgement_info.time:
			message = "Early! %+d ms"
		message = message % [judgement_info.time-judgement_info.target_time]
		text = message
		last_latency_diff = judgement_info.time-judgement_info.target_time

func _ready():
	hide()
	max_latency = HBUtils.find_key(HBJudge.RATING_WINDOWS, HBJudge.JUDGE_RATINGS.SAD)
	
func _draw():
	var val = float(last_latency_diff) / float(max_latency)
	var color = Color.white
	if val > 0:
		color = Color.red
	else:
		color = Color.green
	var origin = Vector2(rect_size.x/2.0, rect_size.y - LATENCY_RECT_HEIGHT)
	var size =  Vector2((val/2.0)*rect_size.x, LATENCY_RECT_HEIGHT)
	var rect = Rect2(origin, size)
	draw_rect(rect, color)
