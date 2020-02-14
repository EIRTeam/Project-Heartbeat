extends HBLobby

class_name SteamLobby

const LOG_NAME = "SteamLobby"

func set_lobby_name(new_name):
	Steam.setLobbyData(_lobby_id, "name", new_name)
func set_song_name(val):
	Steam.setLobbyData(_lobby_id, "song_name", val)
func set_song_id(val):
	Steam.setLobbyData(_lobby_id, "song_id", val)
func set_song_difficulty(val):
	Steam.setLobbyData(_lobby_id, "song_difficulty", val)
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
		return Steam.getLobbyData(_lobby_id, "song_name")

func get_song_id():
	return Steam.getLobbyData(_lobby_id, "song_id")

func get_song_difficulty():
	return Steam.getLobbyData(_lobby_id, "song_difficulty")

func _init(lobby_id).(lobby_id):
	self._lobby_id = lobby_id

func join_lobby():
	Log.log(self, "Attempting to join lobby " + str(_lobby_id))
	Steam.joinLobby(_lobby_id)
	Steam.connect("lobby_joined", self, "_on_lobby_joined", [], CONNECT_ONESHOT)
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
		connected = true
		Steam.connect("lobby_message", self, "_on_lobby_message")
		Steam.connect("lobby_chat_update", self, "_on_lobby_chat_update")
		Steam.connect("lobby_data_update", self, "_on_lobby_data_updated")
		update_lobby_members()
		emit_signal("lobby_joined", response)
		
func _on_lobby_message(result, user, message, type):
	var found_member = get_member_by_id(user)
	if found_member:
		emit_signal("lobby_chat_message", found_member, message, type)
		
func get_member_by_id(id):
	if members.has(id):
		return members[id]
	return null

func get_lobby_owner():
	return members[Steam.getLobbyOwner(_lobby_id)]

func _on_lobby_data_updated(success, lobby_id, id, key):
	if lobby_id == _lobby_id:
		if id == lobby_id:
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
	emit_signal("lobby_chat_update", changed, making_change, chat_state)
func create_lobby():
	Log.log(self, "Attempting to create lobby")
	Steam.connect("lobby_created", self, "_on_lobby_created", [], CONNECT_ONESHOT)
	Steam.connect("lobby_joined", self, "_on_lobby_joined", [], CONNECT_ONESHOT)
	Steam.createLobby(HBLobby.LOBBY_TYPE.PUBLIC, 5)

func leave_lobby():
	Log.log(self, "Leaving lobby")
	Steam.leaveLobby(_lobby_id)
	emit_signal("lobby_left")

func is_owned_by_local_user():
	var owner = get_lobby_owner() as HBServiceMember
	return owner.member_id == Steam.getSteamID()

func invite_friend_to_lobby():
	Steam.activateGameOverlayInviteDialog(_lobby_id)
