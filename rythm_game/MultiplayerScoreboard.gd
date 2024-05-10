extends Control

class_name MultiplayerScoreboard

const SCOREBOARD_ITEM_SCENE: PackedScene = preload("res://rythm_game/MultiplayerScoreboardItem.tscn")

func add_member(member: HeartbeatSteamLobby.MemberMetadata):
	var scene: MultiplayerScoreboardItem = SCOREBOARD_ITEM_SCENE.instantiate()
	add_child(scene)
	scene.member = member
	member.note_hit_received.connect(self._on_note_hit_received)
	
func _on_note_hit_received(_rating: HBJudge.JUDGE_RATINGS, _score: int):
	var member_items := get_children()
	member_items.sort_custom(self._sort_member_items)
	for i in get_children():
		remove_child(i)
	for i in member_items:
		add_child(i)

func _sort_member_items(a: MultiplayerScoreboardItem, b: MultiplayerScoreboardItem):
	return a.score > b.score

func remove_member(member: HeartbeatSteamLobby.MemberMetadata):
	for scene: MultiplayerScoreboardItem in get_children():
		if scene.member == member:
			remove_child(scene)
			return
