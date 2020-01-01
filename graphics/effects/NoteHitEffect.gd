extends Node2D

onready var animation_player = get_node("AnimationPlayer")

func _ready():
	play_effect()
	animation_player.connect("animation_finished", self, "_on_animation_finished")
	
func play_effect():
	$AnimationPlayer.play("COOL")
	
func _on_animation_finished(anim_name: String):
	queue_free()
