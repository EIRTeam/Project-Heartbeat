extends ScrollContainer

class_name HBUniversalScrollList

signal out_from_bottom
signal out_from_top
signal selected_item_changed
signal scroll_changed

@export var container_path: NodePath
@export var horizontal_step: int = 1
@export var vertical_step: int = 1
@export var enable_fade: bool = false
@export var enable_wrap_around: bool = false
# When selecting an item, n HBHovereableItems before and after the selected one will
# receive a visibility report
@export var items_to_report_visibility_to: int = 6

enum SCROLL_MODE {
	PAGE,
	CENTER
}

@export var scroll_mode: SCROLL_MODE = SCROLL_MODE.PAGE

const FADE_SHADER = preload("res://menus/ScrollListShader.gdshader")
const INITIAL_DEBOUNCE_WAIT = 0.3
const DEBOUNCE_WAIT = 0.1


var debounce_step = 0
var target_scroll = 0.0
var current_selected_item = 0

@onready var tween = Threen.new()
@onready var initial_input_debounce_timer = Timer.new()
@onready var input_debounce_timer = Timer.new()

@onready var item_container: Container = get_node(container_path)

var container_order_dirty := 0

class DummyItem:
	extends Control
	signal sighted
	
	func _draw() -> void:
		pass
	func stop_hover():
		pass
	func hover():
		pass

func _draw() -> void:
	pass

func _ready():
	add_child(tween)
	add_child(initial_input_debounce_timer)
	add_child(input_debounce_timer)
	
	initial_input_debounce_timer.wait_time = INITIAL_DEBOUNCE_WAIT
	initial_input_debounce_timer.one_shot = true
	initial_input_debounce_timer.connect("timeout", Callable(self, "_on_initial_input_debounce_timeout"))
	input_debounce_timer.wait_time = DEBOUNCE_WAIT
	input_debounce_timer.connect("timeout", Callable(self, "_on_input_debounce_timeout"))
	
	connect("focus_exited", Callable(self, "_on_focus_lost"))
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	connect("resized", Callable(self, "_on_resized"))
	
	get_v_scroll_bar().connect("visibility_changed", Callable(self, "_on_vscrollbar_visibility_changed"))
	get_v_scroll_bar().connect("changed", Callable(self, "update_fade"))
	get_v_scroll_bar().connect("value_changed", Callable(self, "_on_scroll_changed"))
	clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	if enable_fade:
		var fade_mat = ShaderMaterial.new()
		fade_mat.shader = FADE_SHADER
		item_container.material = fade_mat
		RenderingServer.canvas_item_set_canvas_group_mode(item_container.get_canvas_item(), RenderingServer.CANVAS_GROUP_MODE_CLIP_ONLY, 5.0, true, 20.0)
	_on_resized()
	scroll_changed.connect(self._queue_clip_update)
	item_container.sort_children.connect(self._queue_clip_update)
	
func _on_scroll_changed(_new_scroll: float):
	if not tween.is_active():
		for i in range(item_container.get_child_count()):
			var child = item_container.get_child(i)
			var found_visible_item = false
			if child.position.y + child.size.y >= scroll_vertical:
				for ii in range(items_to_report_visibility_to*2):
					if child.get_index() + ii >= item_container.get_child_count():
						break
					var child2 = item_container.get_child(child.get_index() + ii) as HBUniversalListItem
				found_visible_item = true
			if found_visible_item:
				break
		target_scroll = scroll_vertical
		scroll_changed.emit()
		update_fade()
func _on_initial_input_debounce_timeout():
	_position_change_input(debounce_step)
	input_debounce_timer.start()
	
func _on_input_debounce_timeout():
	_position_change_input(debounce_step)
	
func _on_vscrollbar_visibility_changed():
	if enable_fade:
		var mat = item_container.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("enabled", get_v_scroll_bar().visible)
	
func _on_resized():
	if enable_fade:
		var mat = item_container.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("enabled", get_v_scroll_bar().visible)
			# HACK: Makes the fade work inside scaled controls!!
			mat.set_shader_parameter("size", get_global_transform().get_scale() * size)
			mat.set_shader_parameter("pos", get_global_transform().origin)
			
			mat.set_shader_parameter("fade_size", 100.0)
