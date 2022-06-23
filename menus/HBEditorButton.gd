tool
extends Container

class_name HBEditorButton

var button: Button
var label: Label

export var text: String = "" setget set_text
export var tooltip: String = ""
export var texture: StreamTexture setget set_texture

func _init():
	button = Button.new()
	button.icon = texture
	button.hint_tooltip = tooltip
	button.expand_icon = true
	
	label = Label.new()
	label.text = text
	rect_min_size.x = label.rect_min_size.x
	rect_min_size.y = label.rect_min_size.x + label.rect_min_size.y
	
	add_child(button)
	add_child(label)
	
	queue_sort()

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		# Must re-sort the children
		var max_width = rect_size.x
		fit_child_in_rect(button, Rect2(Vector2(), Vector2(max_width, max_width)))
		fit_child_in_rect(label, Rect2(Vector2(max_width / 2.0 - label.rect_size.x / 2.0, button.rect_size.x), label.rect_size))
		rect_min_size = Vector2(label.rect_size.x, rect_size.x + label.rect_size.y)

func get_button():
	return button

func set_text(new_text):
	text = new_text
	label.text = new_text
	
	rect_min_size.x = label.rect_min_size.x
	rect_min_size.y = label.rect_min_size.x + label.rect_min_size.y
	
	queue_sort()

func set_texture(new_texture):
	texture = new_texture
	button.icon = new_texture
