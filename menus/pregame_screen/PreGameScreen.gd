extends HBMenu

@onready var song_title = get_node("MarginContainer/VBoxContainer/SongTitle")
var button_container
var modifier_button_container
var modifier_scroll_container
var button_panel
@onready var modifier_selector = get_node("ModifierLoader")
@onready var modifier_settings_editor = get_node("ModifierSettingsOptionSection")
@onready var per_song_settings_editor: HBPerSongSettingsEditor = get_node("PerSongSettingsEditor")
var leaderboard_legal_text
@onready var ppd_video_url_change_confirmation_prompt = get_node("VideoURLChangePopup")
@onready var tabbed_container = get_node("MarginContainer/VBoxContainer/TabbedContainer")
var history_display: HBPreGameLeaderboardHistoryDisplay
var current_song: HBSong
var current_difficulty: String
var current_editing_modifier: String
const BASE_HEIGHT = 720.0

signal song_selected(song_id, difficulty)
signal begin_loading
var game_info = HBGameInfo.new()

var modifier_buttons = {}
var background_image

const LEADERBOARD_TAB = preload("res://menus/new_leaderboard_control/LeaderboardViewTab.tscn")

var leaderboard_tab_normal = LEADERBOARD_TAB.instantiate()
var leaderboard_tab_modifiers = LEADERBOARD_TAB.instantiate()

@onready var delete_song_media_popup := get_node("%DeleteSongMediaPopup")

signal volume_settings_changed(song: HBSong)

func _on_volume_settings_changed():
	volume_settings_changed.emit(current_song)

func _ready():
	super._ready()
	per_song_settings_editor.volume_settings_changed.connect(_on_volume_settings_changed)
	# Hacky af...
	var pregame_start_tab = preload("res://menus/pregame_screen/PregameStartTab.tscn").instantiate()
	
	tabbed_container.add_tab("Song", tr("Song"), pregame_start_tab)
	
	button_container = pregame_start_tab.button_container
	modifier_button_container = pregame_start_tab.modifier_button_container
	modifier_scroll_container = pregame_start_tab.modifier_scroll_container
	leaderboard_legal_text = pregame_start_tab.leaderboard_legal_text
	button_panel = pregame_start_tab.button_panel
	history_display = pregame_start_tab.history_display
	tabbed_container.add_tab("Leaderboard", tr("Leaderboard"), leaderboard_tab_normal)
	#tabbed_container.add_tab(tr("Leaderboard (Modifiers)"), leaderboard_tab_modifiers)
	
	
	modifier_settings_editor.hide()
	modifier_selector.back.connect(self._modifier_loader_back)
	modifier_selector.back.connect(tabbed_container.set_process_unhandled_input.bind(true))
	modifier_selector.modifier_selected.connect(self._on_user_added_modifier)
	
	modifier_settings_editor.back.connect(self._modifier_settings_editor_back)
	modifier_settings_editor.changed.connect(self._on_modifier_setting_changed)
	modifier_settings_editor.back.connect(self._modifier_loader_back)
	modifier_settings_editor.back.connect(tabbed_container.set_process_unhandled_input.bind(true))
	
	per_song_settings_editor.back.connect(self._modifier_loader_back)
	per_song_settings_editor.back.connect(tabbed_container.set_process_unhandled_input.bind(true))
	per_song_settings_editor.back.connect(self._modifier_loader_back)
	
	delete_song_media_popup.cancel.connect(modifier_scroll_container.grab_focus)
	delete_song_media_popup.cancel.connect(tabbed_container.set_process_unhandled_input.bind(true))
	
	ppd_video_url_change_confirmation_prompt.cancel.connect(tabbed_container.set_process_unhandled_input.bind(true))
	ppd_video_url_change_confirmation_prompt.cancel.connect(modifier_scroll_container.grab_focus)
	ppd_video_url_change_confirmation_prompt.accept.connect(self._on_ppd_video_url_confirmed)
	ppd_video_url_change_confirmation_prompt.accept.connect(tabbed_container.set_process_unhandled_input.bind(true))
	
	button_container.connect("out_from_top", Callable(self, "_on_button_list_out_from_top"))
	#per_song_settings_editor.show_editor()
	
	pregame_start_tab.start_button.connect("pressed", Callable(self, "_on_StartButton_pressed"))
	pregame_start_tab.start_practice_button.connect("pressed", Callable(self, "_on_StartPractice_pressed"))
	pregame_start_tab.back_button.connect("pressed", Callable(self, "_on_BackButton_pressed"))
	pregame_start_tab.back_button.set_meta("sfx", HBGame.menu_back_sfx)
	

