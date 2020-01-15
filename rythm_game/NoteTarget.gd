extends StaticBody2D

var distance = 1400
var time_out = 1400

var note_data: HBNoteData = HBNoteData.new()
var arm_position = 0 setget set_arm_position

func set_arm_position(value):
	arm_position = value
	$TimingArm.rotation_degrees = clamp(360 * value, 0, 360)

func _draw():
	pass
#	draw_line(Vector2(0.0, 0.0), Vector2(400.0*distance/time_out, 0.0), Color("#FF0000"))

func _ready():
	note_data.connect("note_type_changed", self, "_on_note_type_changed")

func set_note_type(type, multi = false, hold = false):
	if multi:
		$Sprite.texture = HBNoteData.get_note_graphics(type).multi_note_target
		$Sprite/HoldTextSpriteMulti.visible = hold
	else:
		$Sprite/HoldTextSprite.visible = hold
		$Sprite.texture = HBNoteData.get_note_graphics(type).target
	$TimingArm.rotation_degrees = arm_position * 360
