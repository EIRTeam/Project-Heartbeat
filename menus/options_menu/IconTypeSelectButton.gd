extends HBHovereableButton

var icon_pack = "" setget set_icon_pack

func set_icon_pack(val):
	if icon_pack != val:
		icon_pack = val
		$HBoxContainer.icon_pack = icon_pack
