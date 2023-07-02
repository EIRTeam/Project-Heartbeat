extends Control

class_name HBTabbedContainer

@onready var button_container = get_node("VBoxContainer/HBoxContainer2/HBoxContainer")
@onready var tab_container = get_node("VBoxContainer/TabContainer")
var tabs = {}
var tab_buttons = {}
var current_tab
func add_tab(tab_name: String, tab_display_name: String, tab: Control):
	var button = HBHovereableButton.new()
	button.text = tab_display_name
	button_container.add_child(button)
	button.set_meta("tab_name", tab_name)
	tabs[tab_name] = tab
	tab_buttons[tab_name] = button
	if tabs.size() == 1:
		button_container.select_button(0)
func _ready():
#	add_tab("test", Control.new())
#	add_tab("test2", Control.new())
	button_container.grab_focus()
	button_container.stop_hover_on_focus_exit = false
	button_container.ignore_down = true
	button_container.connect("hovered", Callable(self, "_on_button_container_hover"))
	button_container.prev_action = "gui_tab_left"
	button_container.next_action = "gui_tab_right"

func _on_button_container_hover(button):
	show_tab(button.get_meta("tab_name"))

func show_tab(tab_name: String):
	if current_tab:
		tab_container.remove_child(current_tab)
	current_tab = tabs[tab_name]
	tab_container.add_child(current_tab)
	
	button_container.select_button(tab_buttons[tab_name].get_index(), false)
	if current_tab is TabbedContainerTab:
		current_tab._enter_tab()

func _unhandled_input(event):
	if event.is_action("gui_tab_left") or event.is_action("gui_tab_right"):
		button_container._gui_input(event)
