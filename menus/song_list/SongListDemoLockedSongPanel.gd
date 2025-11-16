extends CenterContainer

class_name HBSongListDemoLockedSongPanel

enum LockedSongPanelResult {
	GO_TO_STORE,
	CONTINUE
}

signal finished(result: LockedSongPanelResult)

@onready var go_to_store_button: Button = get_node("%GoToStoreButton")
@onready var continue_button: Button = get_node("%ContinueButton")
@onready var button_container: HBSimpleMenu = get_node("%ButtonContainer")

func _ready() -> void:
	go_to_store_button.pressed.connect(hide)
	go_to_store_button.pressed.connect(finished.emit.bind(LockedSongPanelResult.GO_TO_STORE))
	continue_button.pressed.connect(hide)
	continue_button.pressed.connect(finished.emit.bind(LockedSongPanelResult.CONTINUE))
	popup()

func popup():
	show()
	button_container.grab_focus()