func get_selected_item():
	if item_container.get_child_count() > current_selected_item and current_selected_item > -1:
		var item = item_container.get_child(current_selected_item)
		if item and is_instance_valid(item):
			return item
	return null
	
var starting_animation_scroll = 0
	
func _scroll_animate_step(scroll_progress: float):
	var selected: Control = get_selected_item()
	if selected:
		target_scroll = calculate_target_scroll_to(selected)
		scroll_vertical = lerp(float(starting_animation_scroll), float(target_scroll), scroll_progress)
		update_fade()
func smooth_scroll_to(target: float):
	tween.remove_all()
	tween.interpolate_method(self, "_scroll_animate_step", 0.0, 1.0, 0.5, Threen.TRANS_CUBIC, Threen.EASE_OUT)
	starting_animation_scroll = scroll_vertical
	target_scroll = target
	scroll_changed.emit()
	tween.start()

var clip_update_queued := false

func _queue_clip_update():
	if not clip_update_queued:
		clip_update_queued = true
		await get_tree().process_frame
		_update_clipping()

func _update_clipping():
	clip_update_queued = false
	var children_sort := func children_sort(a: Control, b: Control):
		return a.position.y < b.position.y
	# hack...
	var clamped_target_scroll := clamp(target_scroll, 0, item_container.size.y - size.y)

	var children := item_container.get_children()
	if children.size() == 0:
		return
	var dummy_control := Control.new()
	dummy_control.position.y = clamped_target_scroll
	var child_start_i := children.bsearch_custom(dummy_control, children_sort)
	dummy_control.queue_free()
	child_start_i = min(children.size()-1, child_start_i)
	
	# Walk backwards to find the first item that shouldn't be visible:
	for i in range(child_start_i, -1, -1):
		if children[i].position.y + children[i].size.y < clamped_target_scroll:
			break
		child_start_i = i
	
	
	for i in range(child_start_i, children.size(), 1):
		var control := children[i] as Control
		if control:
			if control.position.y > clamped_target_scroll + size.y:
				break
		var dummy := children[i] as DummyItem
		if dummy and dummy.visible:
			dummy.sighted.emit()

func add_dummy() -> DummyItem:
	var dummy := DummyItem.new()
	item_container.add_child(dummy)
	container_order_dirty = true
	return dummy

func replace_dummy(dummy: DummyItem, replacement: Control):
	dummy.add_sibling(replacement)
	dummy.queue_free()
	item_container.remove_child(dummy)

func update_fade():
	# Hide top/bottom fade intelligently
	if enable_fade:
		var mat = item_container.material as ShaderMaterial
		if mat:
			var max_scroll = get_v_scroll_bar().max_value - size.y
			var selected_item = get_selected_item()
			if selected_item and selected_item.position.y <= target_scroll:
				# This ensures that if the target is at the top the fade is disabled so it's visible
				mat.set_shader_parameter("top_enabled", float(clamp(target_scroll, 0, max_scroll) > get_selected_item().position.y))
			else:
				mat.set_shader_parameter("top_enabled", float(target_scroll > 0))
				
			mat.set_shader_parameter("bottom_enabled", float(target_scroll < max_scroll))
	
func calculate_target_scroll_to(child: Control) -> float:
	var out := 0.0
	match scroll_mode:
		SCROLL_MODE.PAGE:
			if child.position.y + child.size.y > scroll_vertical + size.y or \
					child.position.y < scroll_vertical:
				out = float(child.position.y)
		SCROLL_MODE.CENTER:
			out = float(child.position.y + child.size.y / 2.0 - size.y / 2.0)
	return out
