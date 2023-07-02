extends ConfirmationDialog

@onready var custom_difficulty_checkbox = get_node("VBoxContainer/HBoxContainer2/CustomDifficultyCheckbox")
@onready var custom_difficulty_line_edit = get_node("VBoxContainer/HBoxContainer2/CustomDifficultyLineEdit")
@onready var difficulty_select_option_button = get_node("VBoxContainer/HBoxContainer/DifficultySelectOptionButton")
@onready var stars_spinbox = get_node("VBoxContainer/HBoxContainer3/StarsSpinBox")
@onready var chart_style_option_button = get_node("VBoxContainer/OptionButton")
signal difficulty_created(difficulty, stars, uses_console_style)

func _ready():
	connect("about_to_popup", Callable(self, "_on_about_to_show"))
	connect("confirmed", Callable(self, "_on_confirmed"))
	custom_difficulty_checkbox.connect("toggled", Callable(self, "_on_CustomDifficultyCheckbox_toggled"))
func _on_about_to_show():
	custom_difficulty_checkbox.button_pressed = false
	custom_difficulty_line_edit.text = ""
	custom_difficulty_line_edit.editable = false
	difficulty_select_option_button.disabled = false
	stars_spinbox.value = 3
	size = get_contents_minimum_size()
func _on_CustomDifficultyCheckbox_toggled(pressed: bool):
	custom_difficulty_line_edit.editable = pressed
	difficulty_select_option_button.disabled = pressed

func _on_confirmed():
	var difficulty = difficulty_select_option_button.get_item_text(difficulty_select_option_button.selected)
	if custom_difficulty_checkbox.pressed:
		difficulty = custom_difficulty_line_edit.text
	var uses_console_style = chart_style_option_button.get_selected_id() == 1
	emit_signal("difficulty_created", difficulty, stars_spinbox.value, uses_console_style)
	
