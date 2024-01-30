@uid("uid://ep2vlj4qg55x") # Generated automatically, do not modify.
@tool
extends CPUParticles2D

class_name SliderPieceParticle

func do_emit():
	restart()
	#for i in [1, -1]:
		#var particle_pjos := Vector2.RIGHT.rotated(deg_to_rad(25.0) * i)
		#particle_pos *= 75.0
		#var particle_trf := Transform2D(deg_to_rad(45.0), Vector2(0.25, 0.25), 0, particle_pos)
		#emit_particle(particle_trf, Vector2(1250.0, -i * 100.0), Color.WHITE, Color.WHITE, EMIT_FLAG_POSITION | EMIT_FLAG_ROTATION_SCALE | EMIT_FLAG_VELOCITY)
	emitting = true
	$GPUParticles2D.emitting = true
func _ready():
	if Engine.is_editor_hint():
		set_process(true)
		finished.connect(do_emit)
		do_emit()
	else:
		set_process(false)
