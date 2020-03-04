extends ConfirmationDialog

onready var track_vbox_container = get_node("MarginContainer/VBoxContainer/Panel/ScrollContainer/VBoxContainer")

signal track_import_accepted(smf, note_range, tracks)

var current_smf: SMFLoader.SMF

func _ready():
	connect("confirmed", self, "_on_confirmed")

func load_smf(path: String):
	var smf_loader = SMFLoader.new()
	current_smf = smf_loader.read_file(path)
	populate_tracks()
func populate_tracks():
	for child in track_vbox_container.get_children():
		child.queue_free()
	for i in range(current_smf.tracks.size()):
		var track = current_smf.tracks[i]
		var checkbox = CheckBox.new()
		checkbox.text = "Track %d, with %d events" % [i, track.events.size()]
		checkbox.set_meta("track_id", i)
		track_vbox_container.add_child(checkbox)

func _on_confirmed():
	var tracks = []
	for checkbox in track_vbox_container.get_children():
		if checkbox.pressed:
			tracks.append(checkbox.get_meta("track_id"))
	emit_signal("track_import_accepted", current_smf, [0, 255], tracks)
