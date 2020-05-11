# unused but left here for historic purposes...
extends Control

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

func _ready():
	var pack := PPDPack.new("user://songs/HIP/Extreme.ppd")
	var index = pack.get_file_index("evd")
	for name in pack.file_names:
		var name_str = name.get_string_from_utf8()
		var f = File.new()
		f.open("user://test/" + name_str, File.WRITE)
		var buff = pack.file.seek(pack.file_offsets[pack.file_names.find(name)])
		f.store_buffer(pack.file.get_buffer(pack.file_sizes[pack.file_names.find(name)]))
	get_data_from_evd(pack.file, pack.file_sizes[index], pack.file_offsets[index])
	# var chart = PPDLoader.PPD2HBChart("user://Easy.ppd", 100)
	# var file := File.new()
	# print(file.open("user://test.json", File.WRITE))
	# file.store_string(JSON.print(chart.serialize(), "  "))
#	extract_pack("user://resource.pak")

static func get_data_from_evd(file: File, file_size, file_offset):
	var events = []
	file.seek(file_offset)
	var tb = 0
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
			PPDEventType.ChangeInitializeOrder:
				# Ignored
				var _table = file.get_buffer(10)
			PPDEventType.ChangeSlideScale:
				var slide_scale = file.get_float()
				event["slide_scale"] = slide_scale
		print("Found event of type " + HBUtils.find_key(PPDEventType, mode))
		print(event)
		events.append(event)
	return events

func extract_pack(path: String):
	var pack := PPDPack.new(path)
	for file in pack.file_names:
		var f_path = "user://" + file.get_string_from_utf8()
		var dir = Directory.new()
		dir.make_dir_recursive(f_path.get_base_dir())
		var index = pack.get_file_index(file.get_string_from_utf8())
		pack.file.seek(pack.file_offsets[index])
		var buff = pack.file.get_buffer(pack.file_sizes[index])
		
		var f = File.new()
		f.open(f_path, File.WRITE)
		f.store_buffer(buff)
		f.close()
