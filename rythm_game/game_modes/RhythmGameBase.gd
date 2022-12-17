extends Node

class_name HBRhythmGameBase

signal time_changed(time)
signal song_cleared(results)
signal note_judged(judgement)
signal intro_skipped(new_time)
signal end_intro_skip_period
signal score_added(added_score)
signal show_multi_hint(new_closest_multi_notes)
signal hide_multi_hint
signal toggle_ui
signal size_changed

const GAME_DEBUG_SCENE = preload("res://rythm_game/GameDebug.tscn")
var game_debug: HBGameDebug

const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5
const MAX_NOTE_SFX = 4
const INTRO_SKIP_MARGIN = 5000 # the time before the first note we warp to when doing intro skip 

var timing_points = [] setget _set_timing_points
var note_groups := []
var finished_note_groups := []

# Note group indices sorted by end time
var note_groups_by_end_time := []
# TPs that were previously hit
var last_hit_index = 0
var result = HBResult.new()
var judge = preload("res://rythm_game/judge.gd").new()
var time: float
var current_combo = 0
var disable_intro_skip = false

# Used for normalization
var _volume_offset = 0.0

# Notes currently being shown to the user
var notes_on_screen = []
var current_song: HBSong = HBSong.new()
var current_difficulty: String = ""

# size for scaling
var size = Vector2(1280, 720) setget set_size

# editor stuff
var editing = false
var previewing = false

# Contains a dictionary that maps HBTimingPoint -> its drawer (if it has one)
var timing_point_to_drawer_map = {}

var modifiers = []

var closest_multi_notes = []

var earliest_note_time = 0

# cached values for speed
var playing_field_size
var playing_field_size_length

# If we've played an sfx in this cycle
var _sfx_played_this_cycle = false
var _intro_skip_enabled = false
# Prevents the song from finishing once
var _prevent_finishing = false
var _finished = false
var _song_volume = 0.0

var disable_ending = false

const SFX_DEBOUNCE_TIME = 0.016*2.0

var _sfx_debounce_t = SFX_DEBOUNCE_TIME
var sfx_debounce_times := {}

var audio_playback: ShinobuGodotSoundPlaybackOffset
var voice_audio_playback: ShinobuGodotSoundPlaybackOffset

var audio_remap: ShinobuChannelRemapEffect
var voice_remap: ShinobuChannelRemapEffect

var game_ui: HBRhythmGameUIBase
var game_input_manager: HBGameInputManager

var bpm_changes = {}
# sorted array of bpm changes, by time
var bpm_change_events := []

var sfx_pool := HBSoundEffectPool.new()

# Initial BPM
var base_bpm = 180.0

var current_assets

var intro_skip_marker: HBIntroSkipMarker

var cached_note_drawers = {}

var current_variant = -1

var notes_judged_this_frame = []

var section_changes = {}

var tracked_sounds := []

var autoplay_scheduled_sounds := {}

enum GAME_MODE {
	NORMAL = 0, # normal mode, requires user input to hit notes
	EDITOR_SEEK = 1, # seeking mode in the editor, you can move over notes but they aren't auto started or auto culled
	AUTOPLAY = 2 # seeking mode in the editor, you can move over notes but they aren't auto started or auto culled
}

var game_mode: int = GAME_MODE.NORMAL

func _init():
	name = "RhythmGameBase"

var _cached_notes = false

func cache_note_drawers():
	pass
#	timing_point_to_drawer_map = {}
#	_cached_notes = false
#	for group in note_groups:
#		group.reset_group()
#
#	cached_note_drawers = {}
#
#	if UserSettings.user_settings.load_all_notes_on_song_start:
#		for group in timing_points:
#			for note in group.note_datas:
#				var drawer = _create_note_drawer_impl(note)
#				cached_note_drawers[note] = drawer
#		_cached_notes = true

func _game_ready():
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	set_current_combo(0)
	
	add_child(sfx_pool)
	
	pause_mode = Node.PAUSE_MODE_STOP
	game_debug = GAME_DEBUG_SCENE.instance()
	add_child(game_debug)

func _ready():
	_game_ready()

func set_game_input_manager(manager: HBGameInputManager):
	game_input_manager = manager
	add_child(game_input_manager)
	MobileControls.set_input_manager(manager)

# TODO: generalize this
func set_chart(chart: HBChart):
	game_ui._on_reset()
	result = HBResult.new()
	current_combo = 0
	var tp = chart.get_timing_points()
	for modifier in modifiers:
		modifier._preprocess_timing_points(tp)
	_set_timing_points(tp)
	# Find slide hold chains
	result.max_score = chart.get_max_score()
	game_ui._on_chart_set(chart)

