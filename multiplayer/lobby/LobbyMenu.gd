extends HBMenu

onready var chat_box = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Chat/MarginContainer/RichTextLabel")
onready var member_list = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/MemberList")
onready var lobby_name_label = get_node("MarginContainer/VBoxContainer/Label")
onready var chat_line_edit = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LineEdit")
onready var options_vertical_menu = get_node ("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/Panel/MarginContainer/VBoxContainer")


var lobby: HBLobby
var selected_song: HBSong
var selected_difficulty: String

signal song_selected(song)

func _ready():
	var starting_song = SongLoader.songs.values()[0]
	select_song(starting_song, starting_song.charts.keys()[0])
	options_vertical_menu.connect("bottom", self, "_options_vertical_menu_from_bottom")
func select_song(song: HBSong, difficulty: String):
	selected_song = song
	selected_difficulty = difficulty
	emit_signal("song_selected", selected_song)
func _on_menu_enter(force_hard_transition=false, args={}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("lobby"):
		set_lobby(args.lobby)
	options_vertical_menu.grab_focus()
	_check_ownership_changed()
	chat_line_edit.clear()
	chat_box.clear()
	if args.has("song"):
		var song = args.song as HBSong
		lobby.song_name = song.get_visible_title()
		lobby.song_id = song.id
		lobby.song_difficulty = args.difficulty
	else:
		select_song(lobby.get_song(), lobby.song_difficulty)
func _check_ownership_changed():
	if lobby.is_owned_by_local_user():
		get_tree().call_group("owner_only", "show")
	else:
		get_tree().call_group("owner_only", "hide")

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
	update_member_list()
	update_lobby_data_display()
	if not lobby is SteamLobby:
		get_tree().call_group("steam_only", "hide")
func _on_chat_message_received(member: HBServiceMember, message, type):
	match type:
		HBLobby.CHAT_MESSAGE_TYPE.MESSAGE:
			print("MESSAGE FROM: " + member.get_member_name())
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
	
	msg = str(making_change.member_name) + msg
	append_service_message(msg)
	update_member_list()
	_check_ownership_changed()
	
func send_chat_message():
	var text = chat_line_edit.text.strip_edges()
	if text != "":
		lobby.send_chat_message(text)
	chat_line_edit.text = ""

func _on_LeaveLobbyButton_pressed():
	lobby.disconnect("lobby_chat_message", self, "_on_chat_message_received")
	lobby.disconnect("lobby_chat_update", self, "_on_lobby_chat_update")
	lobby.disconnect("lobby_data_updated", self, "update_lobby_data_display")
	lobby.leave_lobby()
	change_to_menu("lobby_list")

func _on_InviteFriendButton_pressed():
	lobby.invite_friend_to_lobby()

func _options_vertical_menu_from_bottom():
	chat_line_edit.grab_focus()

func _on_SelectSongButton_pressed():
	change_to_menu("song_list_lobby", false, {"lobby": lobby})


func _on_LineEdit_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_up") and not event.is_echo():
		get_tree().set_input_as_handled()
		options_vertical_menu.grab_focus()
		options_vertical_menu.select_button(options_vertical_menu.get_child_count()-1)
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		send_chat_message()
		
