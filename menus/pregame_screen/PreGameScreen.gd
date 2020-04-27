extends HBMenu

onready var song_title = get_node("MarginContainer/VBoxContainer/SongTitle")
onready var button_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel2/MarginContainer/VBoxContainer")
onready var modifier_button_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer")
onready var modifier_scroll_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer")
onready var button_panel = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel2")
onready var modifier_selector = get_node("ModifierLoader")
onready var modifier_settings_editor = get_node("ModifierSettingsOptionSection")
var current_song: HBSong
var current_difficulty: String
var current_editing_modifier: String
const BASE_HEIGHT = 720.0

signal song_selected(song_id, difficulty)
var game_info = HBGameInfo.new()

var modifier_buttons = {}

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
	modifier_settings_editor.hide()
	modifier_selector.connect("back", self, "_modifier_loader_back")
	modifier_selector.connect("modifier_selected", self, "_on_user_added_modifier")
	modifier_settings_editor.connect("back", self, "_modifier_settings_editor_back")
	modifier_settings_editor.connect("changed", self, "_on_modifier_setting_changed")
func _on_user_added_modifier(modifier_id: String):
	if not modifier_id in game_info.modifiers:
		game_info.add_new_modifier(modifier_id)
		var button = add_modifier_control(modifier_id)
		modifier_scroll_container.select_child(button)
	modifier_scroll_container.grab_focus()
	UserSettings.save_user_settings()
	
func _modifier_settings_editor_back():
	modifier_settings_editor.hide()
	modifier_scroll_container.grab_focus()
	
func _on_modifier_setting_changed(property_name, new_value):
	game_info.modifiers[current_editing_modifier].set(property_name, new_value)
	var modifier_class = ModifierLoader.get_modifier_by_id(current_editing_modifier)
	var modifier = modifier_class.new() as HBModifier
	modifier.modifier_settings = game_info.modifiers[current_editing_modifier]
	modifier_buttons[current_editing_modifier].text = modifier.get_modifier_list_name()
	UserSettings.save_user_settings()
	
func _modifier_loader_back():
	modifier_scroll_container.grab_focus()
	
func _on_resized():
	# We have to wait a frame for the resize to happen...
	# seriously wtf
	yield(get_tree(), "idle_frame")
	var inv = 1.0 / (rect_size.y / BASE_HEIGHT)
	button_panel.size_flags_stretch_ratio = inv

func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("song"):
		current_song = args.song
	button_container.select_button(0)
	button_container.grab_focus()
	current_difficulty = current_song.charts.keys()[0]
	if args.has("difficulty"):
		current_difficulty = args.difficulty
	song_title.difficulty = current_difficulty
	song_title.set_song(current_song)
	game_info = UserSettings.user_settings.last_game_info
	emit_signal("song_selected", current_song.id, current_difficulty)
	update_modifiers()
	button_container.connect("out_from_top", self, "_on_button_list_out_from_top")
	
func _on_button_list_out_from_top():
	modifier_scroll_container.grab_focus()
	modifier_scroll_container.select_child(modifier_button_container.get_child(modifier_button_container.get_child_count()-1))
	
func _on_StartButton_pressed():
	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
	game_info.time = OS.get_unix_time()
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	
	game_info.song_id = current_song.id
	game_info.difficulty = current_difficulty
	scene.start_session(game_info)

func add_modifier_control(modifier_id: String):
	
	var modifier_class = ModifierLoader.get_modifier_by_id(modifier_id)
	var button = preload("res://menus/pregame_screen/ModifierButton.tscn").instance()
	modifier_button_container.add_child(button)
	
	var modifier = modifier_class.new() as HBModifier
	modifier.modifier_settings = game_info.modifiers[modifier_id]
	button.text = modifier.get_modifier_list_name()
	button.connect("edit_modifier", self, "_on_open_modifier_settings_selected", [modifier_id])
	button.connect("remove_modifier", self, "_on_remove_modifier_selected", [modifier_id, button])
	if modifier_class.get_option_settings().empty():
		button.remove_settings_button()
	modifier_buttons[modifier_id] = button
	return button
func _on_open_modifier_settings_selected(modifier_id: String):
	modifier_settings_editor.show()
	current_editing_modifier = modifier_id
	var modifier_class = ModifierLoader.get_modifier_by_id(modifier_id)
	modifier_settings_editor.settings_source = game_info.modifiers[modifier_id]
	modifier_settings_editor.section_data = modifier_class.get_option_settings()
	modifier_settings_editor.show()
	modifier_settings_editor.grab_focus()
	
func _on_remove_modifier_selected(modifier_id: String, modifier_button):
	var current_button_i = modifier_button.get_position_in_parent()
	var new_button_i = current_button_i-1
	new_button_i = clamp(new_button_i, 0, modifier_button_container.get_child_count()-1)
	modifier_scroll_container.select_child(modifier_button_container.get_child(new_button_i))
	
	modifier_button_container.remove_child(modifier_button)
	modifier_buttons.erase(modifier_id)
	modifier_button.queue_free()
	game_info.modifiers.erase(modifier_id)
	
func update_modifiers():
	modifier_buttons = {}
	modifier_scroll_container.selected_child = null
	for button in modifier_button_container.get_children():
		modifier_button_container.remove_child(button)
		button.queue_free()
	var add_modifier_button = HBHovereableButton.new()
	add_modifier_button.text = "Add modifier"
	add_modifier_button.connect("pressed", self, "_on_add_modifier_pressed")
	modifier_button_container.add_child(add_modifier_button)
	var last_modifier
	for modifier_id in game_info.modifiers:
		last_modifier = add_modifier_control(modifier_id)

func _on_add_modifier_pressed():
	modifier_selector.popup()

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		get_tree().set_input_as_handled()
		_on_BackButton_pressed()

func _on_BackButton_pressed():
	change_to_menu("song_list", false, {"song": current_song.id, "song_difficulty": current_difficulty})
