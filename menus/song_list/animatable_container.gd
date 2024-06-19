extends Container

class_name HBAnimatableContainer

var tween: Tween

var calculated_min_size: Vector2

enum Direction {
	HORIZONTAL,
	VERTICAL
}

const SEPARATION := 10.0

@export var direction: Direction = Direction.VERTICAL
var deployed := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sort_children.connect(_on_sort_children)

func get_animatable_children_controls() -> Array[Control]:
	var out: Array[Control]
	for child in get_children():
		if child is Control and child.has_meta(&"animated_deployed_visibility"):
			out.push_back(child)
	return out

func _get_minimum_size() -> Vector2:
	var calculated := Vector2()
	var children := get_children()
	for i in range(children.size()):
		var first := i == 0
		var child := children[i]
		if child is Control:
			if not child.visible:
				continue
			var animated_scale := child.get_meta("animated_scale", child.scale) as Vector2
			if direction == Direction.VERTICAL:
				if not first:
					calculated.y += SEPARATION * animated_scale.y
				calculated.y += child.get_combined_minimum_size().y * animated_scale.y
				calculated.x = max(child.get_combined_minimum_size().x * animated_scale.x, calculated.x)
			else:
				if not first:
					calculated.x += SEPARATION * animated_scale.x
				calculated.x += child.get_combined_minimum_size().x * animated_scale.x
				calculated.y = max(child.get_combined_minimum_size().y * animated_scale.y, calculated.y)
			calculated.ceil()
	return calculated

func _draw() -> void:
	return
	for child in get_children():
		draw_rect(Rect2(child.position, child.size), Color.RED, false)
#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_accept"):
		#animate(!deployed)

func _animate_step(_p: float):
	for child in get_animatable_children_controls():
		child.pivot_offset.y = 0.0
	queue_sort()
	
func animate_child_scale(a_scale: float, child: Control):
	child.set("scale", a_scale * Vector2.ONE)
	child.modulate.a = a_scale
	child.set_meta("animated_scale", a_scale * Vector2.ONE)
	
func animate(deploy: bool):
	if deploy == deployed:
		return
	deployed = deploy
	const ANIMATION_DURATION := 0.3
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	
	tween.parallel().tween_method(_animate_step, 0.0, 1.0, ANIMATION_DURATION)
	var visibility_callables: Array[Callable]
	for child in get_animatable_children_controls(): 
		var should_be_visible := deployed and child.get_meta(&"animated_deployed_visibility") as bool
		var starting_scale := 0.0 if should_be_visible else 1.0
		var final_scale := 1.0 if should_be_visible else 0.0
		animate_child_scale(starting_scale, child)
		tween.parallel().tween_method(animate_child_scale.bind(child), starting_scale, final_scale, ANIMATION_DURATION)
		child.visible = true
		if should_be_visible:
			if child.scale == Vector2.ONE:
				child.scale = Vector2.ONE
		else:
			visibility_callables.push_back(child.set.bind("visible", !child.visible))
			
	for callable in visibility_callables:
		tween.tween_callback(callable)
#func animate():
	#return
	#var final_scale := Vector2.ZERO if $Panel2.visible else Vector2.ONE
	#const ANIMATION_DURATION := 0.5
	#if tween:
		#tween.kill()
	#tween = create_tween()
	#tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	#
	#tween.parallel().tween_method(_animate_step, 0.0, 1.0, ANIMATION_DURATION)
	#var visibility_callables: Array[Callable]
	#for child in get_animatable_children_controls(): 
		#tween.parallel().tween_property(child, "scale", final_scale, ANIMATION_DURATION)
		#if !child.visible:
			#child.visible = true
			#if child.scale == Vector2.ONE:
				#child.scale = Vector2.ZERO
		#else:
			#visibility_callables.push_back(child.set.bind("visible", !child.visible))
			#
	#for callable in visibility_callables:
		#tween.tween_callback(callable)

func _on_sort_children():
	var minimum_size := Vector2()
	calculated_min_size = Vector2.ZERO
	var rect_start := Vector2()
	var children := get_children()
	for i in range(children.size()):
		var child := children[i] as Control
		if not child.visible:
			continue
		var first := i == 0
		var child_scale := child.scale as Vector2
		if not first:
			if direction == Direction.VERTICAL:
				rect_start.y += SEPARATION * child_scale.y
			else:
				rect_start.x += SEPARATION * child_scale.x
		fit_child_in_rect(child, Rect2(rect_start, Vector2(size.x, 0.0)))
		#child.scale = child_scale
		child.set_deferred("scale", child_scale)
		match direction:
			Direction.VERTICAL:
				rect_start += Vector2(0.0, child.size.y * child_scale.y)
				update_minimum_size()
			Direction.HORIZONTAL:
				calculated_min_size.x += child.get_combined_minimum_size().x * child_scale.x
				calculated_min_size.y = max(calculated_min_size.y, child.get_combined_minimum_size().y * child_scale.y)
				if i < children.size()-1:
					calculated_min_size.x += SEPARATION * children[i+1].scale.x
				rect_start = Vector2(calculated_min_size.x, 0.0)
				update_minimum_size()
