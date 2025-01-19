extends PanelContainer

class_name HBCommandLineEditPopupLine

signal hovered
signal pressed
signal move_up_pressed
signal move_down_pressed
signal edit_pressed
signal remove_pressed

@onready var button_container: HBSimpleMenu = get_node("%ButtonContainer")
@onready var up_button: Button = get_node("%UpButton")
@onready var down_button: Button = get_node("%DownButton")
@onready var remove_button: Button = get_node("%RemoveButton")
@onready var edit_button: Button = get_node("%EditButton")

var line: String:
	set(val):
		line = val
		%LineLabel.text = line

func _gui_input(event: InputEvent) -> void:
	button_container._gui_input(event)

func hover():
	emit_signal("hovered")
	# HACK-y
	button_container._on_focus_entered()

func stop_hover():
	button_container._on_focus_exited()

func _ready() -> void:
	edit_button.pressed.connect(edit_pressed.emit)
	up_button.pressed.connect(move_up_pressed.emit)
	down_button.pressed.connect(move_down_pressed.emit)
	remove_button.pressed.connect(remove_pressed.emit)
	
func _update_buttons_visibility():
	if not is_inside_tree():
		return
	var pos_in_parent := get_index()
	up_button.show()
	down_button.show()
	if pos_in_parent == 0:
		up_button.hide()
	if pos_in_parent == get_parent().get_child_count()-1:
		down_button.hide()
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if not is_node_ready():
				await ready
			get_parent().child_order_changed.connect(_update_buttons_visibility)
			get_parent().child_entered_tree.connect(func(_a): _update_buttons_visibility())
			get_parent().child_exiting_tree.connect(func(_a): _update_buttons_visibility())
			_update_buttons_visibility()