# Override this
func get_chart_from_song(song: HBSong, difficulty) -> HBChart:
	return song.get_chart_for_difficulty(difficulty)

# TODO: generalize this
func set_song(song: HBSong, difficulty: String, assets = null, _modifiers = []):
	modifiers = _modifiers
	current_song = song
	base_bpm = song.bpm
	_volume_offset = 0.0
	if audio_playback:
		audio_playback.queue_free()
	if voice_audio_playback:
		voice_audio_playback.queue_free()
	audio_playback = null
	voice_audio_playback = null
	if assets:
		current_assets = assets
		if "audio_loudness" in assets:
			_volume_offset = HBAudioNormalizer.get_offset_from_loudness(assets.audio_loudness)
		var sound_source := Shinobu.register_sound_from_memory("song", assets.audio_shinobu)
		audio_playback = ShinobuGodotSoundPlaybackOffset.new(sound_source.instantiate(HBGame.music_group, song.uses_dsc_style_channels()))
		var use_source_channel_count = song.uses_dsc_style_channels() and audio_playback.get_channel_count() >= 4
		
		if song.uses_dsc_style_channels() and not use_source_channel_count:
			audio_playback.queue_free()
			audio_playback = ShinobuGodotSoundPlaybackOffset.new(sound_source.instantiate(HBGame.music_group))
		add_child(audio_playback)
		if "voice" in assets:
			if assets.voice is AudioStream:
				var voice_sound_source := Shinobu.register_sound_from_memory("song_voice", assets.voice_shinobu)
				voice_audio_playback = ShinobuGodotSoundPlaybackOffset.new(voice_sound_source.instantiate(HBGame.music_group, use_source_channel_count))
				add_child(voice_audio_playback)
		if song.uses_dsc_style_channels() and audio_playback.get_channel_count() >= 4:
			if voice_audio_playback:
				voice_remap = Shinobu.instantiate_channel_remap(voice_audio_playback.get_channel_count(), 2)
				voice_remap.set_weight(2, 0, 1.0)
				voice_remap.set_weight(3, 1, 1.0)
				voice_remap.connect_to_group(HBGame.music_group)
				voice_audio_playback.connect_sound_to_effect(voice_remap)
			
			audio_remap = Shinobu.instantiate_channel_remap(audio_playback.get_channel_count(), 2)
			audio_remap.set_weight(0, 0, 1.0)
			audio_remap.set_weight(1, 1, 1.0)
			audio_remap.connect_to_group(HBGame.music_group)
			audio_playback.connect_sound_to_effect(audio_remap)
	else:
		var sound_source := Shinobu.register_sound_from_memory("song", song.get_audio_stream().data)
		audio_playback = ShinobuGodotSoundPlaybackOffset.new(sound_source.instantiate(HBGame.music_group))
		add_child(audio_playback)
		if song.voice:
			var voice_sound_source := Shinobu.register_sound_from_memory("song_voice", song.get_voice_stream().data)
			voice_audio_playback = ShinobuGodotSoundPlaybackOffset.new(voice_sound_source.instantiate(HBGame.music_group))
			add_child(voice_audio_playback)
	if voice_audio_playback:
		voice_audio_playback.volume = audio_playback.volume
		voice_audio_playback.offset = current_song.get_variant_data(current_variant).variant_offset
	audio_playback.offset = current_song.get_variant_data(current_variant).variant_offset
	if current_variant != -1:
		_volume_offset = song.get_variant_data(current_variant).get_volume()
	
	section_changes = {}
	for section in current_song.sections:
		section_changes[section.time] = section
	
	var chart: HBChart
	
	current_difficulty = difficulty

	chart = get_chart_from_song(song, difficulty)

	set_chart(chart)
	
	HBGame.spectrum_snapshot.set_volume(_volume_offset)
	
	if note_groups.size() > 0:
		earliest_note_time = note_groups[0].get_hit_time_msec()
	if song.allows_intro_skip and not disable_intro_skip:
		if earliest_note_time / 1000.0 > song.intro_skip_min_time:
			_intro_skip_enabled = true
		else:
			Log.log(self, "Disabling intro skip")
			_intro_skip_enabled = false
		if intro_skip_marker:
			if intro_skip_marker.time >= earliest_note_time:
				intro_skip_marker = null
	
	if current_song.id in UserSettings.user_settings.per_song_settings:
		var user_song_settings = UserSettings.user_settings.per_song_settings[current_song.id] as HBPerSongSettings
		_song_volume = song.get_volume_db() * user_song_settings.volume
	else:
		_song_volume = song.get_volume_db()
	audio_playback.volume = db2linear(_song_volume + _volume_offset)
	# todo: call ui on set song
	game_ui._on_song_set(song, difficulty, assets, modifiers)

