extends Control

@onready var chapter_title: TutorialUIChapterTitle = %ChapterTitle
	
	
func initialize(_tutorial_song: HBSong):
	pass
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_F1 and event.pressed and not event.is_echo():
			chapter_title.play_show_animation()
