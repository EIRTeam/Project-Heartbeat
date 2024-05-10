extends VBoxContainer

class_name LobbyChat

@onready var chat_line_edit: LineEdit = get_node("%ChatLineEdit")
@onready var chat_rich_text_label: RichTextLabel = get_node("%RichTextLabel")

signal chat_message_submitted(text: String)

func _ready() -> void:
	focus_mode = FOCUS_ALL
	focus_entered.connect(self._on_focus_entered)
	chat_line_edit.gui_input.connect(self._on_chat_line_edit_gui_input)
	
func _on_focus_entered():
	chat_line_edit.grab_focus()

func _on_chat_line_edit_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("gui_up"):
		get_viewport().set_input_as_handled()
		var next_node: Control = get_node(focus_neighbor_top)
		if next_node:
			next_node.grab_focus()

func _on_chat_line_edit_text_submitted(new_text: String) -> void:
	chat_message_submitted.emit(new_text)

func _on_submit_button_pressed() -> void:
	chat_message_submitted.emit(chat_line_edit.text)

func clear_chat_line():
	chat_line_edit.clear()

func clear():
	chat_rich_text_label.clear()

func push_avatar(sender: HBSteamFriend):
	chat_rich_text_label.add_image(sender.avatar, 32, 32)
	chat_rich_text_label.append_text(" ")

func add_chat_line(sender: HBSteamFriend, text: String):
	push_avatar(sender)
	chat_rich_text_label.push_bold()
	chat_rich_text_label.append_text(sender.persona_name)
	chat_rich_text_label.append_text(": ")
	chat_rich_text_label.pop()
	chat_rich_text_label.append_text(text)
	chat_rich_text_label.newline()

func notify_member_joined(member: HeartbeatSteamLobby.MemberMetadata):
	push_avatar(member.member)
	
	chat_rich_text_label.push_color(Color.GREEN)
	chat_rich_text_label.append_text(
		tr("{member_name} joined", &"Lobby chat user joined message") \
		.format({
			"member_name": member.member.persona_name
		}))
	chat_rich_text_label.pop()
	chat_rich_text_label.newline()

func notify_member_left(member: HeartbeatSteamLobby.MemberMetadata):
	push_avatar(member.member)
	
	chat_rich_text_label.push_color(Color.RED)
	chat_rich_text_label.append_text(
		tr("{member_name} left", &"Lobby chat user left message") \
		.format({
			"member_name": member.member.persona_name
		}))
	chat_rich_text_label.pop()
	chat_rich_text_label.newline()