func make_group(notes: Array, extra_notes: Array, group_position, group_time):
	var group = NoteGroup.new()
	group.notes = notes + extra_notes
	group.time = group_time
	
	var highest_time_out = 0

	for point in group.notes:
		point.set_meta("group_position", group_position)
		point.set_meta("group", group)
	var array = PoolByteArray()
	array.resize(group.notes.size())
	group.hit_notes = array
	if group.hit_notes.size() == 0:
		breakpoint
	for i in range(group.hit_notes.size()):
		group.hit_notes[i] = 0
	for note in group.notes:
		highest_time_out = max(highest_time_out, note.get_time_out(get_bpm_at_time(note.time)))
	group.precalculated_timeout = highest_time_out
	
	return group
	
func _process_timing_points_into_groups(points):
	# Group:time map
	var groups := {}
	for note in points:
		if note is HBBaseNote:
			if note is HBNoteData and note.is_slide_hold_piece():
				continue
			var group: HBNoteGroup
			if not note.time in groups:
				group = HBNoteGroup.new()
				group.game = self
				group.connect("notes_judged", self, "_on_notes_judged_new")
				groups[note.time] = group
			else:
				group = groups[note.time]
			group.add_note_to_group(note)
	return groups.values()
func get_time_to_intro_skip_to():
	if intro_skip_marker:
		return intro_skip_marker.time
	else:
		return earliest_note_time - INTRO_SKIP_MARGIN
	
func _sort_groups_by_end_time(a, b):
	return a.get_end_time_msec() < b.get_end_time_msec()
	
func _sort_notes_by_time(a: HBTimingPoint, b: HBTimingPoint):
	return a.time < b.time
	
func _set_timing_points(points):
	for point in timing_points:
		if point is NoteGroup:
			for note in point.notes:
				if note.has_meta("group"):
					note.remove_meta("group")
	timing_points = points
	timing_points.sort_custom(self, "_sort_notes_by_time")
	
	# When timing points change, we might introduce new BPM change events
	bpm_change_events.clear()
	intro_skip_marker = null
	
	for point in timing_points:
		if point is HBBPMChange:
			bpm_change_events.append(point)
		if point is HBIntroSkipMarker:
			intro_skip_marker = point
	bpm_change_events.sort_custom(self, "_sort_notes_by_time")
	
	note_groups = _process_timing_points_into_groups(points)
	note_groups_by_end_time = note_groups.duplicate()
	note_groups_by_end_time.sort_custom(self, "_sort_groups_by_end_time")
	
	last_hit_index = timing_points.size()
	remove_all_notes_from_screen()

var bpm_bsearch := HBBPMChange.new()

func get_bpm_at_time(bpm_time):
	if bpm_change_events.size() == 0:
		return base_bpm
		
	bpm_bsearch.time = bpm_time
	var bpm_i := bpm_change_events.bsearch_custom(bpm_bsearch, self, "_sort_notes_by_time")
	bpm_i = max(0, bpm_i-1)
	
	var bpm: HBBPMChange = bpm_change_events[bpm_i]
	if bpm.time > bpm_time:
		return base_bpm
	
	return bpm_change_events[bpm_i].bpm

func get_section_at_time(section_time):
	var current_time = null
	for c_t in section_changes:
		if (current_time == null and c_t <= section_time) or (c_t <= section_time and c_t > current_time):
			current_time = c_t
	
	return section_changes[current_time] if current_time else null

func _sort_notes_by_appear_time(a: HBTimingPoint, b: HBTimingPoint):
	var ta = 0
	var tb = 0
	
	if a is HBBaseNote:
		ta = a.get_time_out(get_bpm_at_time(a.time))
	if b is HBBaseNote:
		tb = b.get_time_out(get_bpm_at_time(b.time))
	
	return (a.time - ta) > (b.time - tb)

# Stores playing field size in memory to mape remap_coords faster
func cache_playing_field_size():
	var ratio = size.x / size.y
	if ratio < 16.0/9.0:
		playing_field_size = Vector2(size.x, size.x * 9/16.0)
	else:
		playing_field_size = Vector2(size.y * 16.0/9.0, size.y)
	playing_field_size_length = playing_field_size.length()

