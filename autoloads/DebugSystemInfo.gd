extends CanvasLayer

func _ready():
	$"Version Label".text = HBVersion.get_version_string()
	print(HBVersion.get_version_string())
