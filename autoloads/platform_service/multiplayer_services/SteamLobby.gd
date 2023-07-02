extends HBLobby

class_name SteamLobby

const LOG_NAME = "SteamLobby"

func set_lobby_name(new_name):
	Steam.setLobbyData(_lobby_id, "name", new_name)
func set_song_name(val):
	Steam.setLobbyData(_lobby_id, "song_name_base_64", Marshalls.utf8_to_base64(val))
func set_song_id(val):
	game_info.song_id = val
	Steam.setLobbyData(_lobby_id, "song_id_base64", Marshalls.utf8_to_base64(val))
func set_song_difficulty(val):
	game_info.difficulty = val
	
func send_game_info_update():
	Steam.setLobbyData(_lobby_id, "game_info", JSON.stringify(game_info.serialize()))
	set_song_id(game_info.song_id)
	set_song_name(SongLoader.songs[game_info.song_id].title)
func get_lobby_name():
	return Steam.getLobbyData(_lobby_id, "name")
func get_lobby_member_count():
	return Steam.getNumLobbyMembers(_lobby_id)
func get_max_lobby_members():
	return Steam.getLobbyMemberLimit(_lobby_id)

func get_song_name():
	# By default we use the local name for a song... but if we do not have that
	# song we just use whatever the server gave us
	var song = get_song()
	if song:
		return song.get_visible_title()
	else:
		var song_name_b64 = Steam.getLobbyData(_lobby_id, "song_name_base_64")
		return Marshalls.base64_to_utf8(song_name_b64)

func get_song_id():
	return game_info.song_id

func get_song_difficulty():
	return game_info.difficulty

func _init(lobby_id):
	super(lobby_id)
	self._lobby_id = lobby_id
	connect("game_done", Callable(self, "_on_game_done"))
func join_lobby():
	Log.log(self, "Attempting to join lobby " + str(_lobby_id))
	Steam.joinLobby(_lobby_id)
	Steam.connect("lobby_joined", Callable(self, "_on_lobby_joined").bind(), CONNECT_ONE_SHOT)

func obtain_game_info():
	var gif = Steam.getLobbyData(_lobby_id, "game_info")
	var test_json_conv = JSON.new()
	var json_err := test_json_conv.parse(gif)
	var json = test_json_conv.get_data()
	if json_err == OK:
		game_info = HBGameInfo.deserialize(test_json_conv.data)
		game_info.song_id = Marshalls.base64_to_utf8(Steam.getLobbyData(_lobby_id, "song_id_base64"))
	else:
		Log.log(self, "Error obtaining game_info from lobby %d error on line %d: %s" % [_lobby_id, test_json_conv.get_error_line(), test_json_conv.get_error_message()])

func update_lobby_members():
	members.clear()
	
	var member_n = get_lobby_member_count()
	
	for member_i in range(0, member_n):
		var member_id = Steam.getLobbyMemberByIndex(_lobby_id, member_i)
		var member = SteamServiceMember.new(member_id)
		members[member_id] = member
func _on_lobby_joined(lobby_id, permissions, locked, response):
	
	Log.log(self, "Attempted to join lobby " + str(_lobby_id))
	
	if lobby_id == _lobby_id:
		if response == LOBBY_ENTER_RESPONSE.SUCCESS:
			connected = true
			Steam.connect("lobby_message", Callable(self, "_on_lobby_message"))
			Steam.connect("lobby_chat_update", Callable(self, "_on_lobby_chat_update"))
			Steam.connect("lobby_data_update", Callable(self, "_on_lobby_data_updated"))
			Steam.connect("p2p_session_request", Callable(self, "_on_p2p_session_request"))
			Steam.connect("p2p_session_connect_fail", Callable(self, "_on_p2p_session_connect_fail"))
			PlatformService.service_provider.ugc_provider.connect("ugc_item_installed", Callable(self, "_on_ugc_item_downloaded"))
			YoutubeDL.connect("song_cached", Callable(self, "_on_song_cached"))
			PlatformService.service_provider.connect("run_mp_callbacks", Callable(self, "_on_p2p_packet_received"))
			update_lobby_members()
			if not is_owned_by_local_user():
				obtain_game_info()
		emit_signal("lobby_joined", response)
		