# Called when the game size is changed
func set_size(value):
	size = value
	cache_playing_field_size()

func _on_viewport_size_changed():
	cache_playing_field_size()
	emit_signal("size_changed")

var _on_frame = false

var handled_event_uids_this_frame := []
var unhandled_input_events_this_frame := []

func _process_input(event):
	if event.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.UP][0]) or event.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.LEFT][0]):
		if Input.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.UP][0]) and Input.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.LEFT][0]):
			if current_song.allows_intro_skip and _intro_skip_enabled:
				if time*1000.0 < get_time_to_intro_skip_to():
					_intro_skip_enabled = false
					seek(get_time_to_intro_skip_to())
					start()
					# call ui on intro skip
					emit_signal("intro_skipped", get_time_to_intro_skip_to() / 1000.0)
	if event is InputEventHB and not game_mode == GAME_MODE.EDITOR_SEEK:
		var input_handled := false
		for group in current_note_groups:
			if group.process_input(event):
				input_handled = true
				handled_event_uids_this_frame.append(event.event_uid)
				break
		if not input_handled:
			unhandled_input_events_this_frame.append(event)
func _input(event):
	_process_input(event)

func _group_compare_start(a, b):
	var a_time: int
	var b_time: int
	
	if a is HBNoteGroup:
		a_time = a.get_start_time_msec()
	else:
		a_time = a
		
	if b is HBNoteGroup:
		b_time = b.get_start_time_msec()
	else:
		b_time = b
	
	return a_time < b_time

func _group_compare_end(a, b):
	var a_time: int
	var b_time: int
	
	if a is HBNoteGroup:
		a_time = a.get_end_time_msec()
	else:
		a_time = a
		
	if b is HBNoteGroup:
		b_time = b.get_end_time_msec()
	else:
		b_time = b
	
	return a_time < b_time

# A possibility for note groups that are close together is that because of a big lag spike or frame rules
# we might just skip a complete group in that case it's preferrable to still process that group anyways
# even if it's just gonna give us a WORST
# so that score calculations continue to work fine
# Setting this to -1 will disable this system for a frame and instead cull from whatever group is the first after the current time
var last_culled_note_group := -1

# List of note groups that should be processed
var current_note_groups := []

func _sort_groups_by_hit_time(a, b):
	return a.get_hit_time_msec() < b.get_hit_time_msec()

func _process_groups():
	if note_groups.size() == 0:
		return
	var time_msec := int(time * 1000.0)
	# Find the first group that is still alive in our window
	var final_search_point := note_groups.bsearch_custom(time_msec, self, "_group_compare_start", false)
	var first_search_point := note_groups_by_end_time.bsearch_custom(time_msec, self, "_group_compare_end", true)
	if first_search_point == note_groups_by_end_time.size():
		first_search_point -= 1
	first_search_point = note_groups.find(note_groups_by_end_time[first_search_point])
	
	if last_culled_note_group != -1:
		first_search_point = min(first_search_point, last_culled_note_group)
	
	var group_order_dirty := false
	for i in range(first_search_point, final_search_point):
		var group := note_groups[i] as HBNoteGroup
		if not group in current_note_groups and not group in finished_note_groups:
			if group.get_start_time_msec() <= time_msec and group.get_end_time_msec() >= time_msec:
				current_note_groups.append(group)
				if OS.has_feature("editor"):
					game_debug.track_group(group)
				group_order_dirty = true
	
	if group_order_dirty:
		current_note_groups.sort_custom(self, "_sort_groups_by_start_time")
		
	last_culled_note_group = final_search_point-1
	
	for i in range(current_note_groups.size()-1, -1, -1):
		var note_group := current_note_groups[i] as HBNoteGroup
		if note_group.process_group(time_msec):
			current_note_groups.erase(note_group)
			finished_note_groups.append(note_group)
			game_debug.untrack_group(note_group)

