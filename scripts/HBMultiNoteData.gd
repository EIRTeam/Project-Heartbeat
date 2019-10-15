extends HBNoteData

class_name HBMultiNoteData

var number_of_notes = 3
var duration = 3000
var target_position = Vector2(0.25, 0.5)

func _init():
	._init()
	serializable_fields += ["number_of_notes", "duration", "target_position"]

func get_simplified():
	var interval = duration / (number_of_notes - 1)
	var notes = []
	for i in range(number_of_notes):
		var data = HBNoteData.new()
		data.note_type = note_type
		data.time_out = time_out
		data.oscillation_amplitude = oscillation_amplitude
		data.oscillation_frequency = oscillation_frequency
		data.oscillation_phase_shift = oscillation_phase_shift
		data.entry_angle = entry_angle
		data.position = lerp(position, target_position, float(i)/float(number_of_notes-1))
		data.time = int(time + (i * interval))
		notes.append(data)
	return notes 

func get_duration():
	return duration

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorTimelineItemMultinote.tscn")
	var timeline_item = timeline_item_scene.instance()
	timeline_item.data = self
	return timeline_item

func get_serialized_type():
	return "MultiNote"
