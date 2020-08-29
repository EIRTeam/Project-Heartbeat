extends HBMenu

onready var song_title = get_node("MarginContainer/VBoxContainer/SongTitle")
onready var button_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel2/MarginContainer/VBoxContainer")
onready var modifier_button_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer")
onready var modifier_scroll_container = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer")
onready var button_panel = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel2")
onready var modifier_selector = get_node("ModifierLoader")
onready var modifier_settings_editor = get_node("ModifierSettingsOptionSection")
onready var per_song_settings_editor = get_node("PerSongSettingsEditor")
onready var leaderboard_legal_text = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/HBoxContainer/VBoxContainer/Panel2/HBoxContainer/Label")
onready var ppd_video_url_change_confirmation_prompt = get_node("VideoURLChangePopup")
onready var stats_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel2/StatsLabel")
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
	per_song_settings_editor.connect("back", self, "_modifier_loader_back")
	ppd_video_url_change_confirmation_prompt.connect("cancel", modifier_scroll_container, "grab_focus")
	ppd_video_url_change_confirmation_prompt.connect("accept", self, "_on_ppd_video_url_confirmed")
	button_container.connect("out_from_top", self, "_on_button_list_out_from_top")
	#per_song_settings_editor.show_editor()

func _on_user_added_modifier(modifier_id: String):
	if not modifier_id in game_info.modifiers:
		game_info.add_new_modifier(modifier_id)
		var button = add_modifier_control(modifier_id)
		modifier_scroll_container.select_child(button)
	modifier_scroll_container.grab_focus()
	UserSettings.save_user_settings()
	draw_leaderboard_legality()
	
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
	game_info = UserSettings.user_settings.last_game_info.clone()
	UserSettings.user_settings.last_game_info = game_info
	game_info.song_id = current_song.id
	
	emit_signal("song_selected", current_song.id, current_difficulty)
	update_modifiers()
	
	update_song_stats_label()
func update_song_stats_label():
	var stats = HBGame.song_stats.get_song_stats(current_song.id)
	var highest_score_string = "Never played"
	if ScoreHistory.has_result(current_song.id, current_difficulty):
		var result := ScoreHistory.get_result(current_song.id, current_difficulty) as HBResult
		var pass_percentage = result.get_percentage()
		var thousands_sep_score = HBUtils.thousands_sep(result.score)
		highest_score_string = "%s (%.2f %%)" % [thousands_sep_score, pass_percentage*100]
	var text = "Times Played: %d\n\nHighest score:\n%s" % [stats.times_played, highest_score_string]
	stats_label.text = text
	
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
	
func _on_modify_song_settings_pressed():
	per_song_settings_editor.current_song = current_song
	per_song_settings_editor.show_editor()
	

func _on_remove_modifier_selected(modifier_id: String, modifier_button):
	var current_button_i = modifier_button.get_position_in_parent()
	var new_button_i = current_button_i-1
	new_button_i = clamp(new_button_i, 0, modifier_button_container.get_child_count()-1)
	modifier_scroll_container.select_child(modifier_button_container.get_child(new_button_i))
	
	modifier_button_container.remove_child(modifier_button)
	modifier_buttons.erase(modifier_id)
	modifier_button.queue_free()
	game_info.modifiers.erase(modifier_id)
	UserSettings.save_user_settings()
	draw_leaderboard_legality()
	
func draw_leaderboard_legality():
	if game_info.is_leaderboard_legal():
		leaderboard_legal_text.text = "The current song will count towards leaderboard scores"
	else:
		leaderboard_legal_text.text = "Modifiers are not allowed in the leaderboards, thus this score won't count"
	
func add_buttons():
	var modify_song_settings_option = HBHovereableButton.new()
	modify_song_settings_option.text = "Song settings"
	modify_song_settings_option.expand_icon = true
	modify_song_settings_option.icon = preload("res://graphics/icons/settings.svg")
	modify_song_settings_option.connect("pressed", self, "_on_modify_song_settings_pressed")
	modifier_button_container.add_child(modify_song_settings_option)
	
	if current_song is HBPPDSong:
		var change_video_link_button = HBHovereableButton.new()
		change_video_link_button.text = "Change PPD video URL"
		change_video_link_button.connect("pressed", self, "_on_ppd_video_change_button_pressed")
		modifier_button_container.add_child(change_video_link_button)
	
	var add_modifier_button = HBHovereableButton.new()
	add_modifier_button.text = "Add modifier"
	add_modifier_button.expand_icon = true
	add_modifier_button.icon = preload("res://graphics/icons/icon_add.svg")
	add_modifier_button.connect("pressed", self, "_on_add_modifier_pressed")
	modifier_button_container.add_child(add_modifier_button)
func update_modifiers():
	modifier_buttons = {}
	modifier_scroll_container.selected_child = null
	for button in modifier_button_container.get_children():
		modifier_button_container.remove_child(button)
		button.queue_free()
	add_buttons()

	var last_modifier
	for modifier_id in game_info.modifiers:
		last_modifier = add_modifier_control(modifier_id)
	draw_leaderboard_legality()
func _on_add_modifier_pressed():
	modifier_selector.popup()
func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		get_tree().set_input_as_handled()
		_on_BackButton_pressed()

func _on_BackButton_pressed():
	change_to_menu("song_list", false, {"song": current_song.id, "song_difficulty": current_difficulty})

func _on_ppd_video_change_button_pressed():
	$VideoURLChangePopup.popup_centered_ratio(0.5)
func _on_ppd_video_url_confirmed():
	var args = {
		"song": current_song.id,
		"song_difficulty": current_difficulty,
		"force_url_request": true
		}
	change_to_menu("song_list", false, args)
	


func _on_StartPractice_pressed():
	var new_scene = preload("res://rythm_game/practice_mode.tscn")
	game_info.time = OS.get_unix_time()
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	game_info.song_id = current_song.id
	game_info.difficulty = current_difficulty
	scene.start_session(game_info)
