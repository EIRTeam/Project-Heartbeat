extends VBoxContainer

const SCOREBOARD_ITEM_SCENE = preload("res://rythm_game/MultiplayerScoreboardItem.tscn")

var members = [] setget set_members

var member_item_map = {}

func set_members(val):
	members = val
	for member in members:
		var item_scene = SCOREBOARD_ITEM_SCENE.instance()
		add_child(item_scene)
		item_scene.member = member
		member_item_map[member] = item_scene

func set_last_note_hit_for_member(member, score, last_rating):
	var item = member_item_map[member]
	item.score = score
	item.last_rating = last_rating

func remove_member(member: HBServiceMember):
	member_item_map[member].queue_free()
	member_item_map.erase(member)
	members.erase(member)
