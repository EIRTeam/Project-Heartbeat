extends Control

class_name TutorialUIChapterTitle

var starting_title_global_rect: Rect2

@onready var title_label: Label = %Title
@onready var title_container: Container = %TitleContainer

var update_title_rect_queued = false
var tween: Tween

func _ready() -> void:
	hide()
	starting_title_global_rect = title_container.get_global_rect()
	set_notify_local_transform(true)

func _update_title_animation(progress: float):
	var container_pos := title_container.global_position
	var container_size := title_container.size.x
	title_label.global_position = (container_pos + Vector2(title_container.size.x * 0.5, 0.0)).lerp(container_pos, progress)

func _update_container_animation(progress: float):
	modulate.a = progress
	scale.y = lerp(0.1, 1.0, progress)

func play_show_animation():
	show()
	modulate.a = 1.0
	if tween:
		tween.kill()
		tween = null
	tween = create_tween()
	# Panel Container scale
	tween.tween_method(_update_container_animation, 0.0, 1.0, 0.25) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	# Panel Container fade in
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.25) \
		.from(0.0)
	const LABEL_FADE_IN_DURATION := 0.5
	const LABEL_ANIMATION_MID_POINT = 0.8
	const LABEL_ANIMATION_END_SLOW_DURATION := 3.0
	# Label fade in
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, LABEL_FADE_IN_DURATION) \
		.from(0.0)
	# Label animation first part
	tween.parallel().tween_method(_update_title_animation, 0.0, LABEL_ANIMATION_MID_POINT, LABEL_FADE_IN_DURATION) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	# End slower part
	tween.tween_method(_update_title_animation, LABEL_ANIMATION_MID_POINT, 1.0, LABEL_ANIMATION_END_SLOW_DURATION)
	
	const FADEOUT_DURATION := 0.25
	# Fade out scale
	tween.parallel().tween_method(_update_container_animation, 1.0, 0.0, FADEOUT_DURATION) \
		.set_delay(LABEL_ANIMATION_END_SLOW_DURATION-FADEOUT_DURATION) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	# fade out alpha
	tween.parallel().tween_property(self, "modulate:a", 0.0, FADEOUT_DURATION) \
		.set_delay(LABEL_ANIMATION_END_SLOW_DURATION-FADEOUT_DURATION) \
		.from(1.0)
	tween.tween_callback(hide)
func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		pivot_offset = size * Vector2(0.0, 0.5)
