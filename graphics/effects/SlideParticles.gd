extends Particles2D

var d = 0

func _ready():
	emitting = true
	
func _process(delta):
	d += delta
	if d >= lifetime:
		queue_free()
