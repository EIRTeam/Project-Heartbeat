extends PanelContainer

class_name MultiplayerScoreboardItem

@onready var member_name_label: Label = get_node("%MemberNameLabel")
@onready var avatar_texture_rect: TextureRect = get_node("%AvatarTextureRect")
@onready var rating_label: Label = get_node("%RatingLabel")
@onready var score_counter: HBScoreCounter = get_node("%ScoreCounter")

var score := 0

var _update_queued := false

func _update():
	if _update_queued:
		_update_queued = false
		member_name_label.text = member.member.persona_name
		avatar_texture_rect.texture = member.member.avatar

func _queue_update():
	if not _update_queued:
		_update_queued = true
		if not is_node_ready():
			await ready
		_update.call_deferred()

var member: HeartbeatSteamLobby.MemberMetadata:
	set(val):
		if member:
			member.note_hit_received.disconnect(self._on_note_hit_received)
		member = val
		member.note_hit_received.connect(self._on_note_hit_received)
		_queue_update()

func _on_note_hit_received(rating: HBJudge.JUDGE_RATINGS, score: int):
	update_rating(rating)
	update_score(score)

func update_rating(rating: HBJudge.JUDGE_RATINGS):
	rating_label.add_theme_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[rating]))
	rating_label.add_theme_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[rating])
	rating_label.text = HBJudge.JUDGE_RATINGS.keys()[rating]

func update_score(new_score: int):
	score = new_score
	score_counter.score = score
