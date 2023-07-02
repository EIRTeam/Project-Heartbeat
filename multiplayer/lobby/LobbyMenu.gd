extends HBMenu

@onready var chat_box = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Chat/MarginContainer/RichTextLabel")
@onready var member_list = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MemberList")
@onready var lobby_name_label = get_node("MarginContainer/VBoxContainer/Label")
@onready var chat_line_edit = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LineEdit")
@onready var options_vertical_menu = get_node ("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/Panel/MarginContainer/VBoxContainer")
@onready var waiting_for_song_confirmation_prompt = get_node("WaitingForSongConfirmation")
@onready var song_confirmation_error_prompt = get_node("SongConfirmationError")
@onready var downloading_message_prompt = get_node("DownloadingMesssage")

var lobby: HBLobby
var selected_song: HBSong
var selected_difficulty: String

signal song_selected(song)

var song_availabilities = {}
var checking_song_availabilities = false
var waiting_for_ugc_downloads_to_complete = false

func _ready():
	super._ready()
	var starting_song = SongLoader.songs.values()[0]
	select_song(starting_song, starting_song.charts.keys()[0])
	options_vertical_menu.connect("bottom", Callable(self, "_options_vertical_menu_from_bottom"))
	waiting_for_song_confirmation_prompt.connect("cancel", Callable(self, "_on_song_availability_check_cancelled"))
	waiting_for_song_confirmation_prompt.connect("cancel", Callable(options_vertical_menu, "grab_focus"))
	song_confirmation_error_prompt.connect("accept", Callable(options_vertical_menu, "grab_focus"))
func select_song(song: HBSong, difficulty: String):
	selected_song = song
	selected_difficulty = difficulty
	emit_signal("song_selected", selected_song)
	
func _on_menu_exit(force_hard_transition=false):
	super._on_menu_exit(force_hard_transition)
	
func _on_menu_enter(force_hard_transition=false, args={}):
	super._on_menu_enter(force_hard_transition, args)
	if lobby:
		connect_lobby(lobby)
	if args.has("lobby"):
		set_lobby(args.lobby)
	chat_line_edit.clear()
	# Sets the song wen returning from lobby song select, or not if we are just joining
	if args.has("song"):
		var song = args.song as HBSong
		lobby.song_name = song.get_visible_title()
		lobby.song_id = song.id
		lobby.song_difficulty = args.difficulty
		lobby.send_game_info_update()
	else:
		if lobby.get_song():
			select_song(lobby.get_song(), lobby.song_difficulty)
	# HACK! Else we select the wrong button when we don't do this
	await get_tree().process_frame
	options_vertical_menu.grab_focus()
	update_member_list()
	_check_ownership_changed()

func _check_ownership_changed():
	if is_inside_tree():
		if lobby.is_owned_by_local_user():
			get_tree().call_group("owner_only", "show")
		else:
			get_tree().call_group("owner_only", "hide")

func _on_song_availability_check_cancelled():
	checking_song_availabilities = false

func update_member_list():
	if is_inside_tree():
		member_list.clear_members()
		for member in lobby.members.values():
			var is_owner = false
			if lobby.get_lobby_owner() == member:
				is_owner = true
			member_list.add_member(member, is_owner, lobby.is_owned_by_local_user())

func update_lobby_data_display():
	lobby_name_label.text = lobby.lobby_name
	if lobby.get_song():
		select_song(lobby.get_song(), lobby.song_difficulty)

func _on_host_changed():
	update_member_list()
	_check_ownership_changed()
	var msg = lobby.get_lobby_owner().member_name + " is the new host."
	append_service_message(msg, Color.GREEN)

