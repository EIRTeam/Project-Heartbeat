extends VBoxContainer

class_name HBSkinEditorComponentPicker

signal component_picked(component)

var components := [
	HBUISongProgress,
	HBUIClearBar,
	HBUIPanel,
	HBUIAccuracyDisplay,
	HBUICosmeticTextureRect,
	HBUISongTitle,
	HBUISongDifficultyLabel,
	HBUIScoreCounter,
	HBUISkipIntroIndicator,
	HBUIHoldIndicator,
	HBUIMultiHint,
	HBUIHealthDisplay
]

func _ready():
	update_list()
func update_list():
	for button in get_children():
		button.queue_free()
	for component in components:
		var but := Button.new()
		but.text = component.get_component_name()
		but.connect("pressed", Callable(self, "_on_component_picked").bind(component))
		add_child(but)
func _on_component_picked(component):
	emit_signal("component_picked", component)
