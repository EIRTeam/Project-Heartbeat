extends TabbedContainerTab

@onready var button_container = get_node("Panel2/MarginContainer/VBoxContainer")
@onready var modifier_button_container = get_node("%ModifierButtonContainer")
@onready var modifier_scroll_container = get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer")
@onready var button_panel = get_node("Panel2")
@onready var leaderboard_legal_text = get_node("%LeaderboardLegalLabel")

@onready var start_button = get_node("Panel2/MarginContainer/VBoxContainer/StartButton")
@onready var start_practice_button = get_node("Panel2/MarginContainer/VBoxContainer/StartPractice")
@onready var back_button = get_node("Panel2/MarginContainer/VBoxContainer/BackButton")

@onready var history_display: HBPreGameLeaderboardHistoryDisplay = get_node("%HistoryDisplay")

func _enter_tab():
	button_container.grab_focus()
