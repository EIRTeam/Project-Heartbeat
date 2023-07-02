extends Control

signal deleted
signal show_download_prompt(variant)

@onready var line_edit_name: LineEdit = get_node("VBoxContainer/LineEditName")
@onready var line_edit_url: LineEdit = get_node("VBoxContainer/LineEditURL")
@onready var checkbox_audio_only: CheckBox = get_node("VBoxContainer/AudioOnlyCheckbox")
@onready var offset_spinbox: SpinBox = get_node("VBoxContainer/OffsetSpinBox")
@onready var sync_window = get_node("Window")
var offset := 0.0

var variant: HBSongVariantData = HBSongVariantData.new()
var song: HBSong

func _on_DeleteButton_pressed():
	emit_signal("deleted")
	
func set_variant(_variant: HBSongVariantData):
	variant = _variant
	line_edit_name.text = variant.variant_name
	line_edit_url.text = variant.variant_url
	checkbox_audio_only.button_pressed = variant.audio_only
	offset_spinbox.value = variant.variant_offset
func save_variant():
	variant.variant_name = line_edit_name.text
	variant.variant_url = line_edit_url.text
	variant.audio_only = checkbox_audio_only.button_pressed
	variant.variant_offset = offset_spinbox.value

func _on_ButtonSync_pressed():
	if YoutubeDL.get_cache_status(variant.variant_url, false, true) != YoutubeDL.CACHE_STATUS.OK:
		emit_signal("show_download_prompt", get_index())
	else:
		sync_window.show_comparison(song, variant, offset_spinbox.value / 1000.0)

func _on_WindowDialog_offset_changed(new_offset: float):
	offset_spinbox.value = int(new_offset * 1000.0)
