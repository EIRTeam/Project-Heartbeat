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
signal ui_toggled
signal size_changed

const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5
const MAX_NOTE_SFX = 4
const INTRO_SKIP_MARGIN = 5000 # the time before the first note we warp to when doing intro skip 

var timing_points = []: set = _set_timing_points
var note_groups := []
var finished_note_groups := []

# Note group indices sorted by end time
var note_groups_by_end_time := []
# TPs that were previously hit
var result = HBResult.new()
var judge = preload("res://rythm_game/judge.gd").new()
var time_msec: int
var current_combo = 0
var disable_intro_skip = false

# Used for normalization
var _volume_offset = 0.0

var current_song: HBSong = HBSong.new()
var current_difficulty: String = ""

# size for scaling
var size = Vector2(1280, 720): set = set_size

# editor stuff
var editing = false
var previewing = false

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

var bpm_changes := []
var bpm_map := {}

var sfx_pool := HBSoundEffectPool.new()

var current_assets: SongAssetLoader.AssetLoadToken

var intro_skip_marker: HBIntroSkipMarker

var cached_note_drawers = {}

var current_variant = -1

var notes_judged_this_frame = []

var section_changes := {}
var timing_changes := []: set = set_timing_changes

var tracked_sounds := []

var autoplay_scheduled_sounds := {}

var sfx_enabled := true

# Note from Lino to Eir:
# If you ever see this, please write the autoplay description
# You forgor 💀💀💀💀💀:skull:
enum GAME_MODE {
	NORMAL = 0, # normal mode, requires user input to hit notes
	EDITOR_SEEK = 1, # seeking mode in the editor, you can move over notes but they aren't auto started or auto culled
	AUTOPLAY = 2 # seeking mode in the editor, you can move over notes but they aren't auto started or auto culled
}

var game_mode: int = GAME_MODE.NORMAL

func _init():
	name = "RhythmGameBase"

var _cached_notes = false

func _game_ready():
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	_on_viewport_size_changed()
	set_current_combo(0)
	
	add_child(sfx_pool)
	
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _ready():
	_game_ready()

