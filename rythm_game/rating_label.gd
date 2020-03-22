extends Label

const DISAPPEAR_TIMEOUT = 1.0
const DISAPPEAR_TIME = 0.1
var disappear_timeout_t = 0.0
var disappear_time_t = 0.0
func show_rating():
	disappear_timeout_t = 0.0
	disappear_time_t = 0.0
	
func _process(delta):
	modulate.a = 1.0
	disappear_timeout_t += delta
	if disappear_timeout_t > DISAPPEAR_TIMEOUT:
		disappear_time_t += delta
		modulate.a = 1.0 - (disappear_time_t/DISAPPEAR_TIME)
		
