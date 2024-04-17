extends HBSerializable

class_name HBConsoleToArcadeModifierSettings

var keep_hearts := false

enum SUSTAIN_MODE {
	TWO_NOTES,
	HOLD,
	SINGLE_NOTE
}

var sustain_mode: SUSTAIN_MODE = SUSTAIN_MODE.TWO_NOTES

func _init():
	serializable_fields += ["keep_hearts", "sustain_mode"]

func get_serialized_type():
	return "ConsoleToArcadeSettings"