func set_game_input_manager(manager: HBGameInputManager):
	game_input_manager = manager
	add_child(game_input_manager)

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
func set_song(song: HBSong, difficulty: String, assets: SongAssetLoader.AssetLoadToken = null, _modifiers = []):
	modifiers = _modifiers
	current_song = song
	_volume_offset = 0.0
	if audio_playback:
		audio_playback.queue_free()
	if voice_audio_playback:
		voice_audio_playback.queue_free()
	audio_playback = null
	voice_audio_playback = null
	if assets:
		current_assets = assets
		var loudness := assets.get_asset(SongAssetLoader.ASSET_TYPES.AUDIO_LOUDNESS) as SongAssetLoader.AudioNormalizationInfo
		if loudness:
			_volume_offset = HBAudioNormalizer.get_offset_from_loudness(loudness.loudness)
		else:
			var song_loudness := 0.0
			if SongDataCache.is_song_audio_loudness_cached(song):
				song_loudness = SongDataCache.audio_normalization_cache[song.id].loudness
			elif song.has_audio_loudness:
				song_loudness = song.audio_loudness
			_volume_offset = HBAudioNormalizer.get_offset_from_loudness(song_loudness)
		var audio_data := assets.get_asset(SongAssetLoader.ASSET_TYPES.AUDIO) as SongAssetLoader.SongAudioData
		var sound_source := audio_data.shinobu
		audio_playback = ShinobuGodotSoundPlaybackOffset.new(sound_source.instantiate(HBGame.music_group, song.uses_dsc_style_channels()))
		var use_source_channel_count = song.uses_dsc_style_channels() and audio_playback.get_channel_count() >= 4
		
		if song.uses_dsc_style_channels() and not use_source_channel_count:
			audio_playback.queue_free()
			audio_playback = ShinobuGodotSoundPlaybackOffset.new(sound_source.instantiate(HBGame.music_group))
		add_child(audio_playback)
		var voice_audio_data := assets.get_asset(SongAssetLoader.ASSET_TYPES.VOICE) as SongAssetLoader.SongAudioData
		if voice_audio_data:
			var voice_sound_source := voice_audio_data.shinobu
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
	
	# Note for future people looking at this codebase (probably me or eir)
	# Do NOT, I repeat, do NOT change the order of things here. It should
	# be precisely:
	#	1- deserialize the chart (via get_chart_from_song)
	#	2- get sections and timing changes
	#	3- call set_chart
	#
	# This is because deserializing a V1 chart modifies the song meta in-memory
	# to create a new placeholder tempo map. So the chart has to get deserialized
	# before we can touch the tempo map, just in case. But calling set_chart uses
	# these timing changes, so it has to be done after we load them.
	# A wrong loading order manifests as an empty tempo map (0bpm) under corner
	# cases, like when "show note types before playing" is disabled. 
	# If you have to chase this bug again, Im sorry.
	# 
	# - Lino, 02/03/23
	
	var chart: HBChart
	current_difficulty = difficulty
	chart = get_chart_from_song(song, difficulty)
	
	section_changes = {}
	for section in current_song.sections:
		section_changes[section.time] = section
	
	timing_changes = current_song.timing_changes.duplicate()
	timing_changes.sort_custom(Callable(self, "_sort_notes_by_time"))
	
	# Fallback
	if not timing_changes:
		var placeholder_timing_change = HBTimingChange.new()
		placeholder_timing_change.bpm = song.bpm
		
		timing_changes = [placeholder_timing_change]
	
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
	audio_playback.volume = db_to_linear(_song_volume + _volume_offset)
	# If I understand correctly, diva songs that use two channels have half the volume because they are played twice
	if song is SongLoaderDSC.HBSongMMPLUS and audio_playback.get_channel_count() <= 2:
		audio_playback.volume *= 2
	game_ui._on_song_set(song, difficulty, assets, modifiers)

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
				group.connect("notes_judged", Callable(self, "_on_notes_judged_new"))
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
	
func _sort_groups_by_start_time(a, b):
	return a.get_end_time_msec() < b.get_end_time_msec()
	
func _sort_groups_by_end_time(a, b):
	return a.get_end_time_msec() < b.get_end_time_msec()

func _set_timing_points(points):
	for point in timing_points:
		if point is NoteGroup:
			for note in point.notes:
				if note.has_meta("group"):
					note.remove_meta("group")
	
	timing_points = points
	timing_points.sort_custom(Callable(self, "_sort_notes_by_time"))
	
	# When timing points change, the bpm map might change
	intro_skip_marker = null
	
	bpm_changes.clear()
	for point in timing_points:
		if point is HBBPMChange:
			bpm_changes.append(point)
		if point is HBIntroSkipMarker:
			intro_skip_marker = point
	
	note_groups = _process_timing_points_into_groups(points)
	note_groups_by_end_time = note_groups.duplicate()
	note_groups_by_end_time.sort_custom(Callable(self, "_sort_groups_by_end_time"))
	
	var song_length = audio_playback.get_length_msec() + audio_playback.offset
	if current_song.end_time > 0:
		song_length = min(song_length, float(current_song.end_time))
	
	update_bpm_map()
	
	timing_points = _process_timing_points_into_groups(points)

# Previously get_bpm_at_time
func get_note_speed_at_time(bpm_time: int) -> float:
	if not bpm_map:
		return 120.0
	
	var bpm_times = bpm_map.keys()
	bpm_times.sort()
	var idx = bpm_times.bsearch(bpm_time)
	
	if idx == bpm_times.size():
		return bpm_map[bpm_times[idx - 1]]
	
	if bpm_times[idx] == bpm_time:
		return bpm_map[bpm_time]
	
	idx = max(idx - 1, 0)
	return bpm_map[bpm_times[idx]]

func get_section_at_time(section_time):
	var current_time = null
	for c_t in section_changes:
		if (current_time == null and c_t <= section_time) or (c_t <= section_time and c_t > current_time):
			current_time = c_t
	
	return section_changes[current_time] if current_time else null

