extends HBMenu

class_name LobbyMenu

signal ugc_song_selected(ugc_id: int)
signal song_selected(song: HBSong)

@onready var member_list: LobbyMemberList = get_node("%MemberList")

@onready var lobby_debug_window: Window = get_node("%LobbyMenuDebugWindow")
@onready var lobby_menu_debug: LobbyMenuDebug = get_node("%LobbyMenuDebug")
@onready var lobby_main_menu: HBSimpleMenu = get_node("%LobbyMainMenu")
@onready var lobby_chat: LobbyChat = get_node("%LobbyChat")
@onready var lobby_name_label: Label = get_node("%LobbyNameLabel")
@onready var send_ugc_download_request_dialog: HBConfirmationWindow = get_node("%SendUGCDownloadSongRequestDialog")
@onready var download_ugc_song_dialog: HBConfirmationWindow = get_node("%DownloadUGCSongDialog")
@onready var error_message_window: HBConfirmationWindow = get_node("%ErrorMessage")

var lobby: HeartbeatSteamLobby

enum LobbyMenuAction {
	CHANGE_SONG,
	LOBBY_MENU_ACTION_MAX,
}

func _show_error(error: String):
	error_message_window.text = error
	error_message_window.popup_centered()

func _on_lobby_data_updated(data: HeartbeatSteamLobbyData):
	if data.song_id in SongLoader.songs:
		song_selected.emit(SongLoader.songs[data.song_id])
	elif data.is_song_from_ugc:
		ugc_song_selected.emit(data.song_ugc_id)
	
	lobby_name_label.text = data.lobby_name
	
	member_list.lobby_owner = lobby.steam_lobby.owner
	member_list.is_owned_by_local_user = lobby.steam_lobby.is_owned_by_local_user()
	
func _on_lobby_song_download_data_request_received():
	var availability_status := lobby.get_song_availability_status(lobby.lobby_data.is_song_from_ugc, lobby.lobby_data.song_id, lobby.lobby_data.song_variant)
	match availability_status:
		HeartbeatSteamLobby.SongAvailabilityStatus.HAS_DATA:
			return
		HeartbeatSteamLobby.SongAvailabilityStatus.NEEDS_UGC_SONG_DOWNLOAD, HeartbeatSteamLobby.SongAvailabilityStatus.NEEDS_UGC_MEDIA_DOWNLOAD:
			# Prompt user for download
			download_ugc_song_dialog.popup_centered()
		HeartbeatSteamLobby.SongAvailabilityStatus.MISSING_SONG:
			_show_error(tr("Looks like you are currently missing the non-workshop song used in this lobby!", &"Used in the lobby when a non-Workshop song is missing"))
		HeartbeatSteamLobby.SongAvailabilityStatus.MISSING_SONG_MEDIA:
			_show_error(tr("You have the non-workshop song used in this lobby, but you haven't downloaded the media for it!", &"Used in the lobby when a non-Workshop song's media is missing"))

func _attempt_start():
	var start_data := lobby.check_game_can_be_started()
	var st := start_data.status
	match st:
		HeartbeatSteamLobby.GameStartResponseStatus.OK:
			lobby.send_begin_game_load_request()
		HeartbeatSteamLobby.GameStartResponseStatus.USER_LACKS_MEDIA:
			send_ugc_download_request_dialog.popup_centered()
		HeartbeatSteamLobby.GameStartResponseStatus.SONG_AVAILABILITY_METADATA_DIRTY:
			# Do nothing
			pass

func _on_kicked_from_lobby():
	disconnect_lobby()
	change_to_menu("lobby_list", false, {"kicked": true})

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_F10 and event.is_pressed() and not event.is_echo():
			lobby_menu_debug.lobby = lobby
			lobby_debug_window.popup_centered()

func setup_lobby():
	member_list.clear()
	lobby.member_joined.connect(member_list.add_member)
	lobby.member_joined.connect(lobby_chat.notify_member_joined)
	lobby.member_left.connect(lobby_chat.notify_member_left)
	lobby.member_left.connect(member_list.remove_member)
	lobby.chat_message_received.connect(lobby_chat.add_chat_line)
	lobby.lobby_data_updated.connect(self._on_lobby_data_updated)
	lobby.download_song_media_request_received.connect(self._on_lobby_song_download_data_request_received)
	lobby.begin_loading_game_request_received.connect(self._begin_loading_game)
	lobby.kicked.connect(self._on_kicked_from_lobby)
	member_list.lobby_owner_change_pressed.connect(lobby.steam_lobby.set_lobby_owner)
	member_list.kick_member_pressed.connect(lobby.kick_member)
	send_ugc_download_request_dialog.accept.connect(lobby.send_download_song_data_request)
	_on_lobby_data_updated(lobby.lobby_data)
	
	for member in lobby.get_all_members_metadata():
		member_list.add_member(member)

