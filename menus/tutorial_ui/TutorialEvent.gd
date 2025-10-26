class_name HBTutorialEvent

enum EventType {
	CHAPTER_TITLE,
	DIALOGUE,
	SHOW_NOTE_PREVIEWS,
	SHOW_BUTTON_PROMPTS,
}

var event_type: EventType
var time_msec: int
var text: String
var notes_to_show: Array[HBBaseNote.NOTE_TYPE]
var prompts_to_show: Array[StringName]
var show_double_button_prompts := false

func _init(_event_type: EventType):
	event_type = _event_type

static func create_chapter(at_time: int, text: String) -> HBTutorialEvent:
	var event := HBTutorialEvent.new(EventType.CHAPTER_TITLE)
	event.time_msec = at_time
	event.text = text
	return event

static func create_dialogue(at_time: int, text: String) -> HBTutorialEvent:
	var event := HBTutorialEvent.new(EventType.DIALOGUE)
	event.time_msec = at_time
	event.text = text
	return event

static func create_show_note_previews(at_time: int, notes: Array[HBNoteData.NOTE_TYPE]) -> HBTutorialEvent:
	var event := HBTutorialEvent.new(EventType.SHOW_NOTE_PREVIEWS)
	event.notes_to_show = notes
	event.time_msec = at_time
	return event

static func show_button_prompts(at_time: int, actions: Array[StringName], show_double := false):
	var event := HBTutorialEvent.new(EventType.SHOW_BUTTON_PROMPTS)
	event.prompts_to_show = actions
	event.time_msec = at_time
	event.show_double_button_prompts = show_double
	return event