func _on_ugc_item_downloaded(_item_type, item):
	if item is HBSong and item.id == get_song_id():
		if not is_owned_by_local_user():
			if UserSettings.user_settings.workshop_download_audio_only:
				if not UserSettings.user_settings.per_song_settings.has(item.id):
					UserSettings.user_settings.per_song_settings[item.id] = HBPerSongSettings.new()
				UserSettings.user_settings.per_song_settings[item.id].video_enabled = false
				UserSettings.save_user_settings()
		if not YoutubeDL.is_already_downloading(item) and not item.is_cached():
			item.cache_data()
		elif not YoutubeDL.is_already_downloading(item):
			report_ugc_downloaded(item.ugc_id)
func report_ugc_downloaded(ugc_id: int):
	if is_owned_by_local_user():
		emit_signal("reported_ugc_song_downloaded", get_lobby_owner(), ugc_id)
	else:
		send_chat_message("/report_ugc_downloaded %d" % [ugc_id])
	
func execute_command_message(user: HBServiceMember, message: String):
	var command = message.substr(1, -1).split(" ")[0]
	if is_owned_by_local_user():
		if command == "song_available_update":
			var test_json_conv = JSON.new()
			var json_er := test_json_conv.parse(message.split(" ", true, 1)[1])
			var data = test_json_conv.get_data()
			var song_id = Marshalls.base64_to_utf8(data.song_id)
			var song_available = data.available

			if song_id == get_song_id():
				emit_signal("user_song_availability_update", user, song_id, song_available)
		elif command == "report_ugc_downloaded":
			var ugc_id = message.split(" ", true, 1)[1]
			emit_signal("reported_ugc_song_downloaded", user, int(ugc_id))
	elif user == get_lobby_owner():
		if command == "check_songs_request":
			var song_id_b64 = message.split(" ", true, 1)[1]
			var song_id = Marshalls.base64_to_utf8(song_id_b64)
			emit_signal("check_songs_request_received", song_id)
			var dict = {
				"song_id": song_id_b64,
				"available": false
			}
			if song_id in SongLoader.songs:
				var song = SongLoader.songs[song_id] as HBSong
				if song.is_cached():
					dict.available = true
			send_chat_message("/song_available_update %s" % [JSON.stringify(dict)])
	
	if command == "update_lobby_host":
		emit_signal("host_changed")

func check_if_lobby_members_have_song():
	if is_owned_by_local_user():
		send_chat_message("/check_songs_request %s" % [Marshalls.utf8_to_base64(get_song_id())])

func _on_lobby_message(result, user, message: String, type):
	var found_member = get_member_by_id(user)
	if found_member:
		if type == CHAT_MESSAGE_TYPE.MESSAGE:
			if message.begins_with("/"):
				# Command message
				execute_command_message(found_member, message)
				return
		emit_signal("lobby_chat_message", found_member, message, type)
		
func get_member_by_id(id) -> HBServiceMember:
	if members.has(id):
		return members[id]
	return null

func get_lobby_owner() -> HBServiceMember:
	return members[Steam.getLobbyOwner(_lobby_id)]
func set_lobby_owner(val):
	Steam.setLobbyOwner(_lobby_id, val)
	send_chat_message("/update_lobby_host")

func _on_lobby_data_updated(success, lobby_id, id):
	if lobby_id == _lobby_id:
		if id == lobby_id:
			obtain_game_info()
			emit_signal("lobby_data_updated")
		else:
			var found_member = get_member_by_id(id)
			if found_member:
				if success:
					emit_signal("lobby_user_data_updated", found_member)

func send_chat_message(message: String):
	Steam.sendLobbyChatMsg(_lobby_id, message)

func _on_lobby_created(result, lobby_id):
	if _lobby_id == null:
		_lobby_id = lobby_id
	if result == LOBBY_CREATION_RESULT.OK:
		set_lobby_name(Steam.getPersonaName() + "'s Lobby")
		var song = SongLoader.songs.values()[0] as HBSong
		set_song_difficulty(song.charts.keys()[0])
		set_song_id(song.id)
		set_song_name(song.title)
		send_game_info_update()
	else:
		Log.log(self, "Got error %d when attempting to connect to the lobby" %  [result])
	emit_signal("lobby_created", result)

