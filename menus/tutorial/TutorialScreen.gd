extends HBMenu

@onready var page_label: Label = get_node("Panel/MarginContainer/VBoxContainer/Label")
@onready var page_container = get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer2/VBoxContainer")
@onready var previous_arrow = get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/PreviousArrow")
@onready var next_arrow = get_node("Panel/MarginContainer/VBoxContainer/HBoxContainer/NextArrow")

var page = -1

func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	go_to_page(0)
	
func go_to_page(next_page: int):
	if not next_page == self.page:
		self.page = next_page
		for child in page_container.get_children():
			child.hide()
		page_container.get_child(page).show()
		
		if page == 0:
			previous_arrow.modulate.a = 0.0
		else:
			previous_arrow.modulate.a = 1.0
		if page == page_container.get_child_count()-1:
			next_arrow.modulate.a = 0.0
		else:
			next_arrow.modulate.a = 1.0
		
		update_page_label()
func update_page_label():
	page_label.text = "%d/%d" % [page+1, page_container.get_child_count()]

func _unhandled_input(event):
	if event.is_action_pressed("gui_left"):
		go_to_page(clamp((page-1), 0, page_container.get_child_count()-1))
	if event.is_action_pressed("gui_right"):
		go_to_page(clamp((page+1), 0, page_container.get_child_count()-1))
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		change_to_menu("main_menu")
