extends HBMenu

@onready var scroll_list = get_node("MarginContainer/VBoxContainer/ScrollContainer")
@onready var lobbies_found_label = get_node("MarginContainer/VBoxContainer/LobbiesFoundLabel")
@onready var create_lobby_button = get_node("MarginContainer/VBoxContainer/CreateLobbyMenu/CreateLobbyButton")
@onready var create_lobby_menu = get_node("MarginContainer/VBoxContainer/CreateLobbyMenu")
@onready var loadingu = get_node("MarginContainer/VBoxContainer/ScrollContainer/CenterContainer")
@onready var refresh_lobby_button = get_node("MarginContainer/VBoxContainer/CreateLobbyMenu/RefreshLobbyListButton")
@onready var status_prompt = get_node("StatusPrompt")
@onready var error_prompt = get_node("ErrorPrompt")

const LobbyListItem = preload("res://multiplayer/lobby/LobbyListItem.tscn")

func _ready():
	super._ready()
	scroll_list.connect("out_from_top", Callable(self, "_on_out_from_top"))
	create_lobby_menu.connect("bottom", Callable(self, "_on_create_lobby_menu_down"))
	refresh_lobby_button.connect("pressed", Callable(self, "refresh_lobby_list"))
func _on_menu_enter(force_hard_transition=false, args={}):
	super._on_menu_enter(force_hard_transition, args)
	
	var mp_provider = PlatformService.service_provider.multiplayer_provider
	mp_provider.connect("lobby_match_list", Callable(self, "_on_get_lobby_list"))
	refresh_lobby_list()
	create_lobby_menu.grab_focus()
	
func _on_menu_exit(force_hard_transition=false):
	super._on_menu_exit(force_hard_transition)
	var mp_provider = PlatformService.service_provider.multiplayer_provider
	mp_provider.disconnect("lobby_match_list", Callable(self, "_on_get_lobby_list"))
	
func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		get_viewport().set_input_as_handled()
		change_to_menu("main_menu")
	
func _on_get_lobby_list(lobbies):
	var first_child
	for lobby in lobbies:
			
		var item = LobbyListItem.instantiate()
		scroll_list.item_container.add_child(item)
		item.set_lobby(lobby)
		item.connect("pressed", Callable(self, "_on_lobby_button_pressed").bind(lobby))
		if not first_child:
			first_child = item
#	if first_child:
#		scroll_list.select_child(first_child)
	var n_of_lobbies = lobbies.size()
	if n_of_lobbies == 1:
		lobbies_found_label.text = "%d lobby found!" % [n_of_lobbies]
	else:
		lobbies_found_label.text = "%d lobbies found!" % [n_of_lobbies]
	loadingu.hide()
#	if lobbies.size() <= 0:
#		create_lobby_menu.grab_focus()
func refresh_lobby_list():
	for child in scroll_list.item_container.get_children():
		scroll_list.item_container.remove_child(child)
		child.queue_free()
	var mp_provider = PlatformService.service_provider.multiplayer_provider
	mp_provider.request_lobby_list()
	loadingu.show()
	lobbies_found_label.text = "Loadingu..."
func _on_out_from_top():
	create_lobby_menu.grab_focus()
	
func _on_create_lobby_menu_down():
	if scroll_list.item_container.get_child_count() > 0:
		scroll_list.grab_focus()

func _on_lobby_button_pressed(lobby: HBLobby):
	
	if lobby.song_id in SongLoader.songs or lobby.song_id.begins_with("ugc_"):
		lobby.connect("lobby_joined", Callable(self, "_on_lobby_joined").bind(lobby), CONNECT_ONE_SHOT)
		lobby.join_lobby()
	else:
		show_error("You do not have this song")

func show_error(error: String):
	error_prompt.connect("accept", Callable(self, "_on_error_prompt_accepted").bind(get_viewport().gui_get_focus_owner()), CONNECT_ONE_SHOT)
	error_prompt.text = error
	error_prompt.popup_centered_ratio(0.5)
func _on_error_prompt_accepted(old_focus):
	old_focus.grab_focus()
	
func show_status(message: String):
	status_prompt.text = message
	status_prompt.popup_centered_ratio(0.5)
	
func _on_lobby_joined(response, lobby: HBLobby):
	status_prompt.hide()
	print("Joined lobby ", lobby.lobby_name)
	if response == HBLobby.LOBBY_ENTER_RESPONSE.SUCCESS:
		change_to_menu("lobby", false, {"lobby": lobby})
	else:
		show_error("Error joining lobby")


func _on_CreateLobbyButton_pressed():
	var mp_provider = PlatformService.service_provider.multiplayer_provider
	var lobby = mp_provider.create_lobby() as HBLobby
	lobby.connect("lobby_joined", Callable(self, "_on_lobby_joined").bind(lobby))
	lobby.connect("lobby_created", Callable(self, "_on_lobby_created").bind(lobby), CONNECT_ONE_SHOT)
	lobby.create_lobby()
	
func _on_lobby_created(response, lobby: HBLobby):
	if not response == HBLobby.LOBBY_CREATION_RESULT.OK:
		show_error("Error creating lobby")
