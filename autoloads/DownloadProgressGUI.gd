extends CanvasLayer

const PER_NOTIFICATION_OFFSET = 90.0
var notifications = []
# When the user plays, we hold back notifications
var holding_back_notifications = false: set = set_holding_back_notifications
var held_back_notifications = []

@onready var control = get_node("DownloadProgressGUI")

const PROGRESS_THING_SCENE = preload("res://autoloads/DownloadProgressThing.tscn")

func add_notification(notification_scene: HBDownloadProgressThing, can_be_held_back=false):
	if can_be_held_back and holding_back_notifications:
		held_back_notifications.append(notification_scene)
	else:
		control.add_child(notification_scene)
		notification_scene.appear(PER_NOTIFICATION_OFFSET)
		set_offsets(PER_NOTIFICATION_OFFSET)
		notifications.push_front(notification_scene)
		notification_scene.connect("disappeared", Callable(self, "remove_notification").bind(notification_scene))

func set_holding_back_notifications(val):
	holding_back_notifications = val
	control.visible = !holding_back_notifications
	if not holding_back_notifications:
		for scene in held_back_notifications:
			add_notification(scene)
		held_back_notifications = []

func set_offsets(base=0.0):
	var offset = base
	for notification in notifications:
		offset += PER_NOTIFICATION_OFFSET
		notification.move_to_offset(offset, 0.75)

func remove_notification(notification_scene, free=false):
	if notification_scene in notifications:
		notifications.erase(notification_scene)
		if free:
			control.remove_child(notification_scene)
			notification_scene.queue_free()
		else:
			notification_scene.disappear()
		set_offsets()
