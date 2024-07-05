extends HBMenu

class_name HBOOBMenuRight

@onready var text_label: Label = get_node("%StepDescriptionLabel")

func show_text(text: String):
	text_label.text = text