func select_item(item_i: int):
	if item_container.get_child_count() == 0:
		return
	
	var current_item = get_selected_item()
	
	var old_selected_item = current_selected_item
	
	if current_item:
		item_container.get_child(current_selected_item).stop_hover()

	var child = item_container.get_child(item_i)
	current_selected_item = item_i
	match scroll_mode:
		SCROLL_MODE.PAGE:
			if child.position.y + child.size.y > scroll_vertical + size.y or \
					child.position.y < scroll_vertical:
				smooth_scroll_to(float(child.position.y))
		SCROLL_MODE.CENTER:
			smooth_scroll_to(float(child.position.y + child.size.y / 2.0 - size.y / 2.0))
	if child.has_method("hover") and has_focus():
		child.hover()
	if old_selected_item != current_selected_item:
		emit_signal("selected_item_changed")
	if items_to_report_visibility_to > 0:
		var item_visiblity_report_min = current_selected_item - items_to_report_visibility_to
		item_visiblity_report_min = max(item_visiblity_report_min, 0)
		var item_visibility_report_max = current_selected_item + items_to_report_visibility_to + 1
		item_visibility_report_max = min(item_visibility_report_max, item_container.get_child_count())
		for i in range(item_visiblity_report_min, item_visibility_report_max):
			var visible_child = item_container.get_child(i)
	call_deferred("update_fade")
	
func force_scroll():
	if get_selected_item():
		select_item(current_selected_item)
	
func _input(event):
	# Stop debouncing when buttons are released
	var all_released = true
	for action in ["gui_up", "gui_down", "gui_left", "gui_right"]:
		if Input.is_action_pressed(action):
			all_released = false
	if all_released:
		initial_input_debounce_timer.stop()
		input_debounce_timer.stop()

# Receives position change input, select items as needed & plays back sounds
func _position_change_input(position_change: int):
	if position_change != 0:
		var new_pos = current_selected_item + position_change
		if enable_wrap_around:
			new_pos = wrapi(new_pos, 0, item_container.get_child_count())
		if new_pos > item_container.get_child_count() - 1:
			emit_signal("out_from_bottom")
		if new_pos < 0:
			emit_signal("out_from_top")
		else:
			new_pos = clamp(new_pos, 0, item_container.get_child_count() - 1)
			if new_pos != current_selected_item:
				select_item(new_pos)
				HBGame.fire_and_forget_sound(HBGame.menu_press_sfx, HBGame.sfx_group)

func _try_focus_neighbor(neighbor: NodePath) -> bool:
	if neighbor:
		var control := get_node(neighbor) as Control
		if not control:
			return false
		if control.focus_mode != Control.FOCUS_ALL:
			return false
		control.grab_focus()
		return true
	return false
func _gui_input(event):
	var position_change = 0
	if event.is_action_pressed("gui_down"):
		if vertical_step != 0:
			position_change += vertical_step
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("gui_up"):
		if vertical_step != 0:
			position_change -= vertical_step
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("gui_right"):
		if horizontal_step != 0:
			position_change += horizontal_step
			get_viewport().set_input_as_handled()
		else:
			if _try_focus_neighbor(focus_neighbor_right):
				return
	if event.is_action_pressed("gui_left"):
		if horizontal_step != 0:
			position_change -= horizontal_step
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("gui_accept"):
		var selected_child = get_selected_item()
		if selected_child and selected_child.has_signal("pressed"):
			get_viewport().set_input_as_handled()
			var sfx_type = HBGame.menu_forward_sfx
			if selected_child.has_meta("sfx"):
				sfx_type = selected_child.get_meta("sfx")
			if sfx_type:
				HBGame.fire_and_forget_sound(sfx_type, HBGame.sfx_group)
			selected_child.emit_signal("pressed")
	_position_change_input(position_change)
	if position_change != 0:
		debounce_step = position_change
		initial_input_debounce_timer.stop()
		input_debounce_timer.stop()
		initial_input_debounce_timer.start()

func _on_focus_lost():
	var current_item = get_selected_item()
	if not current_item:
		return
	if current_item.has_method(&"notify_parent_list_lost_focus"):
		current_item.notify_parent_list_lost_focus()
	else:
		current_item.stop_hover()
	initial_input_debounce_timer.stop()
	input_debounce_timer.stop()

func _on_focus_entered():
	var current_item = get_selected_item()
	if current_item:
		current_item.hover()