func _sort_notes_by_time(a: HBTimingPoint, b: HBTimingPoint):
	return a.time < b.time

# Stores playing field size in memory to mape remap_coords faster
func cache_playing_field_size():
	if size.y == 0:
		playing_field_size = Vector2.ZERO
		return
	
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

var handled_event_uids_this_frame := []
var unhandled_input_events_this_frame := []

func _process_input(event):
	if event.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.UP][0]) or event.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.LEFT][0]):
		if Input.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.UP][0]) and Input.is_action_pressed(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.LEFT][0]):
			if current_song.allows_intro_skip and _intro_skip_enabled:
				if time_msec < get_time_to_intro_skip_to():
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
			elif group.is_blocking_input():
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
	# Find the first group that is still alive in our window
	var final_search_point := note_groups.bsearch_custom(time_msec, self._group_compare_start, false)
	var first_search_point := note_groups_by_end_time.bsearch_custom(time_msec, self._group_compare_end, true)
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
				group_order_dirty = true
	
	if group_order_dirty:
		current_note_groups.sort_custom(Callable(self, "_sort_groups_by_start_time"))
		
	last_culled_note_group = final_search_point-1
	
	for i in range(current_note_groups.size()-1, -1, -1):
		var note_group := current_note_groups[i] as HBNoteGroup
		if note_group.process_group(time_msec):
			current_note_groups.erase(note_group)
			finished_note_groups.append(note_group)

# We need to split _process into it's own function so we can override it because
# godot is stupid and calls _process on both parent and child
func _process_game(_delta):
	_sfx_debounce_t += _delta
	
	_process_groups()
	
	for i in range(tracked_sounds.size()-1, -1, -1):
		var sound := tracked_sounds[i] as ShinobuSoundPlayer
		if sound.is_at_stream_end():
			tracked_sounds.remove_at(i)
			sound.queue_free()
	
	for i in range(current_note_groups.size()):
		var group = current_note_groups[i] as HBNoteGroup
		# Ignore timing points that are not happening now
		var start_time_msec := group.get_start_time_msec() as int
		if time_msec < start_time_msec:
			break
		if time_msec >= start_time_msec:
			for modifier in modifiers:
				if modifier.processing_notes:
					var drawers = []
					for note in group.note_datas:
						var drw = group.note_drawers.get(note, null)
						if drw:
							drawers.append(drw)
					modifier._process_note(drawers, time_msec / 1000.0, get_note_speed_at_time(time_msec))
	
	emit_signal("time_changed", time_msec / 1000.0)
	
	var new_closest_multi_notes = []
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
		if time_msec >= get_time_to_intro_skip_to():
			emit_signal("end_intro_skip_period")
			_intro_skip_enabled = false
			
	if not UserSettings.user_settings.play_hit_sounds_only_when_hit:
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
	var latency_compensation = UserSettings.user_settings.lag_compensation
	if current_song.id in UserSettings.user_settings.per_song_settings:
		latency_compensation += UserSettings.user_settings.per_song_settings[current_song.id].lag_compensation

	if (not editing or previewing) and audio_playback:
		time_msec = audio_playback.get_playback_position_nsec() / 1000_000.0
		time_msec -= latency_compensation

		if not editing:
			var end_time = audio_playback.get_length_msec() + audio_playback.offset
			if current_song.end_time > 0:
				end_time = min(end_time, float(current_song.end_time))

			if (audio_playback.get_playback_position_nsec() / 1000_000.0) >= end_time or audio_playback.is_at_stream_end() and not _finished:
				_on_game_finished()
func _process(delta):
	_pre_process_game()
	_process_game(delta)
	notes_judged_this_frame = []
	game_input_manager._frame_end()


func toggle_ui():
	emit_signal("ui_toggled")

func set_current_combo(combo: int):
	current_combo = combo