var current_assets: SongAssetLoader.AssetLoadToken
var variant_select: Control

func set_current_assets(assets: SongAssetLoader.AssetLoadToken):
	if assets.song == current_song:
		current_assets = assets

func _on_user_added_modifier(modifier_id: String):
	if not modifier_id in game_info.modifiers:
		game_info.add_new_modifier(modifier_id)
		var button = add_modifier_control(modifier_id)
		modifier_scroll_container.select_item(button.get_index())
	modifier_scroll_container.grab_focus()
	UserSettings.save_user_settings()
	draw_leaderboard_legality()
	tabbed_container.set_process_unhandled_input(true)
	
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
	
func _on_menu_exit(force_hard_transition=false):
	super._on_menu_exit(force_hard_transition)
	MouseTrap.cache_song_overlay.disconnect("done", Callable(button_container, "grab_focus"))
	

func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	if args.has("song"):
		current_song = args.song
	button_container.select_button(0)
	current_difficulty = current_song.charts.keys()[0]
	if args.has("difficulty"):
		current_difficulty = args.difficulty

	song_title.difficulty = current_difficulty
	song_title.set_song(current_song)
	game_info = UserSettings.user_settings.last_game_info.clone()
	UserSettings.user_settings.last_game_info = game_info
	game_info.song_id = current_song.id
	
	leaderboard_tab_normal.song = current_song
	leaderboard_tab_normal.difficulty = current_difficulty
	
	leaderboard_tab_modifiers.song = current_song
	leaderboard_tab_modifiers.difficulty = current_difficulty
	leaderboard_tab_modifiers.include_modifiers = true
	
	leaderboard_tab_normal.reset()
	leaderboard_tab_modifiers.reset()
	
	emit_signal("song_selected", current_song.id, current_difficulty)
	update_modifiers()
	tabbed_container.show_tab("Song")
	
	MouseTrap.cache_song_overlay.connect("done", Callable(button_container, "grab_focus").bind(), CONNECT_DEFERRED)
	history_display.song = current_song
	history_display.difficulty = current_difficulty
		
func _on_button_list_out_from_top():
	modifier_scroll_container.grab_focus()
	modifier_scroll_container.select_item(modifier_button_container.get_child_count()-1)
	
func _on_StartButton_pressed():
	var selected_variant = -1
	if variant_select:
		selected_variant = variant_select.value
		var stats = HBGame.song_stats.get_song_stats(current_song.id)
		stats.selected_variant = selected_variant
		HBGame.song_stats.song_stats[current_song.id] = stats
	if not current_song.is_cached(selected_variant):
		MouseTrap.cache_song_overlay.show_download_prompt(current_song, selected_variant, true)
		return
	game_info.variant = selected_variant
	
	var new_scene = preload("res://menus/LoadingScreen.tscn")
	game_info.time = Time.get_unix_time_from_system()
	var scene = new_scene.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	game_info.song_id = current_song.id
	game_info.difficulty = current_difficulty
	emit_signal("begin_loading")
	scene.load_song(game_info, false, current_assets)

