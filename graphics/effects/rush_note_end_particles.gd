extends Node2D

class_name HBRushNoteEndParticles

func _on_animation_finished():
	queue_free()

func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(self._on_animation_finished)
	$Whirl.texture = ResourcePackLoader.get_graphic("rush_note_twirl.png")
	$Spark.texture = ResourcePackLoader.get_graphic("rush_note_spark.png")

func play():
	$AnimationPlayer.play("new_animation")
