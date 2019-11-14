extends "res://tools/editor/widgets/EditorWidget.gd"

signal start_moved(new_position)
signal end_moved(new_position)
	
func _ready():
	$StartWidget.editor = editor
	$EndWidget.editor = editor

func _on_StartWidget_note_moved(new_pos):
	emit_signal("start_moved", new_pos + $StartWidget.rect_size / 2)


func _on_EndWidget_note_moved(new_pos):
	emit_signal("end_moved", new_pos + $StartWidget.rect_size / 2)
	
func set_start_position(screen_pos):
	$StartWidget.rect_position = screen_pos - $StartWidget.rect_size / 2
	
func set_end_position(screen_pos):
	$EndWidget.rect_position = screen_pos - $EndWidget.rect_size / 2
