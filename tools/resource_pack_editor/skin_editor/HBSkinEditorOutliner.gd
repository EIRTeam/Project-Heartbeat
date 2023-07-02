extends VBoxContainer

class_name HBSkinEditorOutliner

signal item_removed(component)

class OutlinerItem:
	extends PanelContainer
	
	signal item_selected
	signal remove_pressed
	signal contextual_menu_pressed
	
	@onready var container := HBoxContainer.new()
	@onready var item_name_label := Label.new()
	@onready var line_edit := LineEdit.new()
	@onready var remove_button := Button.new()
	var node: HBUIComponent
	var layer: String
	
	var selected := false
	
	func _init(_node: HBUIComponent):
		node = _node
	
	func _ready():
		set_process_input(false)
		add_child(container)
		container.add_child(item_name_label)
		container.add_child(line_edit)
		item_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_node(node)
		line_edit.hide()
		item_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.connect("focus_exited", Callable(self, "_on_abort_line_edit"))
		line_edit.connect("text_submitted", Callable(self, "_on_text_entered"))
		line_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		remove_button.icon = preload("res://tools/icons/icon_remove.svg")
		remove_button.flat = true
		
		container.add_child(remove_button)
		
		remove_button.connect("pressed", Callable(self, "emit_signal").bind("remove_pressed"))
	func set_node(new_node: HBUIComponent):
		node = new_node
		item_name_label.text = node.name

	func select():
		if not selected:
			selected = true
			emit_signal("item_selected")
			add_theme_stylebox_override("panel", get_theme_stylebox("focus", "Button"))
	func deselect():
		selected = false
		remove_theme_stylebox_override("panel")

	func _on_abort_line_edit():
		line_edit.hide()
		item_name_label.show()
		set_process_input(false)

	func _on_text_entered(new_text: String):
		node.name = new_text
		item_name_label.text = node.name
		line_edit.hide()
		item_name_label.show()
		set_process_input(false)

	func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				emit_signal("item_selected")
				if event.double_click:
					item_name_label.hide()
					line_edit.show()
					line_edit.text = node.name
					line_edit.grab_focus()
					line_edit.caret_column = line_edit.text.length()
					set_process_input(true)
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				emit_signal("item_selected")
				emit_signal("contextual_menu_pressed")
				
	func _input(event):
		# We monitor the input while the node is being edited to check if the user clicks outside
		if event is InputEventMouseButton:
			if event.pressed:
				if not line_edit.get_global_rect().has_point(get_global_mouse_position()):
					_on_abort_line_edit()
					get_viewport().set_input_as_handled()
