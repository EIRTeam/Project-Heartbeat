extends HBMenu

@onready var offset_label = get_node("MarginContainer/VBoxContainer/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/OffsetLabel")
@onready var rhythm_game = get_node("MarginContainer/VBoxContainer/EmbeddedRhythmGame")
@onready var tutorial_popup = get_node("TutorialPopup")
@onready var substract_button = get_node("MarginContainer/VBoxContainer/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/SubstractButton")
@onready var add_button = get_node("MarginContainer/VBoxContainer/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/AddButton")
@onready var next_test_button = get_node("MarginContainer/VBoxContainer/MarginContainer2/MarginContainer/VBoxContainer/HBoxContainer2/ChangeTestButton")
@onready var add_button_prompt = get_node("MarginContainer/VBoxContainer/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/PromptInputAction2")
@onready var substract_button_prompt = get_node("MarginContainer/VBoxContainer/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/PromptInputAction")

var offset := 0
var player: ShinobuSoundPlayer
var mode = 0
const PREVIOUS_MENU = "tools_menu"
const tutorials = [
	"""
	Passive test:
	Adjust the offset to the left or right
	until it feels on-beat.
	Click apply to apply the offset.
	""",
	"""
	Active test:
	Press the button to the beat
	and an offset will be calculated.
	Click apply to apply the offset.
	"""
]
const next_test = [
	"Active test",
	"Passive test"
]

signal pause_background_player
signal resume_background_player


func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	
	UserSettings.enable_menu_fps_limits = false
	
	emit_signal("pause_background_player")
	
	mode = 0
	
	offset = UserSettings.user_settings.lag_compensation
	update_latency()
	
	var pattern = {
		"layers": [
			{
				"name": "LEFT",
				"timing_points": [
					{
						"time": 0,
						"note_type": HBNoteData.NOTE_TYPE.LEFT,
						"type": "Note"
					}
				]
			}
		],
		"repeat": 592,
		"spacing": 500
	}
	var loudness = HBAudioLoudnessCacheEntry.new()
	loudness.loudness = -29.576157
	var song = HBAutoSong.new(
		pattern,
		"res://tools/latency_tester/metronome.ogg",
		-29.576157,
		1000
	)
	
	rhythm_game.rhythm_game.audio_playback = null
	
	if player:
		player.queue_free()
	
	var sound_source := HBGame.register_sound_from_path("latency_tester_song", song.audio_path) as ShinobuSoundSource
	
	player = sound_source.instantiate(HBGame.music_group)
	player.volume = db_to_linear(HBAudioNormalizer.get_offset_from_loudness(song.loudness))
	add_child(player)
	
	rhythm_game.set_audio(player, null)
	rhythm_game.play_song(song, song.chart)
	
	update_mode()

func update_mode():
	substract_button.visible = (mode == 0)
	add_button.visible = (mode == 0)
	add_button_prompt.visible = (mode == 0)
	substract_button_prompt.visible = (mode == 0)
	
	tutorial_popup.text = tutorials[mode]
	next_test_button.button_text = next_test[mode]
	
	Diagnostics.autoplay_checkbox.button_pressed = (mode == 0)
	
	rhythm_game.restart()


func update_latency():
	var offset_text = "%s ms" % offset
	if offset > 0:
		offset_text = "+" + offset_text
	offset_text = " " + offset_text
	
	offset_label.text = offset_text


func _on_SubstractButton_pressed():
	offset -= 1
	update_latency()


func _on_AddButton_pressed():
	offset += 1
	update_latency()


func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		get_viewport().set_input_as_handled()
		_on_BackButton_pressed()
	if event.is_action_pressed("gui_left", true):
		_on_SubstractButton_pressed()
	if event.is_action_pressed("gui_right", true):
		_on_AddButton_pressed()
	if event.is_action_pressed("practice_go_to_waypoint"):
		_on_ResetButton_pressed()
	if event.is_action_pressed("gui_accept"):
		_on_ApplyButton_pressed()
	if event.is_action_pressed("contextual_option"):
		_on_TutorialButton_pressed()
	if event.is_action_pressed("practice_set_waypoint"):
		_on_ChangeTestButton_pressed()

func _on_menu_exit(force_hard_transition = false):
	super._on_menu_exit(force_hard_transition)
	player.stop()
	emit_signal("resume_background_player")
	Diagnostics.autoplay_checkbox.button_pressed = false
	UserSettings.enable_menu_fps_limits = true


func _on_ApplyButton_pressed():
	UserSettings.user_settings.lag_compensation = offset
	rhythm_game.restart()
	UserSettings.save_user_settings()

func _on_ResetButton_pressed():
	offset = UserSettings.user_settings.lag_compensation
	update_latency()
	rhythm_game.restart()
	UserSettings.save_user_settings()

func _on_BackButton_pressed():
	change_to_menu(PREVIOUS_MENU)


func _on_ChangeTestButton_pressed():
	mode = 0 if mode else 1
	update_mode()


func _on_TutorialButton_pressed():
	rhythm_game.pause()
	tutorial_popup.popup_centered()

func _on_TutorialPopup_hide():
	rhythm_game.resume()
	rhythm_game.restart()


func _on_stats_changed():
	if mode == 1:
		if rhythm_game.stats_passed_notes > 0:
			offset = rhythm_game.stats_latency_sum / float(rhythm_game.stats_passed_notes)
			update_latency()

