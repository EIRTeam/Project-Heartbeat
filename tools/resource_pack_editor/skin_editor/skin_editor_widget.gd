extends PanelContainer

class_name HBSkinEditorWidget

@onready var tween := Threen.new()

@onready var inside_control: Control = get_node("Outline/Inside")
@onready var outline_control: Control = get_node("Outline")

@onready var component_name_label: Label = get_node("Outline/Label")

const CORNER_TOP_LEFT = 0
const CORNER_TOP_RIGHT = 1
const CORNER_BOTTOM_RIGHT = 2
const CORNER_BOTTOM_LEFT = 3
const CORNER_TOP = 4
const CORNER_LEFT = 5
const CORNER_DOWN = 6
const CORNER_RIGHT = 7

var _lmb_pressed := false
var _dragging := false
# if set to -1 we are dragging from the center
var _dragging_button := 0
var _dragging_start_pos := Vector2.ZERO
var _dragging_margin_horizontal := "offset_left"
var _dragging_margin_vertical := "offset_top"
var _dragging_edit_value_start := Vector2.ZERO
var _ignore_resize_flag := false

const CORNER = preload("res://tools/resource_pack_editor/skin_editor/skin_editor_corner.tscn")

var component_name: String: set = set_component_name

@export var target_node_path: NodePath
@onready var target_node: Control: set = set_target_node
@onready var contextual_menu: PopupMenu = get_node("Control/PopupMenu")
@onready var contextual_menu_anchor_preset := PopupMenu.new()
@onready var contextual_menu_anchor_margin_preset := PopupMenu.new()

enum WIDGET_MODE {
	MARGIN,
	ANCHOR
}

@export var mode: WIDGET_MODE: set = set_mode

const CONTEXTUAL_ANCHOR_MENU = 0
const CONTEXTUAL_ANCHOR_MARGIN_MENU = 1
const CONTEXTUAL_FIT_MARGIN_TO_ANCHOR = 2

signal changed

@export var popupmenu_font: FontFile

func fill_contextual_menu():
	contextual_menu.clear()
	contextual_menu.add_submenu_item("Anchor preset", "ContextualMenuAnchor", CONTEXTUAL_ANCHOR_MENU)
	contextual_menu.add_submenu_item("Anchor & margin preset", "ContextualMenuAnchorMargin", CONTEXTUAL_ANCHOR_MARGIN_MENU)
	contextual_menu.add_item("Fit margin to anchor", CONTEXTUAL_FIT_MARGIN_TO_ANCHOR)

func _on_contextual_menu_item_pressed(id: int):
	match id:
		CONTEXTUAL_FIT_MARGIN_TO_ANCHOR:
			if target_node:
				target_node.offset_bottom = 0
				target_node.offset_top = 0
				target_node.offset_left = 0
				target_node.offset_right = 0
				_on_target_node_resized()
				emit_signal("changed")
				
func _copy_anchor_from_target_node():
	var par = get_parent_control()
	if par:
		if target_node:
			position = Vector2(target_node.anchor_left * par.size.x, target_node.anchor_top * par.size.y)
			size = Vector2(target_node.anchor_right * par.size.x, target_node.anchor_bottom * par.size.y) - position
				
func _copy_margin_from_target_node():
	if target_node:
		size = target_node.size
		global_position = target_node.global_position
		
func _on_target_node_resized():
	if mode == WIDGET_MODE.MARGIN:
		if not _ignore_resize_flag:
			_copy_margin_from_target_node()
	elif mode == WIDGET_MODE.ANCHOR:
		_copy_anchor_from_target_node()
func set_target_node(val):
	if target_node:
		target_node.disconnect("resized", Callable(self, "_on_target_node_resized"))
	target_node = val
	set_block_signals(true)
	_on_target_node_resized()
	set_block_signals(false)
	if target_node:
		target_node.connect("resized", Callable(self, "_on_target_node_resized"))

func set_component_name(val):
	component_name = val
	if is_inside_tree():
		component_name_label.text = val

@onready var corners = [
	CORNER.instantiate(),
	CORNER.instantiate(),
	CORNER.instantiate(),
	CORNER.instantiate(),
	CORNER.instantiate(),
	CORNER.instantiate(),
	CORNER.instantiate(),
	CORNER.instantiate()
]