func add_modifier_control(modifier_id: String):
	var modifier_class = ModifierLoader.get_modifier_by_id(modifier_id)
	var button = preload("res://menus/pregame_screen/ModifierButton.tscn").instantiate()
	button.focus_neighbor_right = history_display.get_path()
	modifier_button_container.add_child(button)
	
	var modifier = modifier_class.new() as HBModifier
	modifier.modifier_settings = game_info.modifiers[modifier_id]
	button.text = modifier.get_modifier_list_name()
	button.connect("edit_modifier", Callable(self, "_on_open_modifier_settings_selected").bind(modifier_id))
	button.connect("remove_modifier", Callable(self, "_on_remove_modifier_selected").bind(modifier_id, button))
	if modifier_class.get_option_settings().is_empty():
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
	tabbed_container.set_process_unhandled_input(false)
	
func select_song(s: HBSong):
	if not is_inside_tree():
		current_song = s
func _on_modify_song_settings_pressed():
	per_song_settings_editor.current_song = current_song
	per_song_settings_editor.show()
	per_song_settings_editor.show_editor()
	tabbed_container.set_process_unhandled_input(false)
	

func _on_remove_modifier_selected(modifier_id: String, modifier_button):
	var current_button_i = modifier_button.get_index()
	var new_button_i = current_button_i-1
	new_button_i = clamp(new_button_i, 0, modifier_button_container.get_child_count()-1)
	modifier_scroll_container.select_item(new_button_i)
	
	modifier_button_container.remove_child(modifier_button)
	modifier_buttons.erase(modifier_id)
	modifier_button.queue_free()
	game_info.modifiers.erase(modifier_id)
	UserSettings.save_user_settings()
	draw_leaderboard_legality()
	
func draw_leaderboard_legality():
	var song = SongLoader.songs[game_info.song_id] as HBSong
	if HBBackend.can_have_scores_uploaded(song):
		leaderboard_legal_text.text = "The current song and settings will count towards leaderboard scores"
		if game_info.modifiers.size() > 0:
			leaderboard_legal_text.text = "The current song will not count towards leaderboard scores"
	else:
		leaderboard_legal_text.text = "Only workshop or PPD songs can have their scores uploaded!"
	
func add_buttons():
	var modify_song_settings_option = HBHovereableButton.new()
	modify_song_settings_option.text = "Song settings"
	modify_song_settings_option.expand_icon = true
	modify_song_settings_option.icon = preload("res://graphics/icons/settings.svg")
	modify_song_settings_option.connect("pressed", Callable(self, "_on_modify_song_settings_pressed"))
	modifier_button_container.add_child(modify_song_settings_option)
	
	if current_song is HBPPDSong and not current_song.uses_native_video:
		var change_video_link_button = HBHovereableButton.new()
		change_video_link_button.text = "Change PPD video URL"
		change_video_link_button.connect("pressed", Callable(self, "_on_ppd_video_change_button_pressed"))
		modifier_button_container.add_child(change_video_link_button)
	elif current_song.get_fs_origin() == current_song.SONG_FS_ORIGIN.USER and current_song.youtube_url:
			var delete_media = HBHovereableButton.new()
			delete_media.text = "Delete song media"
			delete_media.connect("pressed", Callable(delete_song_media_popup, "popup_centered"))
			delete_media.connect("pressed", Callable(delete_song_media_popup, "grab_focus"))
			delete_media.pressed.connect(delete_song_media_popup.grab_focus)
			delete_media.pressed.connect(tabbed_container.set_process_unhandled_input.bind(false))
			modifier_button_container.add_child(delete_media)
			
	
	if current_song is HBPPDSong \
			or current_song.ugc_service_name == "Steam Workshop":
		var open_leaderboard_button = HBHovereableButton.new()
		open_leaderboard_button.expand_icon = true
		open_leaderboard_button.text = tr("View leaderboards on the website")
		open_leaderboard_button.connect("pressed", Callable(self, "_on_open_leaderboard_pressed"))
		open_leaderboard_button.icon = preload("res://graphics/icons/table.svg")
		modifier_button_container.add_child(open_leaderboard_button)
	
	var add_modifier_button = HBHovereableButton.new()
	add_modifier_button.text = "Add modifier"
	add_modifier_button.expand_icon = true
	add_modifier_button.icon = preload("res://graphics/icons/icon_add.svg")
	add_modifier_button.connect("pressed", Callable(self, "_on_add_modifier_pressed"))
	modifier_button_container.add_child(add_modifier_button)
	
	variant_select = null
	
	if current_song.song_variants.size() > 0:
		var last_variant = HBGame.song_stats.get_song_stats(current_song.id).selected_variant
		variant_select = preload("res://menus/options_menu/OptionSelect.tscn").instantiate()
		variant_select.options = [-1]
		variant_select.text = tr("Video/Audio variant")
		variant_select.options_pretty = ["Default"]
		variant_select.connect("back", Callable(modifier_scroll_container, "grab_focus"))
		for i in range(current_song.song_variants.size()):
			variant_select.options.append(i)
			variant_select.options_pretty.append(current_song.get_variant_data(i).variant_name)
		modifier_button_container.add_child(variant_select)
		variant_select.set_block_signals(true)
		variant_select.value = -1
		if last_variant != -1 and last_variant < current_song.song_variants.size():
			variant_select.value = last_variant
		variant_select.set_block_signals(false)
