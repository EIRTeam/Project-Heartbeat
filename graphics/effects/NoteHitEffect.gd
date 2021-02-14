extends Node2D

onready var note_icon = get_node("NoteIcon")
onready var note_loop = get_node("Loop")
onready var note_flare = get_node("Flare")

onready var tween = Tween.new()

func _ready():
	tween.connect("tween_all_completed", self, "queue_free")
	add_child(tween)
	play_effect()
	
func play_effect():
	note_icon.scale = Vector2.ZERO
	note_icon.modulate.a = 0.0
	note_loop.scale = Vector2.ZERO
	note_loop.modulate.a = 0.0
	note_flare.scale = Vector2.ZERO
	note_flare.modulate.a = 0.0
	tween.playback_speed = 1.5
	tween.stop_all()
	var note_icon_t = Color.white
	note_icon_t.a = 0.75
	
	var transparent_trans = Tween.TRANS_QUINT
	var transparent_ease = Tween.EASE_IN
	
	tween.interpolate_property(note_icon, "scale", Vector2(0.15, 0.15), Vector2(0.25, 0.25), 0.20, Tween.TRANS_BACK, Tween.EASE_IN)
	tween.interpolate_property(note_icon, "scale", Vector2(0.25, 0.25), Vector2(0.65, 0.65), 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.20)
	tween.interpolate_property(note_icon, "modulate:a", 0.6, 0.0, 0.7, transparent_trans, transparent_ease)
	
	tween.interpolate_property(note_loop, "scale", Vector2(0.15, 0.15), Vector2(0.75, 0.75), 0.15, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	tween.interpolate_property(note_loop, "scale", Vector2(0.75, 0.75), Vector2(2.0, 2.0), 0.60, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.15)
	tween.interpolate_property(note_loop, "modulate:a", 0.6, 0.0, 0.7, transparent_trans, transparent_ease)
	
	tween.interpolate_property(note_flare, "scale", Vector2(0.15, 0.15), Vector2(0.75, 0.75), 0.15, Tween.TRANS_BOUNCE, Tween.EASE_IN)
	tween.interpolate_property(note_flare, "scale", Vector2(0.75, 0.75), Vector2(1.0, 1.0), 0.25, Tween.TRANS_QUAD, Tween.EASE_OUT, 0.15)
	tween.interpolate_property(note_flare, "modulate:a", 0.4, 0.0, 0.4, transparent_trans, transparent_ease)
	
	tween.start()
#	$AnimationPlayer.play("COOL")

func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		queue_free()