func set_mode(val):
	mode = val
	if is_inside_tree():
		set_block_signals(true)
		_on_target_node_resized()
		set_block_signals(false)
		for corner in corners:
			corner.show()
			corner.anchor_graphic_visible = false
		inside_control.modulate.a = 0.0
		outline_control.self_modulate = Color("ff6500")
		outline_control.self_modulate.a = 1.0
		if mode == WIDGET_MODE.ANCHOR:
			corners[CORNER_RIGHT].hide()
			corners[CORNER_LEFT].hide()
			corners[CORNER_TOP].hide()
			corners[CORNER_DOWN].hide()
			
			corners[CORNER_BOTTOM_LEFT].anchor_graphic_visible = true
			corners[CORNER_BOTTOM_RIGHT].anchor_graphic_visible = true
			corners[CORNER_TOP_LEFT].anchor_graphic_visible = true
			corners[CORNER_TOP_RIGHT].anchor_graphic_visible = true
			inside_control.modulate.a = 1.0
			outline_control.self_modulate = Color.GREEN
			
func _get_preset_name(preset: int) -> String:
	var preset_name := ""
	match preset:
		PRESET_TOP_LEFT:
			preset_name = "Top Left"
		PRESET_TOP_RIGHT:
			preset_name = "Top Right"
		PRESET_BOTTOM_RIGHT:
			preset_name = "Bottom Right"
		PRESET_BOTTOM_LEFT:
			preset_name = "Bottom Left"
		PRESET_CENTER_LEFT:
			preset_name = "Center Left"
		PRESET_CENTER_TOP:
			preset_name = "Center Top"
		PRESET_CENTER_RIGHT:
			preset_name = "Center Right"
		PRESET_CENTER_BOTTOM:
			preset_name = "Center Bottom"
		PRESET_CENTER:
			preset_name = "Center"
		PRESET_LEFT_WIDE:
			preset_name = "Left Wide"
		PRESET_TOP_WIDE:
			preset_name = "Top Wide"
		PRESET_RIGHT_WIDE:
			preset_name = "Right Wide"
		PRESET_BOTTOM_WIDE:
			preset_name = "Bottom Wide"
		PRESET_VCENTER_WIDE:
			preset_name = "Vertical Center Wide"
		PRESET_HCENTER_WIDE:
			preset_name = "Horizontal Center Wide"
		PRESET_FULL_RECT:
			preset_name = "Wide"
	return preset_name
			
func fill_preset_menu(menu: PopupMenu):
	for i in range(PRESET_FULL_RECT+1):
		menu.add_item(_get_preset_name(i), i)
		if i in [PRESET_BOTTOM_RIGHT, PRESET_CENTER, PRESET_HCENTER_WIDE]:
			menu.add_separator()
			
func _apply_anchor_preset(preset: int):
	if target_node:
		target_node.set_anchors_preset(preset)
		_on_target_node_resized()
		emit_signal("changed")
		

func _apply_anchor_and_margin_preset(preset: int):
	if target_node:
		var resize_mode := Control.PRESET_MODE_MINSIZE
		
		match preset:
			Control.PRESET_TOP_LEFT, \
			Control.PRESET_TOP_RIGHT, \
			Control.PRESET_BOTTOM_LEFT, \
			Control.PRESET_BOTTOM_RIGHT, \
			Control.PRESET_CENTER_LEFT, \
			Control.PRESET_CENTER_TOP, \
			Control.PRESET_CENTER_RIGHT, \
			Control.PRESET_CENTER_BOTTOM, \
			Control.PRESET_CENTER:
				resize_mode = Control.PRESET_MODE_KEEP_SIZE
		target_node.set_anchors_and_offsets_preset(preset, resize_mode)
		_on_target_node_resized()
		emit_signal("changed")

		
