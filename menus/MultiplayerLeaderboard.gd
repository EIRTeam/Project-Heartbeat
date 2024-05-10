extends HBMenu

class_name MultiplayerLeaderboard

const MP_LEADERBOARD_ITEM: PackedScene = preload("res://multiplayer/lobby/MultiplayerLeaderboardItem.tscn")

@onready var entry_container: VBoxContainer = get_node("%EntryContainer")

var members: Array[MultiplayerLeaderboardItem]

var _update_queued := false
func _queue_update():
	if not _update_queued:
		_update_queued = true
		if not is_node_ready():
			await ready
		_update.call_deferred()

func _update():
	if _update_queued:
		_update_queued = false
		members.sort_custom(
			func(a: MultiplayerLeaderboardItem, b: MultiplayerLeaderboardItem):
				var score_a := a.member.result.score if a.member.result else 9999999999999999
				var score_b := b.member.result.score if b.member.result else 9999999999999999
				return score_a >= score_b
		)
		
		for scene in members:
			scene.visible = scene.member.result != null
			
func set_lobby(lobby: HeartbeatSteamLobby):
	for member in lobby.get_all_members_metadata():
		add_member(member)
			
func add_member(member: HeartbeatSteamLobby.MemberMetadata):
	var scene := MP_LEADERBOARD_ITEM.instantiate() as MultiplayerLeaderboardItem
	scene.member = member
	member.result_received.connect(self._queue_update)
	
	entry_container.add_child(scene)
	members.push_back(scene)
	_queue_update()