class OutlinerLayer:
	extends VBoxContainer
	
	signal layer_selected
	signal item_removed(component)
	signal contextual_menu_open_request(item)
	
	@onready var panel_container := PanelContainer.new()
	@onready var name_label := Label.new()
	@onready var children_outer_container := PanelContainer.new()
	@onready var children_container := VBoxContainer.new()
	
	var layer_name: String
	
	var selected := false
	var selected_item: OutlinerItem
	
	func set_layer_name(new_layer_name: String):
		if is_inside_tree():
			name_label.text = layer_name
		layer_name = new_layer_name
	func _ready():
		panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel_container)
		panel_container.add_child(name_label)
		add_child(HSeparator.new())
		add_child(children_outer_container)
		children_outer_container.add_child(children_container)
		set_layer_name(layer_name)
		children_outer_container.add_theme_stylebox_override("panel", get_theme_stylebox("panel", "Panel"))
	
	func move_item_to(item: OutlinerItem, position: int):
		children_container.move_child(item, position)
	
	func deselect(layer_only := false):
		if not layer_only:
			for item in children_container.get_children():
				item.deselect()
		selected = false
		panel_container.remove_theme_stylebox_override("panel")
		selected_item = null
		
	func select():
		if not selected:
			selected = true
			emit_signal("layer_selected")
			panel_container.add_theme_stylebox_override("panel", panel_container.get_theme_stylebox("focus", "TextEdit"))
	
	func _gui_input(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				select()
	func add_item(item: OutlinerItem):
		item.layer = name_label.text
		item.connect("item_selected", Callable(self, "_on_item_selected").bind(item))
		item.connect("remove_pressed", Callable(self, "_on_item_removed_pressed").bind(item))
		item.connect("contextual_menu_pressed", Callable(self, "emit_signal").bind("contextual_menu_open_request", item))
		children_container.add_child(item)
		
	func remove_item_from_list(item: OutlinerItem):
		children_container.remove_child(item)
		
	func _on_item_removed_pressed(item: OutlinerItem):
		remove_item_from_list(item)
		emit_signal("item_removed", item.node)
		if item == selected_item:
			selected_item = null
		item.queue_free()
			
	func _on_item_selected(item: OutlinerItem):
		if item == selected_item:
			return
		if selected_item:
			selected_item.deselect()
		selected_item = item
		emit_signal("layer_selected")
		item.select()
		
	

var component_items = []

var layers := {}

signal component_selected(component)
signal moved_component_to_layer(old_layer, new_layer, component)

var selected_layer := ""

@onready var popup_menu := PopupMenu.new()

var currently_selected_item: OutlinerItem

const CONTEXTUAL_MENU_MOVE_BACK = 0
const CONTEXTUAL_MENU_MOVE_FORWARD = 1

func update_contextual_menu():
	var move_to_layer_submenu := PopupMenu.new()
	for i in range(layers.size()):
		move_to_layer_submenu.add_item(layers.keys()[i], i)
	popup_menu.clear()
	
	popup_menu.add_item("Move back", CONTEXTUAL_MENU_MOVE_BACK)
	popup_menu.add_item("Move forward", CONTEXTUAL_MENU_MOVE_FORWARD)
	
	if popup_menu.has_node("MoveToLayerSubmenu"):
		popup_menu.get_node("MoveToLayerSubmenu").queue_free()
		popup_menu.remove_child(popup_menu.get_node("MoveToLayerSubmenu"))
	
	move_to_layer_submenu.name = "MoveToLayerSubmenu"
	popup_menu.add_child(move_to_layer_submenu, true)
	popup_menu.add_submenu_item("Move to layer", "MoveToLayerSubmenu")
	move_to_layer_submenu.connect("id_pressed", Callable(self, "_on_move_to_layer_pressed"))
	
func _on_move_to_layer_pressed(idx: int):
	layers[currently_selected_item.layer].remove_item_from_list(currently_selected_item)
	emit_signal("moved_component_to_layer", currently_selected_item.layer, layers.keys()[idx], currently_selected_item.node)
	currently_selected_item.queue_free()
	currently_selected_item = null
	
func _on_contextual_menu_id_pressed(id: int):
	match id:
		CONTEXTUAL_MENU_MOVE_BACK, CONTEXTUAL_MENU_MOVE_FORWARD:
			var position_change = 1
			if id == CONTEXTUAL_MENU_MOVE_BACK:
				position_change = -1
			
			var current_pos := currently_selected_item.node.get_index()
			var new_pos = clamp(current_pos + position_change, 0, currently_selected_item.node.get_parent().get_child_count()-1)
			if new_pos != current_pos:
				currently_selected_item.node.get_parent().move_child(currently_selected_item.node, new_pos)
				layers[currently_selected_item.layer].move_item_to(currently_selected_item, new_pos)
	
func _ready():
	add_child(popup_menu)
	popup_menu.connect("id_pressed", Callable(self, "_on_contextual_menu_id_pressed"))

func clear_layers():
	for layer in layers.values():
		layer.queue_free()
	layers.clear()
	selected_layer = ""
	currently_selected_item = null
	
func add_layer(layer_name: String):
	var layer := OutlinerLayer.new()
	layer.set_layer_name(layer_name)
	layers[layer_name] = layer
	add_child(layer)
	layer.connect("layer_selected", Callable(self, "_on_layer_selected").bind(layer_name))
	layer.connect("item_removed", Callable(self, "_on_item_removed"))
	layer.connect("contextual_menu_open_request", Callable(self, "_on_contextual_menu_open_request"))
	update_contextual_menu()
	
func _on_item_removed(item: HBUIComponent):
	emit_signal("item_removed", item)
	
func add_component(cmp: HBUIComponent, layer: String):
	var item := OutlinerItem.new(cmp)
	item.connect("item_selected", Callable(self, "_on_item_selected").bind(item))
	(layers[layer] as OutlinerLayer).add_item(item)

func _on_layer_selected(layer_name: String):
	selected_layer = layer_name
	for d_layer_name in layers:
		if layer_name == d_layer_name:
			continue
		layers[d_layer_name].deselect()

func get_selected_layer() -> String:
	return selected_layer

func _on_item_selected(item: OutlinerItem):
	emit_signal("component_selected", item.node)
	currently_selected_item = item

func _on_contextual_menu_open_request(item: OutlinerItem):
	popup_menu.popup()
	popup_menu.global_position = get_global_mouse_position()

#func _on_item_edited():
#	var item := get_edited()
#	var new_name := item.get_text(get_edited_column())
#	if new_name:
#		item.get_meta("node").name = new_name
#	item.set_text(0, item.get_meta("node").name)
