extends HBEditorModule

signal show_transform(transformation)
signal hide_transform()
signal apply_transform(transformation)

onready var straight_increment_spinbox := get_node("%StraightIncrementSpinBox")
onready var diagonal_increment_spinbox := get_node("%DiagonalIncrementSpinBox")
onready var increment_away_button := get_node("%AwayButton")
onready var increment_closer_button := get_node("%CloserButton")
onready var increment_away_back_button := get_node("%AwayBackButton")
onready var increment_closer_back_button := get_node("%CloserBackButton")
onready var interpolate_angles_button := get_node("%InterpolateAnglesButton")
onready var interpolate_distances_button := get_node("%InterpolateDistancesButton")
onready var flip_oscillations_button := get_node("%FlipOscillationsButton")
onready var flip_angles_button := get_node("%FlipAnglesButton")

var increment_angles_transform := HBEditorTransforms.IncrementAnglesTransform.new()

var angle_shortcuts = [
	"editor_angle_r",
	"editor_angle_dr",
	"editor_angle_d",
	"editor_angle_dl",
	"editor_angle_l",
	"editor_angle_ul",
	"editor_angle_u",
	"editor_angle_ur",
]


func _ready():
	add_shortcut("editor_interpolate_angle", "apply_angle_transform", interpolate_angles_button, [0])
	add_shortcut("editor_interpolate_distance", "apply_angle_transform", interpolate_distances_button, [1])
	add_shortcut("editor_flip_oscillation", "apply_angle_transform", flip_oscillations_button, [2])
	add_shortcut("editor_flip_angle", "apply_angle_transform", flip_angles_button, [3])
	
	add_shortcut("editor_move_angles_away", "arrange_angles", increment_closer_button)
	add_shortcut("editor_move_angles_closer", "arrange_angles", increment_away_button, [true])
	add_shortcut("editor_move_angles_closer_back", "arrange_angles", increment_closer_back_button, [true, true])
	add_shortcut("editor_move_angles_away_back", "arrange_angles", increment_away_back_button, [false, true])
	
	for i in range(angle_shortcuts.size()):
		add_shortcut(angle_shortcuts[i], "apply_angle_shortcut", null, [i])
	
	update_shortcuts()

func set_editor(_editor: HBEditor):
	.set_editor(_editor)
	
	connect("show_transform", editor, "_show_transform_on_current_notes")
	connect("hide_transform", editor.game_preview.transform_preview, "hide")
	connect("apply_transform", editor, "_apply_transform_on_current_notes")


func show_arrange_angles(invert: bool = false, backwards: bool = false):
	increment_angles_transform.timing_interval = get_timing_interval(1.0/16.0) * 2
	increment_angles_transform.backwards = backwards
	increment_angles_transform.invert = invert
	increment_angles_transform.straight_increment = straight_increment_spinbox.value
	increment_angles_transform.diagonal_increment = diagonal_increment_spinbox.value
	
	emit_signal("show_transform", increment_angles_transform)

func arrange_angles(invert: bool = false, backwards: bool = false):
	increment_angles_transform.timing_interval = get_timing_interval(1.0/16.0) * 2
	increment_angles_transform.backwards = backwards
	increment_angles_transform.invert = invert
	increment_angles_transform.straight_increment = straight_increment_spinbox.value
	increment_angles_transform.diagonal_increment = diagonal_increment_spinbox.value
	
	emit_signal("apply_transform", increment_angles_transform)


var modify_angles_transforms = [
	HBEditorTransforms.InterpolateAngleTransform.new(),
	HBEditorTransforms.InterpolateDistanceTransform.new(),
	HBEditorTransforms.FlipOscillationTransform.new(),
	HBEditorTransforms.FlipAngleTransform.new(),
]

func show_angle_transform(id: int):
	emit_signal("show_transform", modify_angles_transforms[id])

func apply_angle_transform(id: int):
	emit_signal("apply_transform", modify_angles_transforms[id])

func hide_transform():
	emit_signal("hide_transform")


func apply_angle_shortcut(i: int):
	var angle = 45 * i
	
	undo_redo.create_action("Change note angle to " + str(angle))
	
	for note in get_selected():
		if note.data is HBBaseNote:
			undo_redo.add_do_property(note.data, "entry_angle", angle)
			undo_redo.add_undo_property(note.data, "entry_angle", note.data.entry_angle)
			
			undo_redo.add_do_method(note, "update_widget_data")
			undo_redo.add_do_method(note, "sync_value", "entry_angle")
			undo_redo.add_do_method(note, "sync_value", "oscillation_frequency")
			undo_redo.add_undo_method(note, "update_widget_data")
			undo_redo.add_undo_method(note, "sync_value", "entry_angle")
			undo_redo.add_undo_method(note, "sync_value", "oscillation_frequency")
	
	undo_redo.add_do_method(self, "sync_inspector_values")
	undo_redo.add_undo_method(self, "sync_inspector_values")
	undo_redo.add_do_method(self, "timing_points_params_changed")
	undo_redo.add_undo_method(self, "timing_points_params_changed")
	
	undo_redo.commit_action()
