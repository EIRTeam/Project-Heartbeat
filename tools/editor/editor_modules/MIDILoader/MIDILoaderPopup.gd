extends ConfirmationDialog

signal track_import_accepted(smf, note_range, tracks)

@onready var track_tree: Tree = get_node("%Tree")

var current_smf: SMFLoader.SMF
var track_root: TreeItem

func _ready():
	connect("confirmed", Callable(self, "_on_confirmed"))

func load_smf(path: String):
	var smf_loader = SMFLoader.new()
	current_smf = smf_loader.read_file(path)
	populate_tracks()

func populate_tracks():
	track_tree.clear()
	track_tree.set_column_custom_minimum_width(0, 1)
	track_tree.set_column_custom_minimum_width(1, 11)
	
	track_root = track_tree.create_item()
	track_root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	track_root.set_editable(0, true)
	track_root.set_text(1, "All Tracks")
	
	for i in range(current_smf.tracks.size()):
		var track = current_smf.tracks[i]
		var track_item = track_tree.create_item(track_root)
		
		track_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		track_item.set_editable(0, true)
		track_item.set_text(1, "Track %d, with %d events" % [i, track.events.size()])
		track_item.set_meta("track_id", i)

func _on_confirmed():
	var tracks = []
	var current_item = track_root.get_children()
	
	while current_item:
		if current_item.is_checked(0):
			tracks.append(current_item.get_meta("track_id"))
		
		current_item = current_item.get_next()
	
	emit_signal("track_import_accepted", current_smf, [0, 255], tracks)


func _on_tree_item_edited():
	if track_tree.get_selected() == track_root and track_tree.get_selected_column() == 0:
		var select_all = track_root.is_checked(0)
		var current_item = track_root.get_children()
		
		while current_item:
			current_item.set_checked(0, select_all)
			
			current_item = current_item.get_next()
