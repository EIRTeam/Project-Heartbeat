extends Control

var scroll_pos = 0.0
var scroll_dir = 1.0
const SCROLL_SPEED = 50.0
var diff = 0
var text_height = 0
export (Font) var font = preload("res://fonts/Rating_Font.tres")
export(String) var text setget set_text

func set_text(te):
	text = te
	_on_resized()
	update()

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
	rect_clip_content = true
func _on_resized():
	var size = font.get_string_size(text)
	var width = size.x
	text_height = size.y
	if rect_size.x < width:
		diff = width - rect_size.x
		set_process(true)
		scroll_pos = 0.0
		scroll_dir = -1.0
	else:
		set_process(false)
		scroll_pos = 0.0
		update()
func _draw():
	draw_string(font, Vector2(scroll_pos, text_height/2 + rect_size.y/2), text, Color.white)
func _process(delta):
	scroll_pos += delta * scroll_dir * SCROLL_SPEED
	if scroll_pos < -diff and scroll_dir == -1.0:
		scroll_dir = 1.0
		scroll_pos = -diff
	elif scroll_pos >= 0:
		scroll_pos = 0
		scroll_dir = -1
	update()
