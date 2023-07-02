extends Control

@onready var tween := Threen.new()

const ANIMATION_DURATION = 0.5
const ANIMATION_DELAY = 0.25
const SECTION_SCENE = preload("res://menus/PregameChartFeatureDisplaySection.tscn")

@onready var item_container: VBoxContainer = get_node("MarginContainer/VBoxContainer2/MarginContainer/VBoxContainer")

var item_controls = []

var t = 0.0

enum FEATURES_DISPLAY_TYPES {
	NORMAL_NOTES,
	HOLD_NOTES,
	SLIDE_NOTES,
	SLIDE_CHAINS,
	DOUBLE_NOTES,
	SUSTAIN_NOTES,
	HEART_NOTES
}

var feature_titles = {
	FEATURES_DISPLAY_TYPES.NORMAL_NOTES: tr("Normal notes"),
	FEATURES_DISPLAY_TYPES.HOLD_NOTES: tr("Hold notes"),
	FEATURES_DISPLAY_TYPES.SLIDE_NOTES: tr("Slide notes"),
	FEATURES_DISPLAY_TYPES.SLIDE_CHAINS: tr("Slide chains"),
	FEATURES_DISPLAY_TYPES.DOUBLE_NOTES: tr("Double notes"),
	FEATURES_DISPLAY_TYPES.SUSTAIN_NOTES: tr("Sustain notes"),
	FEATURES_DISPLAY_TYPES.HEART_NOTES: tr("Heart notes")
}

var feature_descriptions = {
	FEATURES_DISPLAY_TYPES.NORMAL_NOTES: tr("Press the indicated buton!"),
	FEATURES_DISPLAY_TYPES.HOLD_NOTES: tr("Hold these notes for as long as you can!"),
	FEATURES_DISPLAY_TYPES.SLIDE_NOTES: tr("Press the indicated direction!"),
	FEATURES_DISPLAY_TYPES.SLIDE_CHAINS: tr("Hold the indicated direction!"),
	FEATURES_DISPLAY_TYPES.DOUBLE_NOTES: tr("Press the indicated note on two different buttons!"),
	FEATURES_DISPLAY_TYPES.SUSTAIN_NOTES: tr("Hold and release when the time is right!"),
	FEATURES_DISPLAY_TYPES.HEART_NOTES: tr("Flick in any direction!")
}

var feature_actions = {
	FEATURES_DISPLAY_TYPES.NORMAL_NOTES: ["note_up", "note_left", "note_down", "note_right"],
	FEATURES_DISPLAY_TYPES.HOLD_NOTES: ["note_up", "note_left", "note_down", "note_right"],
	FEATURES_DISPLAY_TYPES.DOUBLE_NOTES: ["note_up", "note_left", "note_down", "note_right"],
	FEATURES_DISPLAY_TYPES.SLIDE_NOTES: ["slide_left", "slide_right"],
	FEATURES_DISPLAY_TYPES.SLIDE_CHAINS: ["slide_left", "slide_right"],
	FEATURES_DISPLAY_TYPES.SUSTAIN_NOTES: ["note_up", "note_left", "note_down", "note_right"],
	FEATURES_DISPLAY_TYPES.HEART_NOTES: ["heart_note"]
}

var feature_actions_plus_one = {
	FEATURES_DISPLAY_TYPES.DOUBLE_NOTES: ["note_up", "note_left", "note_down", "note_right"],
	FEATURES_DISPLAY_TYPES.SLIDE_NOTES: ["slide_left", "slide_right"],
	FEATURES_DISPLAY_TYPES.HEART_NOTES: ["heart_note"]
}

