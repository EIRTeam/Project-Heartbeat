extends HBHovereableButton

onready var title_label: Label = get_node("Button/HBoxContainer/Label")
onready var spinner_texture: TextureRect = get_node("Button/HBoxContainer/TextureRect")
onready var animation_player: AnimationPlayer = get_node("Button/AnimationPlayer")

var entry: YoutubeDL.CachingQueueEntry

func _ready():
	connect("resized", self, "_on_resized")
	call_deferred("_on_resized")

func set_entry(_entry: YoutubeDL.CachingQueueEntry):
	entry = _entry
	var song = entry.song
	title_label.text = song.get_visible_title(_entry.variant)
	set_downloading(YoutubeDL.get_video_id(song.get_variant_data(entry.variant).variant_url) in YoutubeDL.video_ids_being_cached)
	
func set_downloading(_downloading: bool):
	spinner_texture.visible = _downloading
	
func _on_resized():
	spinner_texture.rect_pivot_offset = spinner_texture.rect_size / 2.0
	animation_player.play("spin")

func hover():
	.hover()
	
func stop_hover():
	.stop_hover()
