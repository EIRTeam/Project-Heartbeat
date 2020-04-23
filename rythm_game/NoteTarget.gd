extends StaticBody2D

var distance = 1400
var time_out = 1400

var note_data: HBNoteData = HBNoteData.new()
var arm_position = 0 setget set_arm_position

onready var progress_circle_rect = get_node("Node2D/TextureRect")

func set_arm_position(value):
	arm_position = value
	if UserSettings.user_settings.use_timing_arm:
		$TimingArm.rotation_degrees = clamp(360 * value, 0, 360)
	else:
		progress_circle_rect.value = arm_position
		progress_circle_rect.self_modulate.a = arm_position
	update()
func draw_circle_arc( center, radius, angleFrom, angleTo, color ):
	var nbPoints = 32
	var pointsArc = PoolVector2Array()
	
	for i in range(nbPoints+1):
		var anglePoint = angleFrom + i*(angleTo-angleFrom)/nbPoints - 90
		var point = center + Vector2( cos(deg2rad(anglePoint)), sin(deg2rad(anglePoint)) )* radius
		pointsArc.push_back( point )
	
	for indexPoint in range(nbPoints):
		draw_line(pointsArc[indexPoint], pointsArc[indexPoint+1], color, 7.0, false)
	pass

#	draw_circle_arc(Vector2.ZERO, 64, 0, arm_position*360, col)
#	draw_line(Vector2(0.0, 0.0), Vector2(400.0*distance/time_out, 0.0), Color("#FF0000"))

func _ready():
	note_data.connect("note_type_changed", self, "_on_note_type_changed")
func set_note_type(type, multi = false, hold = true):
	if multi:
		$Sprite.texture = HBNoteData.get_note_graphics(type).multi_note_target
		$Sprite/HoldTextSpriteMulti.visible = hold
	else:
		$Sprite/HoldTextSprite.visible = hold
		$Sprite.texture = HBNoteData.get_note_graphics(type).target
	var arm_disabled_types = [
		HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
		HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
	]
	if type in arm_disabled_types:
		$TimingArm.hide()
		progress_circle_rect.hide()
	else:
		if UserSettings.user_settings.use_timing_arm:
			$TimingArm.show()
			progress_circle_rect.hide()
			$TimingArm.rotation_degrees = arm_position * 360
		else:
			$TimingArm.hide()
			progress_circle_rect.show()
			progress_circle_rect.tint_progress = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	
