extends Control

class_name HBMenu

var target_scale := Vector2(1.0, 1.0)
var target_opacity := 1.0
var previous_menu

func _ready():
	focus_mode = Control.FOCUS_ALL

func _process(delta):

	if not is_equal_approx(modulate.a, target_opacity):
		modulate.a = lerp(modulate.a, target_opacity, 15.0 * delta)
		
	if rect_scale != target_scale:
		rect_scale = lerp(rect_scale, target_scale, 15.0 * delta)
		
func back():
	navigate_to_menu(previous_menu, true)
		
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if previous_menu:
			get_tree().set_input_as_handled()
			back()
		
func navigate_to_menu(next_menu, back=false):
	if back:
		next_menu.rect_scale = Vector2(0.75, 0.75)
		target_scale = Vector2(1.25, 1.25)
	else:
		next_menu.rect_scale = Vector2(1.25, 1.25)
		target_scale = Vector2(0.75, 0.75)
		
	next_menu.modulate.a = 0.0
	next_menu.target_scale = Vector2(1.0, 1.0)
	next_menu.target_opacity = 1.0
	target_opacity = 0.0
	
	focus_mode = FOCUS_NONE
	
	next_menu.focus_mode = FOCUS_ALL
	next_menu.grab_focus()
	next_menu.show()
	get_parent().move_child(next_menu, get_parent().get_child_count()-1)
	if not back:
		next_menu.previous_menu = self
		print(next_menu.previous_menu.name)