func connect_lobby(_lobby: HBLobby):
	if not _lobby.is_connected("lobby_chat_message", Callable(self, "_on_chat_message_received")):
		_lobby.connect("lobby_chat_message", Callable(self, "_on_chat_message_received"))
		_lobby.connect("lobby_chat_update", Callable(self, "_on_lobby_chat_update"))
		_lobby.connect("lobby_data_updated", Callable(self, "update_lobby_data_display"))
		_lobby.connect("lobby_loading_start", Callable(self, "_on_lobby_loading_start"))
		_lobby.connect("user_song_availability_update", Callable(self, "_on_user_song_availability_update"))
		_lobby.connect("check_songs_request_received", Callable(self, "_on_check_songs_request_received"))
		_lobby.connect("reported_ugc_song_downloaded", Callable(self, "_on_ugc_song_downloaded"))
		_lobby.connect("host_changed", Callable(self, "_on_host_changed"))
	
func disconnect_lobby(_lobby: HBLobby):
	if _lobby.is_connected("lobby_chat_message", Callable(self, "_on_chat_message_received")):
		_lobby.disconnect("lobby_chat_message", Callable(self, "_on_chat_message_received"))
		_lobby.disconnect("lobby_chat_update", Callable(self, "_on_lobby_chat_update"))
		_lobby.disconnect("lobby_data_updated", Callable(self, "update_lobby_data_display"))
		_lobby.disconnect("lobby_loading_start", Callable(self, "_on_lobby_loading_start"))
		_lobby.disconnect("user_song_availability_update", Callable(self, "_on_user_song_availability_update"))
		_lobby.disconnect("check_songs_request_received", Callable(self, "_on_check_songs_request_received"))
		_lobby.disconnect("reported_ugc_song_downloaded", Callable(self, "_on_ugc_song_downloaded"))
		_lobby.disconnect("host_changed", Callable(self, "_on_host_changed"))
	
func set_lobby(_lobby: HBLobby):
	if self.lobby:
		disconnect_lobby(_lobby)
	self.lobby = _lobby

	connect_lobby(_lobby)
	
	member_list.lobby = self.lobby
	update_member_list()
	update_lobby_data_display()
#	if not lobby is SteamLobby:
#		get_tree().call_group("steam_only", "hide")
func _on_chat_message_received(member: HBServiceMember, message, type):
	match type:
		HBLobby.CHAT_MESSAGE_TYPE.MESSAGE:
			chat_box.text += "\n" + member.get_member_name() + ": " + str(message)

func append_service_message(message: String, color=Color.RED):
	chat_box.text += "\n[color=#%s]%s[/color]" % [color.to_html(false).to_upper(), message]

func _on_lobby_chat_update(changed: HBServiceMember, making_change: HBServiceMember, state):
	var msg
	var color = Color.RED
	if state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.JOINED:
		msg = " has joined."
		color = Color.GREEN
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.LEFT:
		msg = " has left."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.DISCONNECTED:
		msg = " has disconnected."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.KICKED:
		msg = " has been kicked."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.BANNED:
		msg = " has been banned."
	else:
		color = Color.PURPLE
		msg = " has managed to break space-time."
	
	msg = str(changed.member_name) + msg
	append_service_message(msg, color)
	update_member_list()
	_check_ownership_changed()
	
func send_chat_message():
	var text = chat_line_edit.text.strip_edges()
	if text != "" and not text.begins_with("/"):
		lobby.send_chat_message(text)
	chat_line_edit.text = ""

func _on_LeaveLobbyButton_pressed():
	disconnect_lobby(lobby)
	lobby.leave_lobby()
	change_to_menu("lobby_list")

func _on_ugc_song_downloaded(user: HBServiceMember, ugc_id: int):
	if ugc_id == selected_song.ugc_id:
		song_availabilities[user] = true
	var found_false = false
	for lobby_user in song_availabilities:
		if not song_availabilities[lobby_user]:
			found_false = true
	if not found_false:
		start_multiplayer_session_authority()