# Called when the node enters the scene tree for the first time.
func _ready():
	contextual_menu_anchor_preset.add_theme_font_override("font", popupmenu_font)
	contextual_menu_anchor_margin_preset.add_theme_font_override("font", popupmenu_font)
	contextual_menu_anchor_preset.name = "ContextualMenuAnchor"
	contextual_menu_anchor_margin_preset.name = "ContextualMenuAnchorMargin"
	
	fill_preset_menu(contextual_menu_anchor_preset)
	fill_preset_menu(contextual_menu_anchor_margin_preset)
	
	contextual_menu.add_child(contextual_menu_anchor_preset)
	contextual_menu.add_child(contextual_menu_anchor_margin_preset)
	
	fill_contextual_menu()
	
	contextual_menu_anchor_preset.connect("id_pressed", Callable(self, "_apply_anchor_preset"))
	contextual_menu_anchor_margin_preset.connect("id_pressed", Callable(self, "_apply_anchor_and_margin_preset"))
	contextual_menu.connect("id_pressed", Callable(self, "_on_contextual_menu_item_pressed"))
	
	component_name_label.text = component_name
	
	if target_node_path:
		var node := get_node(target_node_path) as Control
		if node:
			set_target_node(node)
	
	queue_redraw()
	set_process(false)
	add_child(tween)
	
	set_mode(mode)
	
	for i in range(corners.size()):
		var corner := corners[i] as HBSkinEditorCorner

		match i:
			CORNER_TOP_LEFT:
				corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
				corner.anchor_graphic_rotation = -180
			CORNER_TOP_RIGHT:
				corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
				corner.anchor_graphic_rotation = -90
			CORNER_BOTTOM_LEFT:
				corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
				corner.anchor_graphic_rotation = 90
			CORNER_BOTTOM_RIGHT:
				corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			CORNER_TOP:
				corner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			CORNER_LEFT:
				corner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
			CORNER_RIGHT:
				corner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
			CORNER_DOWN:
				corner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		corner.offset_left = -8
		corner.offset_top = -8
		corner.offset_right = 8
		corner.offset_bottom = 8
		
		match i:
			CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_TOP:
				corner.offset_bottom += 2
				corner.offset_top += 2
			CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT, CORNER_DOWN:
				corner.offset_top -= 2
				corner.offset_bottom -= 2
		match i:
			CORNER_RIGHT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT:
				corner.offset_left -= 2
				corner.offset_right -= 2
			CORNER_LEFT, CORNER_TOP_LEFT, CORNER_BOTTOM_LEFT:
				corner.offset_left += 2
				corner.offset_right += 2
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inside_control.add_child(corner)
	
func _process(delta):
	queue_redraw()
	var mouse_pos := get_global_mouse_position()
	var par := get_parent_control()
	if mode == WIDGET_MODE.MARGIN:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			contextual_menu.popup()
			var popup_offset = mouse_pos + Vector2(contextual_menu.size) - get_viewport_rect().size
			popup_offset.x = max(popup_offset.x, 0)
			popup_offset.y = max(popup_offset.y, 0)
			contextual_menu.global_canvas_transform.origin = (mouse_pos - popup_offset)
	if not _dragging:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		for i in range(corners.size()):
			var corner := corners[i] as Control
			if not corner.visible:
				continue
			var is_hovered := corner.get_global_rect().has_point(mouse_pos)
			if mode == WIDGET_MODE.ANCHOR:
				is_hovered = corner.get_anchor_graphic_global_rect().has_point(mouse_pos)
			if is_hovered:
				if i > CORNER_BOTTOM_LEFT:
					if i % 2 == 0:
						mouse_default_cursor_shape = Control.CURSOR_VSIZE
					else:
						mouse_default_cursor_shape = Control.CURSOR_HSIZE
						
				elif i % 2 == 0:
					mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
				else:
					mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
				if _lmb_pressed:
					_dragging = true
					
					_dragging_button = i
					_dragging_start_pos = mouse_pos
					_dragging_margin_vertical = ""
					_dragging_margin_horizontal = ""
					match i:
						CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_TOP:
							_dragging_margin_vertical = "offset_top"
						CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT, CORNER_DOWN:
							_dragging_margin_vertical = "offset_bottom"
					match i:
						CORNER_RIGHT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT:
							_dragging_margin_horizontal = "offset_right"
						CORNER_LEFT, CORNER_TOP_LEFT, CORNER_BOTTOM_LEFT:
							_dragging_margin_horizontal = "offset_left"
					_dragging_edit_value_start = Vector2.ZERO
					if _dragging_margin_horizontal:
						_dragging_edit_value_start.x = get(_dragging_margin_horizontal)
					if _dragging_margin_vertical:
						_dragging_edit_value_start.y = get(_dragging_margin_vertical) 
				break
		
		if not _dragging:
			if _lmb_pressed and get_global_rect().has_point(mouse_pos):
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				_dragging_edit_value_start = position
				_dragging = true
				_dragging_button = -1
				_dragging_start_pos = mouse_pos
	if _dragging:
		if _dragging_button != -1:
			var current_margin = _dragging_edit_value_start - (_dragging_start_pos - mouse_pos)
			current_margin.x = clamp(current_margin.x, 0, get_parent().size.x)
			current_margin.y = clamp(current_margin.y, 0, get_parent().size.y)
			if _dragging_margin_horizontal:
				set(_dragging_margin_horizontal, current_margin.x)
			if _dragging_margin_vertical:
				set(_dragging_margin_vertical, current_margin.y)
			queue_redraw()

		else:
			var current_pos = _dragging_edit_value_start - (_dragging_start_pos - mouse_pos)
			position = current_pos
			queue_redraw()
			
		if not _lmb_pressed:
			_dragging = false
			# this forces margins to update
			size = size
			if _dragging_button == -1:
				mouse_default_cursor_shape = Control.CURSOR_ARROW
		position.x = max(position.x, 0)
		position.y = max(position.y, 0)

		if par:
			size.x = min(par.size.x, size.x)
			size.y = min(par.size.y, size.y)
		if par:
			position.x = min(position.x, par.size.x - size.x)
			position.y = min(position.y, par.size.y - size.y)
		if target_node:
			if mode == WIDGET_MODE.MARGIN:
				set_block_signals(true)
				_ignore_resize_flag = true
				target_node.position = position
				target_node.size = size
				_ignore_resize_flag = false
				set_block_signals(false)
				if target_node.custom_minimum_size.x > 0:
					size.x = max(size.x, target_node.custom_minimum_size.x)
				if target_node.custom_minimum_size.y > 0:
					size.y = max(size.y, target_node.custom_minimum_size.y)
				emit_signal("changed")

			elif mode == WIDGET_MODE.ANCHOR:
				if par:
					set_block_signals(true)
					target_node.set_anchor(SIDE_LEFT, position.x / par.size.x, false, false)
					target_node.set_anchor(SIDE_TOP, position.y / par.size.y, false, false)
					target_node.set_anchor(SIDE_BOTTOM, (position.y + size.y) / par.size.y, false, false)
					target_node.set_anchor(SIDE_RIGHT, (position.x + size.x) / par.size.x, false, false)
					set_block_signals(false)
					emit_signal("changed")
					queue_redraw()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_lmb_pressed = event.pressed
