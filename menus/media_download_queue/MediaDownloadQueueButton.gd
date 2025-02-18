extends HBHovereableButton

class_name HBMediaDownloadQueueButton

@onready var title_label: Label = get_node("%TitleLabel")
@onready var spinner_texture: TextureRect = get_node("%Spinner")
@onready var animation_player: AnimationPlayer = get_node("Button/AnimationPlayer")
@onready var progress_bar: ProgressBar = get_node("%ProgressBar")
@onready var cancel_button: HBHovereableButton = get_node("%CancelButton")

var entry: YoutubeDL.CachingQueueEntry

func _ready():
	super._ready()
	connect("resized", Callable(self, "_on_resized"))
	call_deferred("_on_resized")
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	cancel_button.pressed.connect(self.pressed.emit)

func set_entry(_entry: YoutubeDL.CachingQueueEntry):
	if entry:
		entry.disconnect("download_progress_changed", Callable(self, "_on_download_progress_changed"))
	entry = _entry
	entry.connect("download_progress_changed", Callable(self, "_on_download_progress_changed").bind(), CONNECT_DEFERRED)
	var song = entry.song
	title_label.text = song.get_visible_title(_entry.variant)
	set_downloading(YoutubeDL.get_video_id(song.get_variant_data(entry.variant).variant_url) in YoutubeDL.video_ids_being_cached)
	if progress_bar:
		progress_bar.value = _entry.download_progress
func _on_download_progress_changed(download_progress: float, download_speed: float):
	if progress_bar:
		progress_bar.value = download_progress
	
func set_downloading(_downloading: bool):
	spinner_texture.visible = _downloading
	
func _on_resized():
	spinner_texture.pivot_offset = spinner_texture.size / 2.0
	animation_player.play("spin")

func hover():
	cancel_button.hover()
	
func stop_hover():
	cancel_button.stop_hover()
