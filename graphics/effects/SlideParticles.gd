extends Particles2D

var d = 0

func _ready():
	emitting = true
	yield(get_tree().create_timer(lifetime), "timeout")
	queue_free()