func _on_SkinEditorWidget_mouse_entered():
	set_process(true)
	match mode:
		WIDGET_MODE.ANCHOR:
			tween.reset_all()
			tween.interpolate_property(inside_control, "self_modulate:a", inside_control.self_modulate.a, 1.0, 0.2)
			tween.start()
		WIDGET_MODE.MARGIN:
			tween.reset_all()
			tween.interpolate_property(inside_control, "modulate:a", inside_control.modulate.a, 1.0, 0.2)
			tween.start()

func clear_current():
	hide()
	target_node = null

# Bounding box extension on the sides
func has_point(point):
	var rect := Rect2(Vector2.ZERO, size)
	rect.position += Vector2(-16, -16)
	rect.size += Vector2(32, 32)
	if mode == WIDGET_MODE.ANCHOR:
		for corner in corners:
			if corner.anchor_graphic_visible:
				var corner_rect := get_global_transform().affine_inverse() * (corner.get_anchor_graphic_global_rect()) as Rect2
				if corner_rect.has_point(point):
					return true
	return rect.has_point(point)

func _draw():
	if size.x < 4 or size.y < 4:
		draw_set_transform_matrix(get_transform().inverse())
		draw_rect(get_rect(), Color("a300ff"), false, 4.0)# true) TODOGODOT4 Antialiasing argument is missing
#	for corner_i in [CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT, CORNER_TOP_LEFT, CORNER_TOP_RIGHT]:
#		draw_set_transform_matrix(get_global_transform().affine_inverse())
#		var corner := corners[corner_i] as HBSkinEditorCorner
#		var rect := corner.get_anchor_graphic_global_rect() as Rect2
#		draw_rect(rect, Color.blue)
#		draw_line(Vector2.ZERO, rect_position, Color.blue, 3.0, true)
#		draw_line(rect_position + Vector2(rect_size.x, 0), Vector2(par.rect_size.x * anchor_right, 0), Color.blue, 3.0, true)
#		draw_line(rect_position + rect_size, Vector2(par.rect_size.x * anchor_right, par.rect_size.y * anchor_bottom), Color.blue, 3.0, true)
#		draw_line(rect_position + Vector2(0, rect_size.y), Vector2(0, par.rect_size.y * anchor_bottom), Color.blue, 3.0, true)

func _on_SkinEditorWidget_mouse_exited():
	if not _dragging:
		set_process(false)
		match mode:
			WIDGET_MODE.ANCHOR:
				tween.reset_all()
				tween.interpolate_property(inside_control, "self_modulate:a", inside_control.self_modulate.a, 0.0, 0.2)
				tween.start()
			WIDGET_MODE.MARGIN:
				tween.reset_all()
				tween.interpolate_property(inside_control, "modulate:a", inside_control.modulate.a, 0.0, 0.2)
				tween.start()
		mouse_default_cursor_shape = Control.CURSOR_ARROW