# We need to split _process into it's own function so we can override it because
# godot is stupid and calls _process on both parent and child
func _process_game(_delta):
	_sfx_debounce_t += _delta
	var latency_compensation = UserSettings.user_settings.lag_compensation
	if current_song.id in UserSettings.user_settings.per_song_settings:
		latency_compensation += UserSettings.user_settings.per_song_settings[current_song.id].lag_compensation

	if (not editing or previewing) and audio_playback:
		time = audio_playback.get_playback_position_msec() / 1000.0
		time -= latency_compensation / 1000.0

		if not editing:
			var end_time = audio_playback.get_length_msec() + audio_playback.offset
			if current_song.end_time > 0:
				end_time = min(end_time, float(current_song.end_time))

			if audio_playback.get_playback_position_msec() >= end_time or audio_playback.is_at_stream_end() and not _finished:
				_on_game_finished()
	
	_process_groups()
	
	for i in range(tracked_sounds.size()-1, -1, -1):
		var sound := tracked_sounds[i] as ShinobuSoundPlayer
		if sound.is_at_stream_end():
			tracked_sounds.remove(i)
			sound.queue_free()
	
	for i in range(current_note_groups.size()):
		var group = current_note_groups[i] as HBNoteGroup
		# Ignore timing points that are not happening now
		var start_time_msec := group.get_start_time_msec() as int
		if time * 1000.0 < start_time_msec:
			break
		if time * 1000.0 >= start_time_msec:
			for modifier in modifiers:
				if modifier.processing_notes:
					var drawers = []
					for note in group.note_datas:
						var drw = group.note_drawers.get(note, null)
						if drw:
							drawers.append(drw)
					modifier._process_note(drawers, time, get_bpm_at_time(time))
	emit_signal("time_changed", time)
	
	var new_closest_multi_notes = []
	var last_note_time = 0
	for group in current_note_groups:
		if group.note_datas.size() > 1:
			new_closest_multi_notes = group.note_datas
			break
	if UserSettings.user_settings.enable_multi_hint:
		if new_closest_multi_notes.size() > 1:
			if not new_closest_multi_notes[0] in closest_multi_notes:
				closest_multi_notes = new_closest_multi_notes
				emit_signal("show_multi_hint", new_closest_multi_notes)
#				hold_hint.show()
		
	if new_closest_multi_notes.size() < 2:
		emit_signal("hide_multi_hint")
		
	closest_multi_notes = new_closest_multi_notes
	if _intro_skip_enabled:
		if time*1000.0 >= get_time_to_intro_skip_to():
			emit_signal("end_intro_skip_period")
			_intro_skip_enabled = false
			
	for event in unhandled_input_events_this_frame:
		_play_empty_note_sound(event)

	unhandled_input_events_this_frame.clear()
	handled_event_uids_this_frame.clear()
	
	for sound_name in sfx_debounce_times:
		sfx_debounce_times[sound_name] -= _delta
		if sfx_debounce_times[sound_name] <= 0.0:
			sfx_debounce_times.erase(sound_name)
func _pre_process_game():
	game_input_manager.flush_inputs()

func _process(delta):
	_pre_process_game()
	_process_game(delta)
	notes_judged_this_frame = []
	game_input_manager._frame_end()


func toggle_ui():
	emit_signal("toggle_ui")

func set_current_combo(combo: int):
	current_combo = combo

# removes a note from screen (and from the timing points list if not in the editor)
func remove_note_from_screen(i, update_last_hit = true):
	if i != -1:
		if update_last_hit:
			if notes_on_screen[i].has_meta("group_position"):
				var group = notes_on_screen[i].get_meta("group")
				group.hit_notes[group.notes.find(notes_on_screen[i])] = 1
		var drawer = get_note_drawer(notes_on_screen[i])
		game_ui.get_notes_node().remove_child(drawer)
		if is_connected("time_changed", drawer, "_on_game_time_changed"):
			disconnect("time_changed", drawer, "_on_game_time_changed")
		notes_on_screen.remove(i)

# Used by editor to reset hit notes and allow them to appear again
func reset_hit_notes():
	last_hit_index = timing_points.size()
	for group in timing_points:
		var array = PoolByteArray()
		array.resize(group.notes.size())
		for i in range(array.size()):
			array.set(i, 0)
		group.hit_notes = array

func delete_rogue_notes(pos = time):
	pass
		
func restart():
	var max_score := result.max_score as int
	_prevent_finishing = true
	get_tree().paused = false
	time = current_song.start_time / 1000.0
	game_ui._on_reset()
	seek_new(current_song.start_time, true)
	
	result = HBResult.new()
	current_combo = 0
	# Find slide hold chains
	result.max_score = max_score
	
	cache_note_drawers()
	timing_point_to_drawer_map = {}
	if voice_audio_playback:
		voice_audio_playback.volume = db2linear(_song_volume + _volume_offset)
		voice_audio_playback.stop()
	set_current_combo(0)
	audio_playback.stop()
	game_input_manager.reset()
	autoplay_scheduled_sounds.clear()

			
func _on_note_removed(note):
	remove_note_from_screen(notes_on_screen.find(note))