func _on_lobby_chat_update(lobby_id, changed_id, making_change_id, chat_state):
	var making_change
	var changed
	if members.has(making_change_id):
		making_change = members[making_change_id]
	if members.has(changed_id):
		changed = members[changed_id]
	update_lobby_members()
	if members.has(making_change_id):
		making_change = members[making_change_id]
	if members.has(changed_id):
		changed = members[changed_id]
		
	if chat_state == LOBBY_CHAT_UPDATE_STATUS.LEFT or chat_state == LOBBY_CHAT_UPDATE_STATUS.DISCONNECTED:
		if changed_id == making_change_id:
			emit_signal("member_left", changed)
			members.erase(changed)
		
	emit_signal("lobby_chat_update", changed, making_change, chat_state)
func create_lobby():
	Log.log(self, "Attempting to create lobby")
	Steam.connect("lobby_created", Callable(self, "_on_lobby_created").bind(), CONNECT_ONE_SHOT)
	Steam.connect("lobby_joined", Callable(self, "_on_lobby_joined").bind(), CONNECT_ONE_SHOT)
	var lobby_type: int = HBLobby.LOBBY_TYPE.PUBLIC
	Steam.createLobby(lobby_type, 5)

func leave_lobby():
	Log.log(self, "Leaving lobby")
	Steam.leaveLobby(_lobby_id)
	Steam.disconnect("lobby_message", Callable(self, "_on_lobby_message"))
	Steam.disconnect("lobby_chat_update", Callable(self, "_on_lobby_chat_update"))
	Steam.disconnect("lobby_data_update", Callable(self, "_on_lobby_data_updated"))
	Steam.disconnect("p2p_session_request", Callable(self, "_on_p2p_session_request"))
	Steam.disconnect("p2p_session_connect_fail", Callable(self, "_on_p2p_session_connect_fail"))
	PlatformService.service_provider.ugc_provider.disconnect("ugc_item_downloaded", Callable(self, "_on_ugc_item_downloaded"))
	YoutubeDL.disconnect("song_cached", Callable(self, "_on_song_cached"))
	PlatformService.service_provider.disconnect("run_mp_callbacks", Callable(self, "_on_p2p_packet_received"))
	emit_signal("lobby_left")

func is_owned_by_local_user():
	var owner = get_lobby_owner() as HBServiceMember
	return owner.member_id == Steam.getSteamID()

func _on_song_cached(song: HBSong):
	if song.ugc_id == get_song().ugc_id:
		report_ugc_downloaded(song.ugc_id)
func invite_friend_to_lobby():
	Steam.activateGameOverlayInviteDialog(_lobby_id)

# P2P specific shit

func send_packet(data, send_type, channel, to_owner = false):
#	Log.log(self, "Sending packet " + HBUtils.find_key(PACKET_TYPE, data[0]))
	if to_owner:
		Steam.sendP2PPacket(get_lobby_owner().member_id, data, send_type, channel)
	elif get_lobby_member_count() > 1:
		for member in members.values():
			if member.member_id != Steam.getSteamID():
				Steam.sendP2PPacket(member.member_id, data, send_type, channel)

func start_session():
	if is_owned_by_local_user():
		var data = PackedByteArray()
		Steam.setLobbyJoinable(_lobby_id, false)
		data.append(PACKET_TYPE.HANDSHAKE)
		send_packet(data, PACKET_SEND_TYPE.RELIABLE, 0)
	else:
		Log.log(self, "Tried to launch a P2P session while we don't own the lobby", Log.LogLevel.ERROR)

