extends Control

class_name HBResultsScreenHoverRect

var hover_text := ""

var has_mouse := false
var mouse_pos: Vector2

func _ready() -> void:
	mouse_exited.connect(self.set.bind("has_mouse", false))
	mouse_exited.connect(self.queue_redraw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		has_mouse = true
		mouse_pos = event.position
		queue_redraw()

func _draw() -> void:
	if has_mouse:
		const FONT_SIZE := 30
		draw_string_outline(get_theme_font("default_font"), mouse_pos, hover_text,HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 15, Color.BLACK)
		draw_string(get_theme_font("default_font"), mouse_pos, hover_text,HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
