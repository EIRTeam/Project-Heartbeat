# PPD EVD file parser
class_name PPDEVDFile

enum PPDEventType {
	ChangeVolume = 0,
	ChangeBPM = 1,
	RapidChangeBPM = 2,
	ChangeSoundPlayMode = 3,
	ChangeDisplayState = 4,
	ChangeMoveState = 5,
	ChangeReleaseSound = 6,
	ChangeNoteType = 7,
	ChangeInitializeOrder = 8,
	ChangeSlideScale = 9
}

var evd_events = []

func get_note_type_at_time(time: float):
	var note_type = 0
	for event in evd_events:
		if event.event_type == PPDEventType.ChangeNoteType:
			if event.time > time:
				break
			note_type = event.note_type
	return note_type

func get_slide_scale_at_time(time: float):
	var slide_scale = 1.0
	for event in evd_events:
		if event.event_type == PPDEventType.ChangeSlideScale:
			if event.time > time:
				break
			slide_scale = event.slide_scale
	return slide_scale

func from_file(file: FileAccess, file_length, file_offset):
	evd_events = get_data_from_evd(file, file_length, file_offset)

static func get_data_from_evd(file: FileAccess, file_size, file_offset):
	var events = []
	file.seek(file_offset)
	while file.get_position() < file_offset + file_size:
		var time = file.get_float()
		var mode = file.get_8()
		var event = {
			"time": time,
			"event_type": mode
		}
		match mode:
			PPDEventType.ChangeVolume:
				# Ignored
				var _channel = file.get_8()
				var _volpercent = file.get_8()
			PPDEventType.ChangeBPM:
				var target_bpm = file.get_float()
				event["target_bpm"] = target_bpm
			PPDEventType.RapidChangeBPM:
				var target_bpm = file.get_float()
				var rapid = file.get_8()
				event["target_bpm"] = target_bpm
				event["rapid"] = rapid
			PPDEventType.ChangeSoundPlayMode:
				# Ignored
				var _channel = file.get_8()
				var _keep_playing = file.get_8()
			PPDEventType.ChangeDisplayState:
				# Ignored
				var _dstate = file.get_8()
			PPDEventType.ChangeMoveState:
				# Ignored
				var _mstate = file.get_8()
			PPDEventType.ChangeReleaseSound:
				# Ignored	
				var _channel = file.get_8()
				var _release_sound = file.get_8()
			PPDEventType.ChangeNoteType:
				# Ignored
				var _note_type = file.get_8()
				event["note_type"] = _note_type
			PPDEventType.ChangeInitializeOrder:
				# Ignored
				var _table = file.get_buffer(10)
			PPDEventType.ChangeSlideScale:
				var slide_scale = file.get_float()
				event["slide_scale"] = slide_scale
		events.append(event)
	return events
