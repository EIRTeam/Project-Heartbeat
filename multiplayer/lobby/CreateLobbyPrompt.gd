extends CenterContainer

class_name CreateLobbyPrompt

signal accept(lobby_type: int)
signal cancel(lobby_type: int)

@onready var lobby_privacy_option_button: HBHovereableOptionButton = get_node("%LobbyPrivacy")
@onready var button_container: VBoxContainer = get_node("%ButtonContainer")
@onready var accept_cancel_button_container: HBSimpleMenu = get_node("%AcceptCancelButtonContainer")

func _ready() -> void:
	const ALLOWED_LOBBY_TYPES := [
		SteamworksConstants.LobbyType.LOBBY_TYPE_PUBLIC,
		SteamworksConstants.LobbyType.LOBBY_TYPE_FRIENDS_ONLY,
		SteamworksConstants.LobbyType.LOBBY_TYPE_PRIVATE
	]
	for type in ALLOWED_LOBBY_TYPES:
		lobby_privacy_option_button.add_item(HeartbeatSteamLobby.get_localized_lobby_privacy_text(type), type)

func prompt():
	show()
	accept_cancel_button_container.grab_focus()
	# Make sure we select the accept button
	accept_cancel_button_container.select_button(1)

func _on_accept_button_pressed() -> void:
	accept.emit(lobby_privacy_option_button.get_selected_item_id())
	hide()

func _on_cancel_button_pressed() -> void:
	cancel.emit()
	hide()
