extends HBSongListItemBase

class_name HBSongListItem

var song : HBSong

@onready var button = get_node("%Button")
#onready var star_texture_rect = get_node("TextureRect")

@onready var song_title: Control = get_node("%SongTitle")

@onready var arcade_texture_rect: TextureRect = get_node("%ArcadeTexture")
@onready var console_texture_rect: TextureRect = get_node("%ConsoleTexture")
@onready var arcade_texture_diff_rect: TextureRect = get_node("%ArcadeTextureDifficulty")
@onready var console_texture_diff_rect: TextureRect = get_node("%ConsoleTextureDifficulty")
@onready var download_texture_rect: TextureRect = get_node("%DownloadTextureRect")
#HBNoteData.get_note_graphic(data.note_type, "note")

const DIFFICULTY_TAG: PackedScene = preload("res://menus/song_list/DifficultyTag.tscn")

@onready var difficulty_tag_container: HBSimpleMenu = get_node("%DifficultyTagContainer")
@onready var animatable_container: HBAnimatableContainer = get_node("%AnimatableContainer")
@onready var rating_texture: TextureRect = get_node("%RatingTexture")
@onready var rating_data_container: HBoxContainer = get_node("%RatingDataContainer")
@onready var score_label: Label = get_node("%ScoreLabel")
@onready var percentage_label: Label = get_node("%PercentageLabel")
@onready var album_art_texture: TextureRect = get_node("%AlbumArtTexture")
@onready var unsubscribe_button_container: Control = get_node("%UnsubscribeButtonContainer")
@onready var unsubscribe_button_margin_container: Control = get_node("%UnsubscribeButtonMarginContainer")
@onready var unsubscribe_button: Button = get_node("%UnsubscribeButton")

var song_update_queued := false

signal difficulty_selected(song: HBSong, difficulty: String)
signal unsubscribe_requested(song: HBSong)

func _queue_song_update():
	if not song_update_queued:
		song_update_queued = true
		if not is_node_ready():
			await ready
		_song_update.call_deferred()

func _on_difficulty_tag_pressed(diff: String):
	disable_scaling = false
	animatable_container.animate(false)
	UserSettings.user_settings.last_selected_difficulty = diff
	UserSettings.save_user_settings()
	difficulty_selected.emit(song, diff)
	
func select_diff(diff: String):
	await get_tree().process_frame
	for diff_button in difficulty_tag_container.get_children():
		if diff_button.difficulty == diff:
			difficulty_tag_container.select_button(diff_button.get_index())
			break
func _song_update():
	song_update_queued = false
	download_texture_rect.visible = not song.is_cached() and song.youtube_url
	song_title.song = song
	var max_stars = song.get_max_score()
	var sorted_diffs = []
	for chart in song.charts:
		if song.charts[chart].has("stars"):
			var stars = song.charts[chart].stars
			sorted_diffs.push_back([stars, chart])
			if stars > max_stars:
				max_stars = stars

	sorted_diffs.sort_custom(func (a: Array, b: Array): return a[0] < b[0])
	
	for diff in sorted_diffs:
		var diff_tag := DIFFICULTY_TAG.instantiate() as HBDifficultyTag
		diff_tag.difficulty = diff[1]
		diff_tag.stars = diff[0]
		diff_tag.hovered.connect(self._on_difficulty_hovered.bind(diff[1]))
		diff_tag.pressed.connect(self._on_difficulty_tag_pressed.bind(diff[1]))
		difficulty_tag_container.add_child(diff_tag)
	
	var stars_string = "-"
	if max_stars != 0:
		if fmod(max_stars, floor(max_stars)) != 0:
			stars_string = "%.1f" % [max_stars]
		else:
			stars_string = "%d" % [max_stars]

	if not song.comes_from_ugc():
		if unsubscribe_button_margin_container.has_meta(&"animated_deployed_visibility"):
			unsubscribe_button_margin_container.remove_meta(&"animated_deployed_visibility")
	else:
		unsubscribe_button_margin_container.set_meta(&"animated_deployed_visibility", true)
	var token := SongAssetLoader.request_asset_load(song, [SongAssetLoader.ASSET_TYPES.PREVIEW])
	await token.assets_loaded
	album_art_texture.texture = token.get_asset(SongAssetLoader.ASSET_TYPES.PREVIEW)
	
func update_scale(to: Vector2, no_animation=false):
	if not disable_scaling:
		super.update_scale(to, no_animation)

func _ready():
	super._ready()
	arcade_texture_diff_rect.texture = ResourcePackLoader.get_graphic("slide_right_note.png")
	console_texture_diff_rect.texture = ResourcePackLoader.get_graphic("heart_note.png")
	arcade_texture_rect.hide()
	console_texture_rect.hide()
	pressed.connect(self._on_pressed)
	button.pressed.connect(pressed.emit)
	set_process_input(true)
	interpolated_scale = NON_HOVERED_SCALE
	difficulty_tag_container.focus_exited.connect(_on_focus_lost, CONNECT_DEFERRED)
	unsubscribe_button_container.focus_exited.connect(_on_focus_lost, CONNECT_DEFERRED)
	unsubscribe_button.pressed.connect(_on_unsubscribe_requested_pressed)
	
	get_parent().sort_children.connect(
		func(): 
			set_deferred("scale", interpolated_scale)
	)

