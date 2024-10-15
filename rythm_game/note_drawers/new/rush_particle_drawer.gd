extends Node2D

class_name RushParticleDrawer

var free_instances: Array[int]
var in_use_instances: Array[int]
var sprites: Array[Sprite2D]

var rush_particle_progress := PackedFloat32Array()
var rush_particle_start_positions := PackedVector2Array()

const RUSH_PARTICLE_MAX = 32
const RUSH_PARTICLE_RADIUS := 256
const RUSH_PARTICLE_DURATION := 0.25

var nanform := Transform2D()
var texture: Texture2D

func set_note_data(note_data: HBRushNote):
	texture = HBRushNote.get_note_graphic(note_data.note_type, "rush_note")

func _ready() -> void:
	free_instances.resize(RUSH_PARTICLE_MAX)
	rush_particle_progress.resize(RUSH_PARTICLE_MAX)
	rush_particle_start_positions.resize(RUSH_PARTICLE_MAX)
	for i in range(RUSH_PARTICLE_MAX):
		sprites.push_back(Sprite2D.new())
		sprites[-1].hide()
		add_child(sprites[-1])
		free_instances[i] = i

func emit():
	if free_instances.size() > 0:
		var free_instance_idx: int = free_instances.pop_back()
		in_use_instances.push_back(free_instance_idx)
		rush_particle_progress[free_instance_idx] = 0.0
		rush_particle_start_positions[free_instance_idx] = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * RUSH_PARTICLE_RADIUS
		sprites[free_instance_idx].texture = texture
		sprites[free_instance_idx].show()
func _process(delta: float) -> void:
	for i in range(in_use_instances.size()-1, -1, -1):
		var instance_idx := in_use_instances[i]
		rush_particle_progress[instance_idx] = move_toward(rush_particle_progress[instance_idx], RUSH_PARTICLE_DURATION, delta)
		
		
		var normalized_progress := rush_particle_progress[instance_idx] / RUSH_PARTICLE_DURATION
		var graphic_position := rush_particle_start_positions[instance_idx].lerp(Vector2.ZERO, normalized_progress)
		var graphic_alpha := 1.0 - normalized_progress
		graphic_alpha *= 0.25
		
		var trf := Transform2D()
		trf = trf.scaled(Vector2.ONE * 0.75)
		trf.origin = graphic_position
		var sprite := sprites[instance_idx]
		sprite.transform = trf
		sprite.modulate.a = graphic_alpha
		
		if rush_particle_progress[instance_idx] >= RUSH_PARTICLE_DURATION:
			in_use_instances.remove_at(i)
			free_instances.push_back(instance_idx)
			sprite.hide()
