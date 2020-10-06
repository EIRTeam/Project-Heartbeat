extends HBMenu

onready var chat_box = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Chat/MarginContainer/RichTextLabel")
onready var member_list = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MemberList")
onready var lobby_name_label = get_node("MarginContainer/VBoxContainer/Label")
onready var chat_line_edit = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LineEdit")
onready var options_vertical_menu = get_node ("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/Panel/MarginContainer/VBoxContainer")
onready var waiting_for_song_confirmation_prompt = get_node("WaitingForSongConfirmation")
onready var song_confirmation_error_prompt = get_node("SongConfirmationError")

var lobby: HBLobby
var selected_song: HBSong
var selected_difficulty: String

signal song_selected(song)

var song_availabilities = {}
var checking_song_availabilities = false

func _ready():
	var starting_song = SongLoader.songs.values()[0]
	select_song(starting_song, starting_song.charts.keys()[0])
	options_vertical_menu.connect("bottom", self, "_options_vertical_menu_from_bottom")
	waiting_for_song_confirmation_prompt.connect("cancel", self, "_on_song_availability_check_cancelled")
	waiting_for_song_confirmation_prompt.connect("cancel", options_vertical_menu, "grab_focus")
	song_confirmation_error_prompt.connect("accept", options_vertical_menu, "grab_focus")
func select_song(song: HBSong, difficulty: String):
	selected_song = song
	selected_difficulty = difficulty
	emit_signal("song_selected", selected_song)
func _on_menu_enter(force_hard_transition=false, args={}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("lobby"):
		set_lobby(args.lobby)
	_check_ownership_changed()
	chat_line_edit.clear()
	chat_box.clear()
	# Sets the song wen returning from lobby song select, or not if we are just joining
	if args.has("song"):
		var song = args.song as HBSong
		lobby.song_name = song.get_visible_title()
		lobby.song_id = song.id
		lobby.song_difficulty = args.difficulty
		lobby.send_game_info_update()
	else:
		select_song(lobby.get_song(), lobby.song_difficulty)
	# HACK! Else we select the wrong button when we don't do this
	yield(get_tree(), "idle_frame")
	options_vertical_menu.grab_focus()

func _check_ownership_changed():
	if lobby.is_owned_by_local_user():
		get_tree().call_group("owner_only", "show")
	else:
		get_tree().call_group("owner_only", "hide")

func _on_song_availability_check_cancelled():
	checking_song_availabilities = false

func update_member_list():
	member_list.clear_members()
	for member in lobby.members.values():
		var is_owner = false
		if lobby.get_lobby_owner() == member:
			is_owner = true
		member_list.add_member(member, is_owner)

func update_lobby_data_display():
	lobby_name_label.text = lobby.lobby_name
	select_song(lobby.get_song(), lobby.song_difficulty)
func set_lobby(lobby: HBLobby):
	self.lobby = lobby
	lobby.connect("lobby_chat_message", self, "_on_chat_message_received")
	lobby.connect("lobby_chat_update", self, "_on_lobby_chat_update")
	lobby.connect("lobby_data_updated", self, "update_lobby_data_display")
	lobby.connect("lobby_loading_start", self, "_on_lobby_loading_start")
	lobby.connect("user_song_availability_update", self, "_on_user_song_availability_update")

	update_member_list()
	update_lobby_data_display()
#	if not lobby is SteamLobby:
#		get_tree().call_group("steam_only", "hide")
func _on_chat_message_received(member: HBServiceMember, message, type):
	match type:
		HBLobby.CHAT_MESSAGE_TYPE.MESSAGE:
			chat_box.bbcode_text += "\n" + member.get_member_name() + ": " + str(message)

func append_service_message(message: String):
	chat_box.bbcode_text += "\n[color=#FF0000]" + message + "[/color]"

func _on_lobby_chat_update(changed: HBServiceMember, making_change: HBServiceMember, state):
	var msg
	if state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.JOINED:
		msg = " has joined."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.LEFT:
		msg = " has left."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.DISCONNECTED:
		msg = " has disconnected."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.KICKED:
		msg = " has been kicked."
	elif state == HBLobby.LOBBY_CHAT_UPDATE_STATUS.BANNED:
		msg = " has been banned."
	else:
		msg = " has managed to break space-time."
	
	msg = str(changed.member_name) + msg
	append_service_message(msg)
	update_member_list()
	_check_ownership_changed()
	
func send_chat_message():
	var text = chat_line_edit.text.strip_edges()
	if text != "" and not text.begins_with("/"):
		lobby.send_chat_message(text)
	chat_line_edit.text = ""

func _on_LeaveLobbyButton_pressed():
	lobby.disconnect("lobby_chat_message", self, "_on_chat_message_received")
	lobby.disconnect("lobby_chat_update", self, "_on_lobby_chat_update")
	lobby.disconnect("lobby_data_updated", self, "update_lobby_data_display")
	lobby.disconnect("lobby_loading_start", self, "_on_lobby_loading_start")
	lobby.disconnect("user_song_availability_update", self, "_on_user_song_availability_update")
	lobby.leave_lobby()
	change_to_menu("lobby_list")

func _on_user_song_availability_update(sender_user: HBServiceMember, song_id, available: bool):
	if not checking_song_availabilities:
		return
	song_availabilities[sender_user] = available
	var not_owned_by_users = []
	if song_availabilities.size() >= lobby.get_lobby_member_count():
		for user in song_availabilities:
			var owned = song_availabilities[user]
			if not owned:
				not_owned_by_users.append(user)
	if not_owned_by_users.size() > 0:
		var struwu = ""
		for i in range(not_owned_by_users.size()):
			var user = not_owned_by_users[i]
			if i != 0:
				struwu += ","
			struwu += " %s" % user.get_member_name()
		waiting_for_song_confirmation_prompt.hide()
		
		song_confirmation_error_prompt.text = "ERROR: The following users don't have this song: %s" % [struwu]
		song_confirmation_error_prompt.popup_centered()
		checking_song_availabilities = false
	else:
		checking_song_availabilities = false
		start_multiplayer_session_authority()

func _on_InviteFriendButton_pressed():
	lobby.invite_friend_to_lobby()

func _options_vertical_menu_from_bottom():
	chat_line_edit.grab_focus()

func _on_SelectSongButton_pressed():
	change_to_menu("song_list_lobby", false, {"lobby": lobby, "song": lobby.get_song_id(), "song_difficulty": lobby.get_song_difficulty()})


func _on_LineEdit_gui_input(event: InputEvent):
	if event.is_action_pressed("gui_up") and not event.is_echo():
		get_tree().set_input_as_handled()
		options_vertical_menu.grab_focus()
		options_vertical_menu.select_button(options_vertical_menu.get_child_count()-1)
	if event.is_action_pressed("gui_accept") and not event.is_echo():
		send_chat_message()

func start_multiplayer_session_authority():
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(rhythm_game_multiplayer_scene)
	get_tree().current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = lobby
	rhythm_game_multiplayer_scene.start_game()

func _on_StartGameButton_pressed():
	lobby.check_if_lobby_members_have_song()
	song_availabilities = {lobby.get_lobby_owner(): true}
	checking_song_availabilities = true
	waiting_for_song_confirmation_prompt.popup_centered()

	

	
# called when authority sends a game start packet, sets up mp and starts loading
func _on_lobby_loading_start():
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(rhythm_game_multiplayer_scene)
	get_tree().current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = lobby
	rhythm_game_multiplayer_scene.start_loading()