func restart():
	if current_song.allows_intro_skip and not disable_intro_skip:
		if earliest_note_time / 1000.0 > current_song.intro_skip_min_time:
			_intro_skip_enabled = true
	var max_score := result.max_score as int
	_prevent_finishing = true
	get_tree().paused = false
	time_msec = current_song.start_time
	game_ui._on_reset()
	seek_new(current_song.start_time, true)
	autoplay_scheduled_sounds.clear()
	
	result = HBResult.new()
	current_combo = 0
	# Find slide hold chains
	result.max_score = max_score
	
	if voice_audio_playback:
		voice_audio_playback.volume = db_to_linear(_song_volume + _volume_offset)
		voice_audio_playback.stop()
	set_current_combo(0)
	audio_playback.stop()
	game_input_manager.reset()
	autoplay_scheduled_sounds.clear()

func pause_game():
	if audio_playback:
		audio_playback.stop()
	
	if voice_audio_playback:
		voice_audio_playback.stop()

func resume():
	start()
func seek(position: int):
	if audio_playback:
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
	time_msec = position * 1000
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

func bsearch_time(a, b):
	return a.time < b.time
	
func set_game_ui(ui: HBRhythmGameUIBase):
	game_ui = ui
	ui.game = self
	connect("note_judged", Callable(ui, "_on_note_judged"))
	connect("intro_skipped", Callable(ui, "_on_intro_skipped"))
	connect("end_intro_skip_period", Callable(ui, "_on_end_intro_skip_period"))
	connect("score_added", Callable(ui, "_on_score_added"))
	connect("ui_toggled", Callable(ui, "_on_toggle_ui"))
	connect("hide_multi_hint", Callable(ui, "_on_hide_multi_hint"))
	connect("show_multi_hint", Callable(ui, "_on_show_multi_hint"))

func _play_empty_note_sound(event: InputEventHB):
	if event.is_pressed():
		if not event.event_uid in handled_event_uids_this_frame:
			if event.action in ["slide_left", "slide_right", "heart_note"]:
				sfx_pool.play_sfx("slide_empty")
			elif not event.action == "heart_note":
				sfx_pool.play_sfx("note_hit")
			handled_event_uids_this_frame.append(event.event_uid)

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
			voice_audio_playback.volume = db_to_linear(_song_volume + _volume_offset)
		result.notes_hit += 1
	if not wrong:
		result.note_ratings[final_judgement] += 1
	else:
		result.wrong_note_ratings[final_judgement] += 1

	result.total_notes += 1

	if current_combo > result.max_combo:
		result.max_combo = current_combo
		
	var judgement_info = {"judgement": final_judgement, "target_time": judgement_target_time, "time": time_msec, "wrong": wrong, "avg_pos": avg_pos}
	emit_signal("note_judged", judgement_info)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		editor_clear_notes()

# Tracks a sound and auto frees it when its finished
func track_sound(sound: ShinobuSoundPlayer):
	add_child(sound)
	tracked_sounds.append(sound)

func untrack_sound(sound: ShinobuSoundPlayer):
	remove_child(sound)
	tracked_sounds.erase(sound)

func seek_new(new_position_msec: int, reset_notes := false):
	autoplay_scheduled_sounds.clear()
	seek(new_position_msec)
	time_msec = new_position_msec
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

func editor_add_timing_point(point: HBTimingPoint, sort_groups: bool = true):
	if point is HBBaseNote:
		var note_data: HBBaseNote = point
		var group := editor_find_group_at_time(note_data.time, sort_groups)
		
		if not group:
			group = HBNoteGroup.new()
			group.game = self
			note_groups.append(group)
			note_groups_by_end_time.append(group)
		
		group.note_datas.append(note_data)
		group.reset_group()
		
		note_data.set_meta("editor_group", group)
		
		if sort_groups:
			_editor_sort_groups()
			
			last_culled_note_group = -1
	else:
		if point is HBBPMChange:
			bpm_changes.insert(bpm_changes.bsearch_custom(point, self._sort_notes_by_time), point)
			update_bpm_map()
		elif point is HBTimingChange:
			timing_changes.insert(timing_changes.bsearch_custom(point, self._sort_notes_by_time), point)
			update_bpm_map()
		else:
			print("TODO: Handle addition of non note timing points")

