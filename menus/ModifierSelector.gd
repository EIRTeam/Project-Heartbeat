extends Control

signal back
signal modifier_selected(modifier_id)

@onready var description_label = get_node("VBoxContainer/Panel2/MarginContainer/HBoxContainer/DescriptionLabel")
@onready var button_container = get_node("VBoxContainer/Panel/MarginContainer/VBoxContainer")

func _ready():
	hide()

func popup():
	show()
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()
	for modifier_id in ModifierLoader.modifiers:
		var modifier_class = ModifierLoader.get_modifier_by_id(modifier_id)
		var button = HBHovereableButton.new()
		button.text = modifier_class.get_modifier_name()
		button.connect("hovered", Callable(self, "show_description").bind(modifier_class.get_modifier_description()))
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(modifier_id))
		button_container.add_child(button)
		button_container.select_button(0)
	button_container.grab_focus()

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed("gui_cancel"):
			get_viewport().set_input_as_handled()
			_on_back()
func _on_back():
	hide()
	emit_signal("back")

func _on_button_pressed(modifier_id: String):
	emit_signal("modifier_selected", modifier_id)
	hide()

func show_description(description: String):
	description_label.text = description
