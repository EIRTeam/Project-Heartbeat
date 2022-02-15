extends Control

const XBOX_DIAGRAM = preload("res://graphics/XboxOne_Diagram_Simple.png")
const PS4_DIAGRAM = preload("res://graphics/PS4_Diagram_Simple.png")

onready var controller_diagram_texture_rect = get_node("AspectRatioContainer/MarginContainer/CenterContainer/TextureRect")

func _ready():
	set_note_usage([HBChart.ChartNoteUsage.CONSOLE])
	print(JoypadSupport.get_joypad_type())
	match JoypadSupport.get_joypad_type():
		JS_JoypadIdentifier.JoyPads.XBOX:
			controller_diagram_texture_rect.texture = XBOX_DIAGRAM
		JS_JoypadIdentifier.JoyPads.PLAYSTATION:
			controller_diagram_texture_rect.texture = PS4_DIAGRAM
func set_note_usage(note_usage):
	$ArcadeInfo.hide()
	$ConsoleInfo.hide()
	if HBChart.ChartNoteUsage.ARCADE in note_usage:
		$ArcadeInfo.show()
		$AspectRatioContainer/MarginContainer.remove_constant_override("margin_bottom")
	elif HBChart.ChartNoteUsage.CONSOLE in note_usage:
		$ConsoleInfo.show()