func _editor_sort_groups():
	note_groups.sort_custom(Callable(self, "_sort_groups_by_start_time"))
	note_groups_by_end_time.sort_custom(Callable(self, "_sort_groups_by_end_time"))

func editor_find_group_at_time(time_msec: int, sorted_groups: bool = true) -> HBNoteGroup:
	var group_i := -1
	
	if sorted_groups:
		group_i = note_groups_by_end_time.bsearch_custom(time_msec, self._group_compare_end)
	else:
		for i in range(note_groups_by_end_time.size()):
			var group = note_groups_by_end_time[i]
			var _time: int
			
			if group is HBNoteGroup:
				_time = group.get_end_time_msec()
			else:
				_time = group
			
			if _time == time_msec:
				group_i = i
				break
	
	if note_groups.size() > 0:
		# walk backwards
		if group_i == note_groups.size():
			group_i -= 1
		
		while group_i >= 0 and note_groups[group_i].get_end_time_msec() >= time_msec:
			if note_groups[group_i].get_hit_time_msec() == time_msec:
				return note_groups[group_i]
			
			group_i -= 1
	
	return null

func editor_remove_timing_point(point: HBTimingPoint):
	if point is HBBaseNote:
		var note_data: HBBaseNote = point
		var group: HBNoteGroup = note_data.get_meta("editor_group")
		
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
			bpm_changes.erase(point)
			update_bpm_map()
		elif point is HBTimingChange:
			timing_changes.erase(point)
			update_bpm_map()
		else:
			print("TODO: Handle removal of non note timing points")

func editor_clear_notes():
	for group in note_groups:
		for note_data in group.note_datas:
			note_data.set_meta("editor_group", null)
		
		if group.is_connected("notes_judged", Callable(self, "_on_notes_judged_new")):
			group.disconnect("notes_judged", Callable(self, "_on_notes_judged_new"))
		
		group.reset_group()
	
	note_groups.clear()
	note_groups_by_end_time.clear()
	current_note_groups.clear()
	finished_note_groups.clear()
	last_culled_note_group = -1
	
	bpm_changes.clear()
	timing_changes.clear()
	update_bpm_map()

func notify_rollback():
	for group in note_groups:
		group.notify_rollback()

func is_sound_debounced(sound_name: String):
	return sound_name in sfx_debounce_times

func debounce_sound(sound_name: String):
	sfx_debounce_times[sound_name] = SFX_DEBOUNCE_TIME

func set_timing_changes(p_timing_changes):
	timing_changes = p_timing_changes.duplicate()
	timing_changes.sort_custom(Callable(self, "_sort_notes_by_time"))

func update_bpm_map():
	bpm_map.clear()
	
	if timing_changes:
		bpm_map[0] = timing_changes[0].bpm
	elif bpm_changes and bpm_changes[0].usage == HBBPMChange.USAGE_TYPES.FIXED_BPM:
		bpm_map[0] = bpm_changes[0].bpm
	else:
		bpm_map[0] = 0
	
	var speed_changes = bpm_changes.duplicate()
	speed_changes.append_array(timing_changes)
	speed_changes.sort_custom(Callable(self, "_sort_notes_by_time"))
	
	var current_bpm = timing_changes[0].bpm if timing_changes else 120
	var current_bpm_change := HBBPMChange.new()
	current_bpm_change.speed_factor = 100
	for event in speed_changes:
		if event is HBTimingChange:
			current_bpm = event.bpm
		
		if event is HBBPMChange:
			current_bpm_change = event
			
			if current_bpm_change.usage == HBBPMChange.USAGE_TYPES.FIXED_BPM:
				bpm_map[event.time] = current_bpm_change.bpm
				continue
		
		if current_bpm_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
			bpm_map[event.time] = current_bpm * (current_bpm_change.speed_factor / 100.0)
