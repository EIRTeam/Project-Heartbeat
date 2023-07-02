extends Button

class_name HBHovereableOptionButton

@export var normal_style: StyleBox
@export var hover_style: StyleBox

var buttons = []

@onready var vbox_container: HBSimpleMenu = get_node("PanelContainer/MarginContainer/VBoxContainer")
@onready var items_panel_container: PanelContainer = get_node("PanelContainer")

var selected_item: int = 0: set = set_selected_item

signal back

func set_selected_item(item: int):
	selected_item = item
	text = buttons[item].text

signal selected(id)

func add_item(button_text: String, id):
	var butt := HBHovereableButton.new()
	butt.text = button_text
	butt.set_meta("id", id)
	buttons.append(butt)
	vbox_container.add_child(butt)
	butt.connect("pressed", Callable(self, "_on_button_pressed").bind(butt, id))

func _on_button_pressed(button, id):
	items_panel_container.hide()
	selected_item = button.get_index()
	text = button.text
	emit_signal("selected", id)
	emit_signal("back")

func clear():
	for button in buttons:
		button.queue_free()
		vbox_container.remove_child(button)
	buttons.clear()

func hover():
	vbox_container.select_button(selected_item, false)
	set_process_input(true)
	add_theme_stylebox_override("normal", hover_style)
	
func stop_hover():
	add_theme_stylebox_override("normal", normal_style)

	
func get_item_count() -> int:
	return vbox_container.get_child_count()
	
func _on_pressed():
	if not items_panel_container.visible:
		items_panel_container.show()
		items_panel_container.global_position = global_position + Vector2(size.x - items_panel_container.size.x, size.y)
		
		if (get_viewport_rect().position.y + get_viewport_rect().end.y) < items_panel_container.global_position.y + items_panel_container.size.y:
			items_panel_container.global_position.y = (get_viewport_rect().position.y + get_viewport_rect().end.y) - items_panel_container.size.y
		if (get_viewport_rect().position.x + get_viewport_rect().end.x) < items_panel_container.global_position.x + items_panel_container.size.x:
			items_panel_container.global_position.x = (get_viewport_rect().position.x + get_viewport_rect().end.x) - items_panel_container.size.x
		vbox_container.grab_focus()
		vbox_container.select_button(selected_item)
	else:
		items_panel_container.hide()
		emit_signal("back")
		
	
func _input(event):
	if event.is_action_pressed("gui_cancel"):
		if items_panel_container.is_visible_in_tree():
			items_panel_container.hide()
			get_viewport().set_input_as_handled()
			emit_signal("back")
			
func _on_visibility_changed():
	set_process_input(is_visible_in_tree())
	
func _ready():
	items_panel_container.hide()
	items_panel_container.set_as_top_level(true)
	connect("pressed", Callable(self, "_on_pressed"))
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	set_process_input(false)
	RenderingServer.canvas_item_set_z_index(items_panel_container.get_canvas_item(), 100)

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE:
			if get_parent() is HBSimpleMenu:
				connect("back", Callable(get_parent(), "grab_focus"))
		NOTIFICATION_EXIT_TREE:
			if get_parent() is HBSimpleMenu:
				disconnect("back", Callable(get_parent(), "grab_focus"))
