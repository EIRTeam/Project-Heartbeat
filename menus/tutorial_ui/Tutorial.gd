extends Control

class_name HBTutorial

@onready var game_controller: HBRhythmGameController = %RhythmGame

var tutorial_events: Array[HBTutorialEvent]
var assets: SongAssetLoader.AssetLoadToken

const TUTORIAL_START_TIME := 1658
const TUTORIAL_TIMING_REF_TIME := 4858
const EVENT_INTERVAL := 3200

func _setup_common_chart_elements(chart_generator: HBTutorialChartGenerator):
	
	chart_generator.seek_to(TUTORIAL_START_TIME)

	# Start
	chart_generator.add_section("tutorial_start")
	
	# Showing basic notes
	chart_generator.advance_time(EVENT_INTERVAL*3)
	chart_generator.add_section("basic_notes")
	
	# D-pad demo
	chart_generator.advance_time(EVENT_INTERVAL*3)
	chart_generator.add_section("dpad_explanation")
	
	# Basic notes
	chart_generator.advance_time(EVENT_INTERVAL*3)
	chart_generator.add_note(HBBaseNote.NOTE_TYPE.UP)
	chart_generator.advance_time(EVENT_INTERVAL)
	chart_generator.add_note(HBBaseNote.NOTE_TYPE.LEFT)
	chart_generator.advance_time(EVENT_INTERVAL)
	chart_generator.add_note(HBBaseNote.NOTE_TYPE.DOWN)
	chart_generator.advance_time(EVENT_INTERVAL)
	chart_generator.add_note(HBBaseNote.NOTE_TYPE.RIGHT)
	chart_generator.advance_time(EVENT_INTERVAL)

func _generate_console_tutorial_chart() -> HBChart:
	var chart_generator := HBTutorialChartGenerator.new(TUTORIAL_TIMING_REF_TIME, 150.0)
	_setup_common_chart_elements(chart_generator)
	
	return chart_generator.chart

func initialize(_assets: SongAssetLoader.AssetLoadToken):
	assets = _assets
	game_controller.prevent_scene_changes = true
	game_controller.prevent_showing_results = true
	_generate_console_tutorial_chart()
