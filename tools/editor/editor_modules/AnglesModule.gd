extends HBEditorModule

@onready var straight_increment_spinbox := get_node("%StraightIncrementSpinBox")
@onready var diagonal_increment_spinbox := get_node("%DiagonalIncrementSpinBox")

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
	super._ready()
	transforms = [
		HBEditorTransforms.IncrementAnglesTransform.new(),
		HBEditorTransforms.IncrementAnglesTransform.new(false, true),
		HBEditorTransforms.IncrementAnglesTransform.new(true, true),
		HBEditorTransforms.IncrementAnglesTransform.new(true),
		HBEditorTransforms.InterpolateAngleTransform.new(),
		HBEditorTransforms.InterpolateDistanceTransform.new(),
		HBEditorTransforms.FlipOscillationTransform.new(),
		HBEditorTransforms.FlipAngleTransform.new(),
	]
	
	straight_increment_spinbox.connect("value_changed", Callable(self, "_set_straight_increment"))
	diagonal_increment_spinbox.connect("value_changed", Callable(self, "_set_diagonal_increment"))
	
	_set_straight_increment(straight_increment_spinbox.value)
	_set_diagonal_increment(diagonal_increment_spinbox.value)
	
	for i in range(angle_shortcuts.size()):
		add_shortcut(angle_shortcuts[i], "apply_angle_shortcut", [i])

func _set_straight_increment(value):
	for i in range(4):
		transforms[i].straight_increment = value
	
	UserSettings.user_settings.editor_straight_angle_increment = value
	UserSettings.save_user_settings()

func _set_diagonal_increment(value):
	for i in range(4):
		transforms[i].diagonal_increment = value
	
	UserSettings.user_settings.editor_diagonal_angle_increment = value
	UserSettings.save_user_settings()

func user_settings_changed():
	straight_increment_spinbox.value = UserSettings.user_settings.editor_straight_angle_increment
	diagonal_increment_spinbox.value = UserSettings.user_settings.editor_diagonal_angle_increment


func apply_angle_shortcut(i: int):
	var angle = 45 * i
	
	undo_redo.create_action("Change note angle to " + str(angle))
	
	for note in get_selected():
		if note.data is HBBaseNote:
			undo_redo.add_do_property(note.data, "entry_angle", angle)
			undo_redo.add_undo_property(note.data, "entry_angle", note.data.entry_angle)
			
			undo_redo.add_do_method(note.update_widget_data)
			undo_redo.add_do_method(note.sync_value.bind("entry_angle"))
			undo_redo.add_do_method(note.sync_value.bind("oscillation_frequency"))
			undo_redo.add_undo_method(note.update_widget_data)
			undo_redo.add_undo_method(note.sync_value.bind("entry_angle"))
			undo_redo.add_undo_method(note.sync_value.bind("oscillation_frequency"))
	
	undo_redo.add_do_method(self.sync_inspector_values)
	undo_redo.add_undo_method(self.sync_inspector_values)
	undo_redo.add_do_method(self.timing_points_params_changed)
	undo_redo.add_undo_method(self.timing_points_params_changed)
	
	undo_redo.commit_action()