func pause_game():
	audio_playback.stop()
	if voice_audio_playback:
		voice_audio_playback.stop()

func resume():
	start()
func seek(position: int):
	audio_playback.seek(position)
	if voice_audio_playback:
		voice_audio_playback.seek(position)
	
func start():
	audio_playback.start()
	if voice_audio_playback:
		voice_audio_playback.start()
	
func schedule_play_start(global_time: int):
	audio_playback.schedule_start_time(global_time)
	audio_playback.start()
	if voice_audio_playback:
		voice_audio_playback.schedule_start_time(global_time)
		voice_audio_playback.start()
	
func play_from_pos(position: float):
	audio_playback.offset = current_song.get_variant_data(current_variant).variant_offset
	if voice_audio_playback:
		voice_audio_playback.offset = current_song.get_variant_data(current_variant).variant_offset
	audio_playback.schedule_start_time(0)
	audio_playback.seek(position * 1000.0)
	audio_playback.start()
	time = position
func add_score(score_to_add):
	if not previewing:
		result.score += score_to_add
		emit_signal("score_added", score_to_add)
		
func _on_game_finished():
	if not _finished:
		if not disable_ending:
			if not _prevent_finishing:
				for modifier in modifiers:
					modifier._post_game(current_song, self)
				emit_signal("song_cleared", result)
				_finished = true
			else:
				_prevent_finishing = false

# Connects multi notes to their respective master notes
func hookup_multi_notes(notes: Array):
	for note in notes:
		var note_drawer = get_note_drawer(note)
		note_drawer.connected_notes = notes
		note_drawer.note_master = false
	get_note_drawer(notes[0]).note_master = true

# returns the note drawer for the given timing point
func get_note_drawer(timing_point):
	var drawer = null
	if timing_point_to_drawer_map.has(timing_point):
		drawer = timing_point_to_drawer_map[timing_point]
	return drawer
		
func remove_all_notes_from_screen():
	notes_on_screen = []
	for point in timing_point_to_drawer_map:
		if point in timing_point_to_drawer_map:
			if timing_point_to_drawer_map[point]:
				if not timing_point_to_drawer_map[point].is_queued_for_deletion():
					if _cached_notes:
						cached_note_drawers.erase(point)
					timing_point_to_drawer_map[point].free()
	timing_point_to_drawer_map = {}
	
func get_closest_notes():
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = get_note_drawer(note_c).note_data
		if note is HBSustainNote and get_note_drawer(note_c).pressed:
			continue
		if closest_notes.size() > 0:
			if closest_notes[0].time > note.time:
				closest_notes = [note]
			elif note.time == closest_notes[0].time:
				closest_notes.append(note)
		else:
			closest_notes = [note]
	return closest_notes
	
func get_closest_notes_of_type(note_type: int) -> Array:
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = get_note_drawer(note_c).note_data
		if note.note_type == note_type:
			if closest_notes.size() > 0:
				if closest_notes[0].time > note.time:
					closest_notes = [note]
				elif note.time == closest_notes[0].time:
					closest_notes.append(note)
			else:
				closest_notes = [note]
	return closest_notes

func get_note_scale():
	return UserSettings.user_settings.note_size * ((playing_field_size_length / BASE_SIZE.length()) * 0.95)


func remap_coords(coords: Vector2):
	coords = coords / BASE_SIZE
	var pos = coords * playing_field_size
	var ratio = size.x / size.y
	if ratio > 16.0/9.0:
		coords.x = (size.x - playing_field_size.x) * 0.5 + pos.x
		coords.y = pos.y
	else:
		coords.x = pos.x
		coords.y = (size.y - playing_field_size.y) * 0.5 + pos.y
	return coords
func inv_map_coords(coords: Vector2):
	var x = (coords.x - ((size.x - playing_field_size.x) / 2.0)) / playing_field_size.x * BASE_SIZE.x
	var y = (coords.y - ((size.y - playing_field_size.y) / 2.0)) / playing_field_size.y * BASE_SIZE.y
	return Vector2(x, y)

func _create_note_drawer_impl(timing_point: HBBaseNote):
	var note_drawer
	note_drawer = timing_point.get_drawer().instance()
	note_drawer.game = self
	note_drawer.note_data = timing_point
	note_drawer._note_init()
	game_ui.get_notes_node().add_child(note_drawer)
	game_ui.get_notes_node().remove_child(note_drawer)
	return note_drawer
	
func bsearch_time(a, b):
	return a.time < b.time
	
