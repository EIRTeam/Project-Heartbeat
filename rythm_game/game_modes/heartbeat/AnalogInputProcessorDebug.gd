extends Window

class_name HBAnalogInputProcessorDebug

@onready var joystick_display := HBAnalogJoystickDebugDisplay.new()

func _ready():
	size = Vector2(512, 512)
	var vbox := VBoxContainer.new()
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ratio := AspectRatioContainer.new()
	vbox.add_child(ratio)
	ratio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ratio.add_child(joystick_display)

func display_input(inp: Vector2):
	joystick_display.display_input(inp)
