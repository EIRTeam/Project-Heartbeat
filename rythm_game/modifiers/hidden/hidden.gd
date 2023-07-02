extends HBModifier

const HiddenSettings = preload("res://rythm_game/modifiers/hidden/hidden_settings.gd")

func _init():
	processing_notes = true

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()
	
const HIDDEN_PERCENTAGE_START = 0.75
const HIDDEN_DURATION = 0.1
	
func _set_note_drawer_a(note_drawer, time: float, bpm: float):
	var note_time: float = note_drawer.note_data.time / 1000.0
	var perc: float = 1.0 - ((note_time - time) / (note_drawer.note_data.get_time_out(bpm) / 1000.0))
#			var a_o = clamp(, 0.0, HIDDEN_DURATION) / HIDDEN_DURATION
	var a_o = 1.0 - smoothstep(HIDDEN_PERCENTAGE_START, HIDDEN_PERCENTAGE_START+HIDDEN_DURATION, perc)
	
	for node_data in note_drawer.layer_bound_node_datas:
		if node_data is HBNewNoteDrawer.LayerBoundNodeData:
			if node_data.layer_name != "HitParticles" and node_data.layer_name != "SlideChainPieces":
				node_data.node.modulate.a = a_o
	note_drawer.modulate.a = a_o
	
func _process_note(note_drawers: Array, time: float, bpm: float):
	# TODO: this
	pass
	#for note_drawer in note_drawers:
	#	if note_drawer is HBSlideN:
	#		for drw in note_drawer.slide_chain_drawers.values():
	#			_set_note_drawer_a(drw, time, bpm)
	#	_set_note_drawer_a(note_drawer, time, bpm)
			

					
	
static func get_modifier_name():
	return "Hidden"

# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	return "Hidden"

static func get_modifier_description():
	return "Hides notes a few moments after they spawn."
static func get_modifier_settings_class() -> Script:
	return HiddenSettings
static func get_option_settings() -> Dictionary:
	return {}