# creates and connects a new note drawer
func create_note_drawer(timing_point: HBBaseNote):
	var note_drawer
	if not _cached_notes:
		note_drawer = _create_note_drawer_impl(timing_point)
	else:
		note_drawer = cached_note_drawers[timing_point]
	game_ui.get_notes_node().add_child(note_drawer)
	note_drawer.connect("notes_judged", self, "_on_notes_judged")
	note_drawer.connect("note_removed", self, "_on_note_removed", [timing_point])
	if timing_point in timing_point_to_drawer_map:
		if not timing_point_to_drawer_map[timing_point].is_queued_for_deletion():
			timing_point_to_drawer_map[timing_point].free()
			timing_point_to_drawer_map.erase(timing_point)
	timing_point_to_drawer_map[timing_point] = note_drawer
	var pos = notes_on_screen.bsearch_custom(timing_point, self, "bsearch_time")
	notes_on_screen.insert(pos, timing_point)
	connect("time_changed", note_drawer, "_on_game_time_changed")
	return note_drawer
func set_game_ui(ui: HBRhythmGameUIBase):
	game_ui = ui
	ui.game = self
	connect("note_judged", ui, "_on_note_judged")
	connect("intro_skipped", ui, "_on_intro_skipped")
	connect("end_intro_skip_period", ui, "_on_end_intro_skip_period")
	connect("score_added", ui, "_on_score_added")
	connect("toggle_ui", ui, "_on_toggle_ui")
	connect("hide_multi_hint", ui, "_on_hide_multi_hint")
	connect("show_multi_hint", ui, "_on_show_multi_hint")

func _play_empty_note_sound(event: InputEventHB):
	if event.is_pressed():
		if not event.event_uid in handled_event_uids_this_frame:
			if event.action in ["slide_left", "slide_right", "heart_note"]:
				sfx_pool.play_sfx("slide_empty")
			elif not event.action == "heart_note":
				sfx_pool.play_sfx("note_hit")

# called when a note or group of notes is judged
# this doesn't take care of adding the score
# todo: generalize this

func _on_notes_judged_new(final_judgement: int, judgements: Array, judgement_target_time: int, wrong: bool):
	var avg_pos := Vector2.ZERO
	for judgement in judgements:
		avg_pos += judgement.note_data.position
	avg_pos /= float(judgements.size())

	if final_judgement < judge.JUDGE_RATINGS.FINE or wrong:
		# Missed a note
		if final_judgement < judge.JUDGE_RATINGS.SAFE:
			if UserSettings.user_settings.enable_voice_fade:
				if voice_audio_playback:
					voice_audio_playback.volume = 0.0
		set_current_combo(0)
	else:
		set_current_combo(current_combo+1)
		if voice_audio_playback:
			voice_audio_playback.volume = db2linear(_song_volume + _volume_offset)
		result.notes_hit += 1
	if not wrong:
		result.note_ratings[final_judgement] += 1
	else:
		result.wrong_note_ratings[final_judgement] += 1

	result.total_notes += 1

	if current_combo > result.max_combo:
		result.max_combo = current_combo
		
	var judgement_info = {"judgement": final_judgement, "target_time": judgement_target_time, "time": int(time * 1000), "wrong": wrong, "avg_pos": avg_pos}
	emit_signal("note_judged", judgement_info)

func _on_notes_judged(notes: Array, judgement, wrong):
	#print("JUDGED %d notes, with judgement %d %s" % [notes.size(), judgement, str(wrong)])
	
	# Simultaneous slides are a special case...
	# we have to process each note individually
#	for n in notes:
#		if n is HBNoteData:
#			if n != note and n.is_slide_note():
#				_on_notes_judged([n], judgement, wrong)
	# Some notes might be considered more than 1 at the same time? connected ones aren't
	notes_judged_this_frame += notes

	var notes_hit = 1
	if not editing or previewing:
		# Rating graphic
		if judgement < judge.JUDGE_RATINGS.FINE or wrong:
			# Missed a note
			if judgement < judge.JUDGE_RATINGS.SAFE:
				if UserSettings.user_settings.enable_voice_fade:
					if voice_audio_playback:
						voice_audio_playback.volume = 0.0
			set_current_combo(0)
		else:
			set_current_combo(current_combo + notes_hit)
			if voice_audio_playback:
				voice_audio_playback.volume = db2linear(_song_volume + _volume_offset)
			result.notes_hit += notes_hit

		if not wrong:
			result.note_ratings[judgement] += notes_hit
		else:
			result.wrong_note_ratings[judgement] += notes_hit

		result.total_notes += notes_hit

		if current_combo > result.max_combo:
			result.max_combo = current_combo

		# We average the notes position so that multinote ratings are centered
		var avg_pos = Vector2()
		for n in notes:
			avg_pos += n.position
		avg_pos = avg_pos / float(notes.size())

		var target_time = notes[0].time
		var drawer = get_note_drawer(notes[0])
		if notes[0] is HBSustainNote and drawer.pressed:
			target_time = notes[0].end_time

		var judgement_info = {"judgement": judgement, "target_time": target_time, "time": int(time * 1000), "wrong": wrong, "avg_pos": avg_pos}

		emit_signal("note_judged", judgement_info)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		var shit_to_delete = [timing_point_to_drawer_map]
		if _cached_notes:
			shit_to_delete = [cached_note_drawers]
		for c in shit_to_delete:
			for note in c:
				if not c[note].is_queued_for_deletion():
					c[note].queue_free()