func update_modifiers():
	modifier_buttons = {}
	for button in modifier_button_container.get_children():
		modifier_button_container.remove_child(button)
		button.queue_free()
	add_buttons()

	for modifier_id in game_info.modifiers:
		add_modifier_control(modifier_id)

	draw_leaderboard_legality()
func _on_add_modifier_pressed():
	modifier_selector.popup()
	tabbed_container.set_process_unhandled_input(false)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		get_viewport().set_input_as_handled()
		_on_BackButton_pressed()
	
func _input(event):
	if modifier_scroll_container.has_focus() and (event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right")):
		var selected = modifier_scroll_container.get_selected_item()
		if selected:
			if selected.has_method("_gui_input"):
				get_viewport().set_input_as_handled()
				selected._gui_input(event)

func _on_BackButton_pressed():
	per_song_settings_editor.hide()
	modifier_selector.hide()
	change_to_menu("song_list", false, {"song": current_song.id, "song_difficulty": current_difficulty})

func _on_ppd_video_change_button_pressed():
	$VideoURLChangePopup.popup_centered_ratio(0.5)
	tabbed_container.set_process_unhandled_input(false)
func _on_ppd_video_url_confirmed():
	var args = {
		"song": current_song.id,
		"song_difficulty": current_difficulty,
		"force_url_request": true
		}
	change_to_menu("song_list", false, args)
	
func _on_open_leaderboard_pressed():
	var song_ugc_type = "steam"
	if current_song is HBPPDSong:
		song_ugc_type = "ppd"
	OS.shell_open("https://ph.eirteam.moe/leaderboard/%s/%s/%s/1" % [song_ugc_type, str(current_song.ugc_id), current_difficulty])

func _on_StartPractice_pressed():
	var selected_variant = -1
	if variant_select:
		selected_variant = variant_select.options[variant_select.selected_option]
		if selected_variant != -1:
			if not current_song.is_cached(selected_variant):
				MouseTrap.cache_song_overlay.show_download_prompt(current_song, selected_variant, true)
				return
		var stats = HBGame.song_stats.get_song_stats(current_song.id)
		stats.selected_variant = selected_variant
		HBGame.song_stats.save_song_stats()
	game_info.variant = selected_variant
	var new_scene = preload("res://menus/LoadingScreen.tscn")
	game_info.time = Time.get_unix_time_from_system()
	var scene = new_scene.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	game_info.song_id = current_song.id
	game_info.difficulty = current_difficulty
	emit_signal("begin_loading")
	scene.load_song(game_info, true, current_assets)

func _on_DeleteSongMediaPopup_accept():
	if current_song.youtube_url:
		var video_id := YoutubeDL.get_video_id(current_song.youtube_url) as String
		if video_id:
			YoutubeDL.cleanup_video_media(video_id, true, true)
	_on_BackButton_pressed()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for tab in [leaderboard_tab_normal, leaderboard_tab_modifiers]:
			if is_instance_valid(tab) and not tab.is_queued_for_deletion():
				tab.queue_free()