func _on_user_song_availability_update(sender_user: HBServiceMember, song_id, available: bool):
	if not checking_song_availabilities:
		return
	if song_id != selected_song.id:
		return
	song_availabilities[sender_user] = available
	var not_owned_by_users = []
	if song_availabilities.size() >= lobby.get_lobby_member_count():
		for user in song_availabilities:
			var owned = song_availabilities[user]
			if not owned:
				not_owned_by_users.append(user)
				
	if song_availabilities.size() >= lobby.get_lobby_member_count():
		var struwu = ""
		for i in range(not_owned_by_users.size()):
			var user = not_owned_by_users[i]
			if i != 0:
				struwu += ","
			struwu += " %s" % user.get_member_name()
		waiting_for_song_confirmation_prompt.hide()
		if not_owned_by_users.size() > 0:
			song_confirmation_error_prompt.text = "ERROR: The following users don't have this song: %s" % [struwu]
			checking_song_availabilities = false
			waiting_for_ugc_downloads_to_complete = true
			if selected_song.comes_from_ugc():
				downloading_message_prompt.text = song_confirmation_error_prompt.text
				downloading_message_prompt.text += "\nwaiting for song to be downloaded automatically by their game..."
				downloading_message_prompt.popup_centered()
			else:
				song_confirmation_error_prompt.popup_centered()
		else:
			start_multiplayer_session_authority()

func _on_check_songs_request_received(song_id: String):
	if not song_id in SongLoader.songs:
		if song_id.begins_with("ugc_"):
			downloading_message_prompt.text = "Downloading song..."
			downloading_message_prompt.popup_centered()
			var o = PlatformService.service_provider.ugc_provider.download_item(int(song_id.substr(4, -1)))
			if not o:
				downloading_message_prompt.hide()
				song_confirmation_error_prompt.text = "ERROR STARTING GAME: Error downloading workshop song."
				song_confirmation_error_prompt.popup_centered()
		else:
			song_confirmation_error_prompt.text = "ERROR STARTING GAME: You don't seem to have the currently selected song."
			song_confirmation_error_prompt.popup_centered()
	else:
		var song = SongLoader.songs[song_id] as HBSong
		if not song.is_cached():
			if not YoutubeDL.is_already_downloading(song):
				song.cache_data() 
			if song_id.begins_with("ugc_"):
				downloading_message_prompt.text = "Downloading song media..."
				downloading_message_prompt.popup_centered()
			else:
				song_confirmation_error_prompt.text = "ERROR STARTING GAME: You don't seem to have the video/audio for the song currently selected, please return to the free play song list and download it."
				song_confirmation_error_prompt.popup_centered()
func _on_InviteFriendButton_pressed():
	lobby.invite_friend_to_lobby()

func _options_vertical_menu_from_bottom():
	chat_line_edit.grab_focus()

func _on_SelectSongButton_pressed():
	change_to_menu("song_list_lobby", false, {"lobby": lobby, "song": lobby.get_song_id(), "song_difficulty": lobby.get_song_difficulty()})

func _on_LineEdit_gui_input(event: InputEvent):
	if event.is_action_pressed("gui_up") and not event.is_echo():
		get_viewport().set_input_as_handled()
		options_vertical_menu.grab_focus()
		options_vertical_menu.select_button(options_vertical_menu.get_child_count()-1)
	if event.is_action_pressed("gui_accept") and not event.is_echo():
		send_chat_message()
	if event is InputEventKey:
		get_viewport().set_input_as_handled()

func start_multiplayer_session_authority():
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(rhythm_game_multiplayer_scene)
	get_tree().current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = lobby
	rhythm_game_multiplayer_scene.start_game()
	lobby.game_results = {}

func _on_StartGameButton_pressed():
	lobby.check_if_lobby_members_have_song()
	song_availabilities = {lobby.get_lobby_owner(): selected_song.is_cached()}
	if not selected_song.is_cached():
		selected_song.cache_data()
	checking_song_availabilities = true
	waiting_for_song_confirmation_prompt.popup_centered()
	
# called when authority sends a game start packet, sets up mp and starts loading
func _on_lobby_loading_start():
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(rhythm_game_multiplayer_scene)
	get_tree().current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = lobby
	rhythm_game_multiplayer_scene.start_loading()
	lobby.game_results = {}