var feature_textures = {
	FEATURES_DISPLAY_TYPES.NORMAL_NOTES: preload("res://menus/chart_feature_previews/normal_note.png"),
	FEATURES_DISPLAY_TYPES.HOLD_NOTES: preload("res://menus/chart_feature_previews/hold_note.png"),
	FEATURES_DISPLAY_TYPES.DOUBLE_NOTES: preload("res://menus/chart_feature_previews/double_note.png"),
	FEATURES_DISPLAY_TYPES.SLIDE_NOTES: preload("res://menus/chart_feature_previews/slide_note.png"),
	FEATURES_DISPLAY_TYPES.SLIDE_CHAINS: preload("res://menus/chart_feature_previews/slide_chain.png"),
	FEATURES_DISPLAY_TYPES.SUSTAIN_NOTES: preload("res://menus/chart_feature_previews/sustain_note.png"),
	FEATURES_DISPLAY_TYPES.HEART_NOTES: preload("res://menus/chart_feature_previews/heart_note.png")
}

var disable_axis_direction_display_features = [FEATURES_DISPLAY_TYPES.HEART_NOTES]

func _ready():
	add_child(tween)
	set_process(true)

func make_controls(features: Array):
	var curr_container: HBoxContainer
	for i in range(features.size()):
		var feature = features[i]
		if fmod(i, 4) == 0:
			curr_container = HBoxContainer.new()
			curr_container.alignment = BoxContainer.ALIGNMENT_CENTER
			item_container.add_child(curr_container)
		var feature_title = feature_titles[feature]
		var feature_description = feature_descriptions[feature]
		var feature_actions_o = feature_actions.get(feature, [])
		var feature_actions_plus_one_o = feature_actions_plus_one.get(feature, [])
		var control = SECTION_SCENE.instantiate()
		control.title = feature_title
		control.description = feature_description
		control.actions = feature_actions_o
		control.actions_plus_one = feature_actions_plus_one_o
		control.texture = feature_textures[feature]
		control.disable_axis_direction_display = feature in disable_axis_direction_display_features
		
		curr_container.add_child(control)
		item_controls.append(control)
		
func _process(delta):
	$MarginContainer/VBoxContainer2/Panel.self_modulate.a = 0.2 + (abs(sin(t*2.0)) * 1.0-0.2)
	t += delta
func animate_controls():
	tween.remove_all()
	for i in range(item_controls.size()):
		var duration = ANIMATION_DURATION
		var delay = i * ANIMATION_DELAY
		var child = item_controls[i]
		child.modulate.a = 0.0
		child.scale = Vector2(0.5, 0.5)
		child.pivot_offset = child.size * 0.5
		child.show()
		tween.interpolate_property(child, "scale", Vector2(0.5, 0.5), Vector2.ONE, duration, Threen.TRANS_BOUNCE, Threen.EASE_OUT, delay)
		tween.interpolate_property(child, "modulate:a", 0.0, 1.0, duration, Threen.TRANS_ELASTIC, Threen.EASE_OUT, delay)
		tween.start()
		

func set_chart(chart: HBChart):
	var chart_possible_features = FEATURES_DISPLAY_TYPES.values()
	
	var chart_features = []

	var tps = chart.get_timing_points()
	
	for tp in tps:
		var found_feature = -1
		if tp is HBSustainNote:
			found_feature = FEATURES_DISPLAY_TYPES.SUSTAIN_NOTES
		elif tp is HBDoubleNote:
			found_feature = FEATURES_DISPLAY_TYPES.DOUBLE_NOTES
		elif tp is HBNoteData:
			if tp.hold:
				found_feature = FEATURES_DISPLAY_TYPES.HOLD_NOTES
			elif tp.is_slide_note():
				found_feature = FEATURES_DISPLAY_TYPES.SLIDE_NOTES
			elif tp.is_slide_hold_piece():
				found_feature = FEATURES_DISPLAY_TYPES.SLIDE_CHAINS
			elif tp.note_type == HBNoteData.NOTE_TYPE.HEART:
				found_feature = FEATURES_DISPLAY_TYPES.HEART_NOTES
			else:
				found_feature = FEATURES_DISPLAY_TYPES.NORMAL_NOTES
		if found_feature != -1 and not found_feature in chart_features:
			chart_possible_features.erase(found_feature)
			chart_features.append(found_feature)
			if chart_possible_features.size() == 0:
				break
	chart_features.sort()
	make_controls(chart_features)
