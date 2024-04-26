extends MarginContainer

class_name HBResultsScreenNoteHitTotalsDisplay

@onready var combo_label = get_node("%ComboLabel")
@onready var total_notes_label = get_node("%TotalNotesLabel")
@onready var notes_hit_label = get_node("%NotesHitLabel")

var result_update_queued := false

func _queue_result_update():
	if not result_update_queued:
		result_update_queued = true
		_update_result.call_deferred()
func _update_result():
	result_update_queued = false
	if result:
		combo_label.text = str(result.max_combo)
		total_notes_label.text = str(result.total_notes)
		notes_hit_label.text = str(result.notes_hit)
	else:
		combo_label.text = "..."
		total_notes_label.text = "..."
		notes_hit_label.text = "..."
var result: HBResult:
	set(val):
		result = val
		_queue_result_update()
