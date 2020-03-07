extends ConfirmationDialog

onready var custom_difficulty_checkbox = get_node("VBoxContainer/HBoxContainer2/CustomDifficultyCheckbox")
onready var custom_difficulty_line_edit = get_node("VBoxContainer/HBoxContainer2/CustomDifficultyLineEdit")
onready var difficulty_select_option_button = get_node("VBoxContainer/HBoxContainer/DifficultySelectOptionButton")
onready var stars_spinbox = get_node("VBoxContainer/HBoxContainer3/StarsSpinbox")
signal difficulty_created(difficulty, stars)

func _ready():
	connect("about_to_show", self, "_on_about_to_show")
	connect("confirmed", self, "_on_confirmed")
	custom_difficulty_checkbox.connect("toggled", self, "_on_CustomDifficultyCheckbox_toggled")
func _on_about_to_show():
	custom_difficulty_checkbox.pressed = false
	custom_difficulty_line_edit.text = ""
	custom_difficulty_line_edit.editable = false
	difficulty_select_option_button.disabled = false
	stars_spinbox.value = 3
func _on_CustomDifficultyCheckbox_toggled(pressed: bool):
	custom_difficulty_line_edit.editable = pressed
	difficulty_select_option_button.disabled = pressed

func _on_confirmed():
	var difficulty = difficulty_select_option_button.get_item_text(difficulty_select_option_button.selected)
	if custom_difficulty_checkbox.pressed:
		difficulty = custom_difficulty_line_edit.text
	emit_signal("difficulty_created", difficulty, stars_spinbox.value)
	