func _on_p2p_packet_received():
	# P2P packets are comprised of a packet type code and followed by byte data
	# as a Dictionary using var2byes
	var size = Steam.getAvailableP2PPacketSize(0)
	if size > 0:
		var packet = Steam.readP2PPacket(size, 0)
		if packet.is_empty():
			Log.log(self, "Empty P2P packet received with non-zero size")
		var packet_type = packet.data[0]
		var packet_data: Dictionary
		#Log.log(self, get_lobby_name() + " Received P2P packet of type " + HBUtils.find_key(PACKET_TYPE, packet_type))
		if size > 1:
			packet_data = bytes_to_var(packet.data.subarray(1, size - 1))
		if is_owned_by_local_user():
			match packet_type:
				PACKET_TYPE.LOADED:
					emit_signal("game_member_loading_finished", get_member_by_id(packet.steam_id_remote))
		match packet_type:
			PACKET_TYPE.HANDSHAKE:
				emit_signal("lobby_loading_start")
			PACKET_TYPE.NOTE_HIT:
				emit_signal("game_note_hit", get_member_by_id(packet.steam_id_remote), packet_data.score, packet_data.rating)
			PACKET_TYPE.START_GAME:
				obtain_game_info() # We should already have the latest but just to be sure...
				emit_signal("game_start", game_info)
			PACKET_TYPE.GAME_DONE:
				var member = get_member_by_id(packet.steam_id_remote)
				game_results[member] = HBResult.deserialize(packet_data)
				for _member in game_results:
					if not _member.member_id in members:
						print("DELETING USER: ", _member.get_member_name())
						game_results.erase(_member)
				if game_results.size() == members.size():
					emit_signal("game_done", game_results, game_info)
func _on_p2p_session_request(remote_id):
	var found_member = false
	if members.has(remote_id):
		found_member = true
	if found_member:
		var mem = members[remote_id] as HBServiceMember
		Log.log(self, "Accepting p2p session with " + mem.get_member_name())
		Steam.acceptP2PSessionWithUser(remote_id)
	else:
		Log.log(self, "User " + str(remote_id) + " is not in our lobby but tried to send us a P2P packet" + str(_lobby_id))
	_on_p2p_packet_received()
func notify_game_loaded():
	var data = PackedByteArray()
	data.append(PACKET_TYPE.LOADED)
	send_packet(data, PACKET_SEND_TYPE.RELIABLE, 0)

func start_game():
	var data = PackedByteArray()
	data.append(PACKET_TYPE.START_GAME)
	send_packet(data, PACKET_SEND_TYPE.RELIABLE, 0)
# Lets everyone else know that our score (and last rating) has changed
func send_note_hit_update(score, rating):
	var data = PackedByteArray()
	data.append(PACKET_TYPE.NOTE_HIT)
	data.append_array(var_to_bytes({
		"score": score,
		"rating": rating
	}))
	send_packet(data, PACKET_SEND_TYPE.UNREALIABLE, 0)

func _on_p2p_session_connect_fail(lobby_id, session_error):
	if session_error == 0:
		Log.log(self, "Session failure with "+str(lobby_id)+" [no error given].")
	elif session_error == 1:
		Log.log(self, "Session failure with "+str(lobby_id)+" [target user not running the same game].")
	elif session_error == 2:
		Log.log(self, "Session failure with "+str(lobby_id)+" [local user doesn't own game].")
	elif session_error == 3:
		Log.log(self, "Session failure with "+str(lobby_id)+" [target user isn't connected to Steam].")
	elif session_error == 4:
		Log.log(self, "Session failure with "+str(lobby_id)+" [connection timed out].")
	elif session_error == 5:
		Log.log(self, "Session failure with "+str(lobby_id)+" [unused].")
	else:
		Log.log(self, "Session failure with "+str(lobby_id)+" [unknown error "+str(session_error)+"].")

func notify_game_finished(result: HBResult):
	var data = PackedByteArray()
	data.append(PACKET_TYPE.GAME_DONE)
	data.append_array(var_to_bytes(result.serialize()))
	send_packet(data, PACKET_SEND_TYPE.RELIABLE, 0)
	game_results[get_member_by_id(Steam.getSteamID())] = result
	game_info.result = result
	for member in game_results:
		if not member.member_id in members:
			game_results.erase(member)
	if game_results.size() == members.size():
		emit_signal("game_done", game_results, game_info)

func _on_game_done(result, game_info):
	Steam.setLobbyJoinable(_lobby_id, true)
