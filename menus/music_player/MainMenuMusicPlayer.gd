extends HBMenu

var current_song_length
@onready var image_preview_texture_rect = get_node("HBoxContainer/MusicPlayer/MarginContainer/VBoxContainer/HBoxContainer/TextureRect")
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")

@onready var main_container = get_node("HBoxContainer")
@onready var music_player = get_node("HBoxContainer/MusicPlayer")

@onready var entry_tween = Threen.new()
@onready var exit_timer = Timer.new()

var current_song: HBSong

const TIME_ON_SCREEN = 8.0

var current_task

func _ready():
	super._ready()
	if UserSettings.user_settings.disable_menu_music:
		hide()
	add_child(entry_tween)
	add_child(exit_timer)
	exit_timer.wait_time = TIME_ON_SCREEN
	main_container.modulate.a = 0.0
	exit_timer.connect("timeout", Callable(self, "_on_exit_timer_timeout"))
	exit_timer.one_shot = true

func _unhandled_input(event):
	if event.is_action_pressed("gui_show_song"):
		_on_show_title_press()
	elif event.is_action_released("gui_show_song"):
		exit_timer.stop()
		entry_tween.remove_all()
		entry_tween.interpolate_property(main_container, "modulate:a", 1.0, 0.0, 0.5, Threen.TRANS_LINEAR)
		entry_tween.interpolate_property(main_container, "position:x", main_container.position.x, size.x, 0.5, Threen.TRANS_LINEAR, Threen.EASE_OUT)
		entry_tween.start()

func format_time(secs: float) -> String:
	return HBUtils.format_time(secs*1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
func set_song(song: HBSong, length: float, do_animation=true):
	var playback_max_label = get_node("HBoxContainer/MusicPlayer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackMaxLabel")

	current_song = song

	var song_title_label = get_node("HBoxContainer/MusicPlayer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SongTitle")
	current_song_length = length
	song_title_label.set_song(song)
	playback_max_label.text = format_time(length)
	if exit_timer.is_stopped():
		entry_tween.remove_all()
		entry_tween.interpolate_property(main_container, "position:x", music_player.position.x, 0.0, 0.5, Threen.TRANS_BOUNCE)
		entry_tween.interpolate_property(main_container, "modulate:a", 0.0, 1.0, 0.5, Threen.TRANS_LINEAR)
		entry_tween.start()
	exit_timer.start()
	
	var preview_load_task = SongAssetLoadAsyncTask.new(["preview"], song)
	preview_load_task.connect("assets_loaded", Callable(self, "_on_assets_loaded"))
	if current_task:
		AsyncTaskQueue.abort_task(current_task)
	current_task = preview_load_task
	AsyncTaskQueue.queue_task(preview_load_task)
func _on_exit_timer_timeout():
	entry_tween.remove_all()
	entry_tween.interpolate_property(main_container, "modulate:a", main_container.modulate.a, 0.0, 0.5, Threen.TRANS_LINEAR)
	entry_tween.interpolate_property(main_container, "position:x", 0.0, music_player.size.x, 0.5, Threen.TRANS_LINEAR, Threen.EASE_OUT)
	entry_tween.start()
func _on_show_title_press():
	entry_tween.remove_all()
	entry_tween.interpolate_property(main_container, "modulate:a", main_container.modulate.a, 1.0, 0.5, Threen.TRANS_LINEAR)
	entry_tween.interpolate_property(main_container, "position:x", main_container.position.x, 0.0, 0.5, Threen.TRANS_LINEAR, Threen.EASE_OUT)
	entry_tween.start()
func set_time(time: float):
	if current_song_length:
		var playback_current_time_label = get_node("HBoxContainer/MusicPlayer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackCurrentTimeLabel")
		playback_current_time_label.text = format_time(time)
		var playback_progress_bar = get_node("HBoxContainer/MusicPlayer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/VBoxContainer/ProgressBar")
		playback_progress_bar.value = time / current_song_length

func _on_assets_loaded(assets):
	image_preview_texture_rect.material = null
	if "preview" in assets:
		image_preview_texture_rect.texture = assets.preview
		if image_preview_texture_rect.texture is DIVASpriteSet.DIVASprite:
			image_preview_texture_rect.material = image_preview_texture_rect.texture.get_material()
	else:
		image_preview_texture_rect.texture = DEFAULT_IMAGE_TEXTURE
