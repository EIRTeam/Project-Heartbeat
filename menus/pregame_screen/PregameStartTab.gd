extends TabbedContainerTab

@onready var button_container = get_node("Panel2/MarginContainer/VBoxContainer")
@onready var modifier_button_container = get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer/VBoxContainer")
@onready var modifier_scroll_container = get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel/MarginContainer/ScrollContainer")
@onready var button_panel = get_node("Panel2")
@onready var leaderboard_legal_text = get_node("Panel/HBoxContainer/VBoxContainer/Panel2/HBoxContainer/Label")
@onready var stats_label = get_node("Panel/HBoxContainer/VBoxContainer/HBoxContainer/Panel2/StatsLabel")
@onready var start_button = get_node("Panel2/MarginContainer/VBoxContainer/StartButton")
@onready var start_practice_button = get_node("Panel2/MarginContainer/VBoxContainer/StartPractice")
@onready var back_button = get_node("Panel2/MarginContainer/VBoxContainer/BackButton")

func _enter_tab():
	button_container.grab_focus()
