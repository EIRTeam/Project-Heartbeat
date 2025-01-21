extends PanelContainer

class_name HBCommandLineEditPopup

signal lines_updated(lines: Array[String])
signal lines_entered(lines: Array[String])
signal canceled

@onready var add_button: Button = get_node("%AddButton")
@onready var apply_button: Button = get_node("%ApplyButton")
@onready var line_container: HBSimpleMenu = get_node("%LineContainer")
@onready var add_button_container: HBSimpleMenu = get_node("%AddButtonContainer")
@onready var edit_line_popup: HBTextInput = get_node("%EditLinePopup")
@onready var create_line_popup: HBTextInput = get_node("%CreateLinePopup")

const LineScene := preload("res://menus/options_menu/CommandLineEditPopupLine.tscn")

var line_nodes: Array[HBCommandLineEditPopupLine]
var current_editing_line: HBCommandLineEditPopupLine

var lines: Array[String]:
	set(val):
		lines = val
		_update_lines()

func _on_line_pressed(line_idx: int):
	pass

func _on_line_edit_popup_entered(text: String):
	current_editing_line.line = text
	line_container.grab_focus()
	notify_lines_updated()

func _on_line_create_popup_entered(text: String):
	if not text.is_empty():
		add_line(text)
		line_container.select_button(line_container.get_child_count()-1)
		line_container.grab_focus()
		notify_lines_updated()
	else:
		add_button_container.grab_focus()

func _input(event):
	if line_container.has_focus() or add_button_container.has_focus():
		# I feel fairly dirty about this HACK
		if line_container.has_focus() and (event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right") or event.is_action_pressed("gui_accept")):
			var selected = line_container.selected_button
			if selected:
				if selected.has_method("_gui_input"):
					get_viewport().set_input_as_handled()
					selected._gui_input(event)
		if event.is_action_pressed("gui_cancel"):
			get_viewport().set_input_as_handled()
			canceled.emit()
			hide()
func _ready() -> void:
	add_button.pressed.connect(func():
		create_line_popup.text_input = ""
		create_line_popup.popup_centered()
	)
	create_line_popup.entered.connect(_on_line_create_popup_entered)
	create_line_popup.cancel.connect(add_button_container.grab_focus)
	edit_line_popup.entered.connect(_on_line_edit_popup_entered)
	edit_line_popup.cancel.connect(line_container.grab_focus)
	add_button_container.grab_focus()
	apply_button.pressed.connect(notify_lines_entered)
	apply_button.pressed.connect(hide)

func _on_line_move_up_pressed(line: HBCommandLineEditPopupLine):
	line_container.move_child(line, line.get_index()-1)
	line_container.grab_focus()
	line_container.select_button(line.get_index())

func _on_line_move_down_pressed(line: HBCommandLineEditPopupLine):
	line_container.move_child(line, line.get_index()+1)
	line_container.grab_focus()
	line_container.select_button(line.get_index())

func _on_line_remove_pressed(line: HBCommandLineEditPopupLine):
	var old_line_idx := line.get_index()
	
	line_container.remove_child(line)
	line_nodes.erase(line)
	line.queue_free()
	if line_container.get_child_count() == 0:
		add_button_container.grab_focus()
	else:
		line_container.grab_focus()
		line_container.select_button(min(line_container.get_child_count()-1, old_line_idx))
	notify_lines_updated()

func _on_line_edit_pressed(line: HBCommandLineEditPopupLine):
	current_editing_line = line
	edit_line_popup.text_input = line.line
	edit_line_popup.popup_centered()

func add_line(text: String):
	var line_node: HBCommandLineEditPopupLine = LineScene.instantiate()
	line_node.move_up_pressed.connect(_on_line_move_up_pressed.bind(line_node))
	line_node.move_down_pressed.connect(_on_line_move_down_pressed.bind(line_node))
	line_node.edit_pressed.connect(_on_line_edit_pressed.bind(line_node))
	line_node.remove_pressed.connect(_on_line_remove_pressed.bind(line_node))
	line_container.add_child(line_node)
	line_node.line = text
	line_nodes.push_back(line_node)
	add_button.move_to_front()

func _update_lines():
	for line in line_container.get_children():
		if line == add_button:
			continue
		line_container.remove_child(line)
		line.queue_free()
	line_nodes.clear()
	for line in lines:
		add_line(line)

func notify_lines_entered():
	lines_entered.emit(lines)

func notify_lines_updated():
	lines.clear()
	line_nodes.sort_custom(func(a: HBCommandLineEditPopupLine, b: HBCommandLineEditPopupLine):
		a.get_index() < b.get_index()
	)
	for line in line_nodes:
		lines.push_back(line.line)
	
	lines_updated.emit(lines)

func popup():
	show()
	add_button_container.grab_focus()