# Tracks a sound and auto frees it when its finished
func track_sound(sound: ShinobuSoundPlayer):
	add_child(sound)
	tracked_sounds.append(sound)

func untrack_sound(sound: ShinobuSoundPlayer):
	remove_child(sound)
	tracked_sounds.erase(sound)

func seek_new(new_position_msec: int, reset_notes := false):
	var new_position_secs := new_position_msec * 0.001
	autoplay_scheduled_sounds.clear()
	seek(new_position_msec)
	time = new_position_secs
	if reset_notes:
		last_culled_note_group = -1
		for group in current_note_groups:
			# Only need to kill groups that aren't in range
			if group.get_end_time_msec() < new_position_msec or group.get_start_time_msec() > new_position_msec:
				group.reset_group()
		for group in finished_note_groups:
			group.reset_group()
		current_note_groups.clear()
		finished_note_groups.clear()

func _group_compare_hit(a, b):
	var a_time: int
	var b_time: int
	
	if a is HBNoteGroup:
		a_time = a.get_hit_time_msec()
	else:
		a_time = a
		
	if b is HBNoteGroup:
		b_time = b.get_hit_time_msec()
	else:
		b_time = b
	
	return a_time < b_time

func editor_add_timing_point(point: HBTimingPoint):
	if point is HBBaseNote:
		var note_data: HBBaseNote = point
		var group_i := note_groups.bsearch_custom(note_data.time, self, "_group_compare_hit")
		
		var group: HBNoteGroup
		
		if group_i < note_groups.size():
			var candidate_group := note_groups[group_i] as HBNoteGroup
			if candidate_group.get_hit_time_msec() == note_data.time:
				group = candidate_group
		if not group:
			group = HBNoteGroup.new()
			group.game = self
			note_groups.insert(group_i, group)
			note_groups_by_end_time.append(group)
		
		group.note_datas.append(note_data)
		group.reset_group()
		
		note_data.set_meta("editor_group", group)
		
		note_groups.sort_custom(self, "_sort_groups_by_start_time")
		note_groups_by_end_time.sort_custom(self, "_sort_groups_by_end_time")
		last_culled_note_group = -1
	else:
		if point is HBBPMChange:
			bpm_change_events.insert(bpm_change_events.bsearch_custom(point, self, "_sort_notes_by_time"), point)
		else:
			print("TODO: Handle addition of non note timing points")

func editor_remove_timing_point(point: HBTimingPoint):
	if point is HBBaseNote:
		var note_data: HBBaseNote = point
		var group_i := note_groups.bsearch_custom(note_data.time, self, "_group_compare_hit")
		
		var group: HBNoteGroup
		
		if group_i < note_groups.size():
			var candidate_group := note_groups[group_i] as HBNoteGroup
			if candidate_group.get_hit_time_msec() == note_data.time:
				group = candidate_group
		if group:
			group.note_datas.erase(note_data)
			group.reset_group()
			if group.note_datas.size() == 0:
				note_groups.erase(group)
				note_groups_by_end_time.erase(group)

		note_data.set_meta("editor_group", null)

		last_culled_note_group = -1
	else:
		if point is HBBPMChange:
			bpm_change_events.erase(point)
		else:
			print("TODO: Handle removal of non note timing points")

func editor_clear_notes():
	note_groups.clear()
	last_culled_note_group = -1

func notify_rollback():
	for group in note_groups:
		group.notify_rollback()

func is_sound_debounced(sound_name: String):
	return sound_name in sfx_debounce_times

func debounce_sound(sound_name: String):
	sfx_debounce_times[sound_name] = SFX_DEBOUNCE_TIME
