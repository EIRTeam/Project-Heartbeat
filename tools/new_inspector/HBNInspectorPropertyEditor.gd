extends PanelContainer

class_name HBInspectorPropertyEditor

@onready var hbox_container := HBoxContainer.new()
@onready var outer_vbox_container := VBoxContainer.new()
@onready var vbox_container := VBoxContainer.new()

const DOWN_GRAHIC = preload("res://tools/icons/icon_GUI_tree_arrow_down.svg")
const RIGHT_GRAPHIC = preload("res://tools/icons/icon_GUI_tree_arrow_right.svg")


signal value_changed(value)

var value

@onready var text_label := Label.new()

func can_collapse() -> bool:
	return false

func set_value(val):
	value = val

func _ready():
	_init_inspector()
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

func set_property_data(data: Dictionary):
	text_label.text = data.name.capitalize()

func _init_inspector():
	var base_panel := PanelContainer.new()
	base_panel.add_theme_stylebox_override("panel", preload("res://tools/new_inspector/property_editor_stylebox.tres"))
	
	add_child(base_panel)
	base_panel.add_child(outer_vbox_container)
	if can_collapse():
		var hb := HBoxContainer.new()
		var button_right := Button.new()
		var button_down := Button.new()
		button_down.connect("pressed", Callable(button_down, "hide"))
		button_down.connect("pressed", Callable(button_right, "show"))
		button_down.connect("pressed", Callable(hbox_container, "hide"))
		
		button_right.connect("pressed", Callable(button_right, "hide"))
		button_right.connect("pressed", Callable(button_down, "show"))
		button_right.connect("pressed", Callable(hbox_container, "show"))
		
		button_down.icon = DOWN_GRAHIC
		button_right.icon = RIGHT_GRAPHIC
		
		hb.add_child(button_down)
		hb.add_child(button_right)
		
		hb.add_child(text_label)
		
		button_down.hide()
		hbox_container.hide()
		
		outer_vbox_container.add_child(hb)
	else:
		hbox_container.add_child(text_label)
	outer_vbox_container.add_child(hbox_container)
	hbox_container.add_child(vbox_container)
	vbox_container.size_flags_horizontal = SIZE_EXPAND_FILL
	text_label.size_flags_horizontal = SIZE_EXPAND_FILL
	text_label.size_flags_vertical = SIZE_EXPAND_FILL
	
