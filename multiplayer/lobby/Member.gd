extends MarginContainer

var member: HBServiceMember: set = set_member
var lobby: HBLobby
var is_owner: bool: set = set_is_owner
var owned_by_local_user: bool: set = set_local_user_is_owner

@onready var member_name_label = get_node("VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/Label")
@onready var avatar_texture_rect = get_node("VBoxContainer/HBoxContainer/TextureRect")
@onready var owner_crown = get_node("VBoxContainer/HBoxContainer/HBoxContainer/TextureRect")
@onready var set_as_host_button = get_node("VBoxContainer/HBoxContainer/HBoxContainer/HBoxContainer/SetAsHostButton")

func set_member(val: HBServiceMember):
	# FIXME: joining while selecting song is funky
	member = val
	member_name_label.text = member.member_name
	if not member.is_connected("persona_state_change", Callable(self, "_on_persona_state_changed")):
		member.connect("persona_state_change", Callable(self, "_on_persona_state_changed"))
	if not set_as_host_button.is_connected("pressed", Callable(lobby, "set_lobby_owner")):
		set_as_host_button.connect("pressed", Callable(lobby, "set_lobby_owner").bind(member.member_id))
	avatar_texture_rect.texture = member.avatar
	
func set_is_owner(val):
	is_owner = val
	owner_crown.visible = is_owner
func set_local_user_is_owner(val):
	owned_by_local_user = val
	set_as_host_button.visible = (not is_owner) and owned_by_local_user
	
	
func _ready():
	connect("resized", Callable(self, "_on_resized"))
	
func _on_persona_state_changed(flags):
	set_member(member)
	
func _on_resized():
	var new_size = clamp(size.y, 25, 50)
	avatar_texture_rect.custom_minimum_size = Vector2(new_size, new_size)
	avatar_texture_rect.size = Vector2(new_size, new_size)