func _on_unsubscribe_requested_pressed():
	unsubscribe_requested.emit(song)

var disable_scaling := false

func _on_song_cached():
	get_node("%DownloadTextureRect").visible = not song.is_cached() and song.youtube_url

func set_song(value: HBSong):
	if song:
		song.disconnect("song_cached", Callable(self, "_on_song_cached"))
	song = value
	song.connect("song_cached", Callable(self, "_on_song_cached"))
	_queue_song_update()

#	if ScoreHistory.has_result(value.id, difficulty):
#		var result := ScoreHistory.get_result(value.id, difficulty) as HBResult
#		var pass_percentage = result.get_percentage()
#		var score_text = "%s - %.2f" % [HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating()), pass_percentage * 100.0]
#		score_text += " %"
#		score_label.text = score_text
#	else:
#		score_label.hide()

#	stars_texture_rect.rect_position = Vector2(-88, -25)
#	star_texture_rect.rect_position = Vector2(-(star_texture_rect.rect_size.x/2.0), (rect_size.y / 2.0) - ((star_texture_rect.rect_size.y) / 2.0))
	
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

# Called by UniversalScrollList when the item becomes visible

var note_usage_shown = false

func _show_note_usage():
	var global_note_type_usage = []
	for difficulty in song.charts:
		for type in song.get_chart_note_usage(difficulty):
			if not type in global_note_type_usage:
				global_note_type_usage.append(int(type))
			if global_note_type_usage.size() >= HBChart.ChartNoteUsage.size():
				break
	if HBChart.ChartNoteUsage.ARCADE in global_note_type_usage:
		arcade_texture_rect.texture = ResourcePackLoader.get_graphic("slide_right_note.png")
		arcade_texture_rect.show()
	if HBChart.ChartNoteUsage.CONSOLE in global_note_type_usage:
		console_texture_rect.texture = ResourcePackLoader.get_graphic("heart_note.png")
		console_texture_rect.show()
	note_usage_shown = true
func _on_note_usage_loaded(token: SongAssetLoader.AssetLoadToken):
	if token.song == song:
		_show_note_usage()

func _get_minimum_size() -> Vector2:
	return $MarginContainer.get_combined_minimum_size()

func _become_visible():
	if note_usage_shown:
		return
	if song.is_chart_note_usage_known_all():
		_show_note_usage()
	else:
		var task := SongAssetLoader.request_asset_load(song, [SongAssetLoader.ASSET_TYPES.NOTE_USAGE])
		task.assets_loaded.connect(_on_note_usage_loaded)
		
func hover(no_animation=false):
	super.hover(no_animation)
	%Button.add_theme_stylebox_override("normal", hover_style)
	
func stop_hover(no_animation=false):
	if disable_scaling:
		return
	super.stop_hover(no_animation)
	%Button.add_theme_stylebox_override("normal", normal_style)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("gui_cancel"):
		if difficulty_tag_container.has_focus():
			# terrible horrible not very good HACK
			get_parent().get_parent().grab_focus()
			get_viewport().set_input_as_handled()
			set_process_input(false)
			animatable_container.animate(false)
			disable_scaling = false

func _on_difficulty_hovered(diff: String):
	arcade_texture_diff_rect.hide()
	console_texture_diff_rect.hide()
	
	if ScoreHistory.has_result(song.id, diff):
		var result := ScoreHistory.get_data(song.id, diff) as HBHistoryEntry
		var pass_percentage = result.highest_percentage
		var thousands_sep_score = HBUtils.thousands_sep(result.highest_score)
		var rating = HBUtils.find_key(HBResult.RESULT_RATING, result.highest_rating)
		
		var score_text = ""
		if UserSettings.user_settings.use_explicit_rating or result.highest_rating == 1:
			score_text += "%s | " % rating
		
		score_text += "%s pts" % [thousands_sep_score]
		score_label.text = score_text
		percentage_label.text = "%.2f %%" % [pass_percentage * 100.0]
		
		rating_texture.texture = HBUtils.get_clear_badge(result.highest_rating)
		
	else:
		score_label.text = "- | - pts"
		percentage_label.text = "- %"
		rating_texture.texture = preload("res://graphics/icons/badge_empty.svg")
	var note_type_usage: Array = song.get_chart_note_usage(diff)
	
	if HBChart.ChartNoteUsage.ARCADE in note_type_usage:
		arcade_texture_diff_rect.show()
	if HBChart.ChartNoteUsage.CONSOLE in note_type_usage:
		console_texture_diff_rect.show()

func _on_pressed():
	rating_data_container.show()
	disable_scaling = true
	%Button.add_theme_stylebox_override("normal", hover_style)
	_on_difficulty_hovered(difficulty_tag_container.get_child(0).difficulty)
	animatable_container.animate(true)
	difficulty_tag_container.grab_focus()
	for tag: HBDifficultyTag in difficulty_tag_container.get_children():
		if tag.difficulty.to_lower() == UserSettings.user_settings.last_selected_difficulty.to_lower():
			select_diff(tag.difficulty)
			break
	set_process_input(true)

func _on_focus_lost():
	if not get_viewport().gui_get_focus_owner() in [unsubscribe_button_container, difficulty_tag_container]:
		disable_scaling = false
		stop_hover()
		set_process_input(false)
		animatable_container.animate(false)
