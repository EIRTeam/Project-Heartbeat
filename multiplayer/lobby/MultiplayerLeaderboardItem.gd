extends PanelContainer

class_name MultiplayerLeaderboardItem

@onready var ranking_label: Label = get_node("%RankingLabel")
@onready var avatar_texture_rect: TextureRect = get_node("%AvatarTextureRect")
@onready var name_label: Label = get_node("%NameLabel")
@onready var score_label: Label = get_node("%ScoreLabel")
@onready var percentage_label: Label = get_node("%PercentageLabel")


var update_queued := false

var member: HeartbeatSteamLobby.MemberMetadata:
	set(val):
		member = val
		member.result_received.connect(self._queue_update)
		_queue_update()

func _update():
	if update_queued:
		update_queued = false
		ranking_label.text = str(get_index() + 1)
		avatar_texture_rect.texture = member.member.avatar
		name_label.text = member.member.persona_name
		if member.result:
			score_label.text = str(member.result.score)
			percentage_label.text = "%.2f%%" % [member.result.get_percentage() * 100.0]

func _queue_update():
	if not update_queued:
		update_queued = true
		if not is_node_ready():
			await ready
		_update.call_deferred()
