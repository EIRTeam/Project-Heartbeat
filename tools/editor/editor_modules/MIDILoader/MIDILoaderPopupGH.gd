extends "MIDILoaderPopup.gd"

enum GH_DIFFICULTIES {
	EASY,
	NORMAL,
	HARD,
	EXTREME
}

var difficulty_ranges = {
	GH_DIFFICULTIES.EASY: [60, 64],
	GH_DIFFICULTIES.NORMAL: [72, 76],
	GH_DIFFICULTIES.HARD: [84, 88],
	GH_DIFFICULTIES.EXTREME: [96, 100]
}

@onready var item_list = get_node("MarginContainer/VBoxContainer/Panel/ScrollContainer/VBoxContainer/ItemList")

func load_smf(path: String):
	var smf_loader = SMFLoader.new()
	current_smf = smf_loader.read_file(path)
	populate_difficulties()
func populate_difficulties():
	item_list.clear()
	var found_diff_notes = {}
		
	for track in current_smf.tracks:
		for event in track.events:
			if event.event.type == SMFLoader.MIDIEventType.note_on:
				var note = event.event.note
				for difficulty_range_type in difficulty_ranges:
					var difficulty_range = difficulty_ranges[difficulty_range_type]
					if difficulty_range[0] <= note and note <= difficulty_range[1]:
						var key = HBUtils.find_key(GH_DIFFICULTIES, difficulty_range_type)
						if not found_diff_notes.has(key):
							found_diff_notes[key] = 0
						found_diff_notes[key] += 1
						break
	for difficulty in found_diff_notes:
		item_list.add_item(difficulty.capitalize() + ", %d notes" % [found_diff_notes[difficulty]])
		item_list.set_item_metadata(item_list.get_item_count()-1, difficulty)


func _on_confirmed():
	if item_list.is_anything_selected():
		var difficulty = GH_DIFFICULTIES[item_list.get_item_metadata(item_list.get_selected_items()[0])]
		var difficulty_range = difficulty_ranges[difficulty]
		emit_signal("track_import_accepted", current_smf, difficulty_range, [])
