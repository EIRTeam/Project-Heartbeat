extends Node2D

var d = 0

func _ready():
	self.emitting = true
	$Node2D2.emitting = true
	
func _process(delta):
	d += delta
	if d >= self.lifetime:
		queue_free()