func disconnect_lobby():
	if lobby:
		lobby.member_joined.disconnect(member_list.add_member)
		lobby.member_joined.disconnect(lobby_chat.notify_member_joined)
		lobby.member_left.disconnect(lobby_chat.notify_member_left)
		lobby.member_left.disconnect(member_list.remove_member) 
		lobby.chat_message_received.disconnect(lobby_chat.add_chat_line)
		lobby.lobby_data_updated.disconnect(self._on_lobby_data_updated)
		lobby.download_song_media_request_received.disconnect(self._on_lobby_song_download_data_request_received)
		lobby.begin_loading_game_request_received.disconnect(self._begin_loading_game)
		lobby.kicked.disconnect(self._on_kicked_from_lobby)
		member_list.lobby_owner_change_pressed.disconnect(lobby.steam_lobby.set_lobby_owner)
		member_list.kick_member_pressed.disconnect(lobby.kick_member)
		send_ugc_download_request_dialog.accept.disconnect(lobby.send_download_song_data_request)

func _ready() -> void:
	super._ready()
	lobby_chat.chat_message_submitted.connect(self._on_lobby_chat_message_submitted)
	download_ugc_song_dialog.accept.connect(self._on_ugc_song_download_data_request_accepted)
	
func _cache_ugc_song_data(song_id: String, variant: int):
	var song: HBSong = SongLoader.songs[lobby.lobby_data.song_id] if lobby.lobby_data.song_id in SongLoader.songs else null
	if song:
		var entry := song.cache_data(variant) as YoutubeDL.CachingQueueEntry
		if not entry:
			return
		var entry_res := await entry.download_finished as Array
		if entry_res[0] != OK and entry.song.id != lobby.lobby_data.song_id or entry.variant != variant:
			# Must have failed or we changed song while we downloaded meta...
			# do nothing?
			return
		lobby._update_song_availability_information()
	else:
		_show_error(tr("Something went terribly wrong: Song missing after download?", &"Lobby error message"))

func _on_ugc_song_download_data_request_accepted():
	var availability_status := lobby.get_song_availability_status(lobby.lobby_data.is_song_from_ugc, lobby.lobby_data.song_id, lobby.lobby_data.song_variant)
	if not lobby.lobby_data.is_song_from_ugc:
		pass
	var song_id := lobby.lobby_data.song_id
	var song_ugc_id := lobby.lobby_data.song_ugc_id
	var song_variant := lobby.lobby_data.song_variant
	match availability_status:
		HeartbeatSteamLobby.SongAvailabilityStatus.NEEDS_UGC_SONG_DOWNLOAD:
			var item := HBSteamUGCItem.from_id(lobby.lobby_data.song_ugc_id)
			if not item.item_state & SteamworksConstants.ITEM_STATE_INSTALLED or \
					item.item_state & SteamworksConstants.ITEM_STATE_NEEDS_UPDATE:
				if item.download(true):
					var result := await item.item_installed as int
					if result == OK:
						_cache_ugc_song_data(song_id, lobby.lobby_data.song_variant)
					else:
						_show_error(
							tr("Something went wrong with the song installation: download failed (Error: {error_code})", &"Lobby song download error") \
								.format({"error_code": result})
						)
						pass
				else:
					_show_error(tr("Something went wrong with the song installation: download failed to start", &"Lobby song download start error"))
					pass
		HeartbeatSteamLobby.SongAvailabilityStatus.NEEDS_UGC_MEDIA_DOWNLOAD:
			_cache_ugc_song_data(song_id, lobby.lobby_data.song_variant)

func _on_lobby_chat_message_submitted(message: String):
	if lobby.send_chat_text_message(message):
		lobby_chat.clear_chat_line()

func _on_song_select_button_pressed():
	if lobby.lobby_data.song_id.is_empty():
		change_to_menu("song_list_lobby", false, {"lobby": lobby, "song": lobby.lobby_data.song_id, "song_difficulty": lobby.lobby_data.difficulty})
	else:
		change_to_menu("song_list_lobby")

func _begin_loading_game():
	return
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(rhythm_game_multiplayer_scene)
	get_tree().current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = lobby
	rhythm_game_multiplayer_scene.start_game()

func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	
	lobby_debug_window.hide()
	
	if args.has("action"):
		var action := args.get("action", LobbyMenuAction.LOBBY_MENU_ACTION_MAX) as int
		assert(action < LobbyMenuAction.LOBBY_MENU_ACTION_MAX)
		match action:
			LobbyMenuAction.CHANGE_SONG:
				var song := args.get("song", null) as HBSong
				var difficulty := args.get("difficulty", "") as String
				assert(song)
				assert(not difficulty.is_empty())
				lobby.update_lobby_song_data(song, -1, difficulty)
				lobby.send_lobby_data_update()
	
	if args.has("lobby"):
		disconnect_lobby()
		lobby = args.lobby
		setup_lobby()
	assert(lobby)
	lobby_main_menu.grab_focus()

func _leave_lobby():
	disconnect_lobby()
	lobby.steam_lobby.leave_lobby()
	lobby = null
	change_to_menu("lobby_list")

func _on_invite_friend_button_pressed() -> void:
	Steamworks.friends.activate_game_overlay_invite_dialog(lobby.steam_lobby)
