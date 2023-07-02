extends VBoxContainer

const SCOREBOARD_ITEM_SCENE = preload("res://rythm_game/MultiplayerScoreboardItem.tscn")

var members = []: set = set_members
var member_item_map = {}

func set_members(val):
	members = val
	for member in members:
		var item_scene = SCOREBOARD_ITEM_SCENE.instantiate()
		add_child(item_scene)
		item_scene.member = member
		member_item_map[member.member_id] = item_scene

func set_last_note_hit_for_member(member, score, last_rating):
	var item = member_item_map[member.member_id]
	item.score = score
	item.last_rating = last_rating
	var member_items = member_item_map.values()
	member_items.sort_custom(Callable(self, "_sort_member_items"))
	for i in get_children():
		remove_child(i)
	for i in member_items:
		add_child(i)
func _sort_member_items(a, b):
	return a.score > b.score

func remove_member(member: HBServiceMember):
	print("REMOVING MEMBER ", member.get_member_name())
	if member.member_id in member_item_map:
		remove_child(member_item_map[member.member_id])
		member_item_map[member.member_id].queue_free()
		member_item_map.erase(member.member_id)
		members.erase(member.member_id)

