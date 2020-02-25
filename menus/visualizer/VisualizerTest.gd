extends Control

func _ready():
	$Panel/MarginContainer/VBoxContainer/HBoxContainer2/MindBHSlider.share($Panel/MarginContainer/VBoxContainer/HBoxContainer2/MindBSpinbox)
	$Panel/MarginContainer/VBoxContainer/HBoxContainer/FreqHSLider.share($Panel/MarginContainer/VBoxContainer/HBoxContainer/FreqSpinbox)
	
	$Panel/MarginContainer/VBoxContainer/HBoxContainer/FreqHSLider.value = $Visualizer.FREQ_MAX
	$Panel/MarginContainer/VBoxContainer/HBoxContainer2/MindBHSlider.value = $Visualizer.MIN_DB
	$Panel/MarginContainer/VBoxContainer/HBoxContainer4/SeekSlider.connect("value_changed", self, "_on_SeekSlider_value_changed")
	

func load_ogg(path: String):
	var ogg_file = File.new()
	ogg_file.open(path, File.READ)
	var bytes = ogg_file.get_buffer(ogg_file.get_len())
	var stream = AudioStreamOGGVorbis.new()
	stream.data = bytes
	$AudioStreamPlayer.stream = stream
	ogg_file.close()

func load_wav(path: String):
	var wav_file = File.new()
	wav_file.open(path, File.READ)
	var bytes = wav_file.get_buffer(wav_file.get_len())
	var stream = AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_16_BITS
	stream.stereo = true
	stream.mix_rate = 44100
	stream.data = bytes
	$AudioStreamPlayer.stream = stream
	wav_file.close()
func _input(event: InputEvent):
	if event.is_action_pressed("hide_ui"):
		$Panel.visible = !$Panel.visible

func _on_file_selected(path: String):
	if path.to_lower().ends_with(".ogg"):
		load_ogg(path)
	else:
		load_wav(path)
	$Panel/MarginContainer/VBoxContainer/HBoxContainer4/SeekSlider.max_value = $AudioStreamPlayer.stream.get_length()
	$AudioStreamPlayer.play()
	
func _process(delta):
	$Panel/MarginContainer/VBoxContainer/HBoxContainer4/SeekSlider.disconnect("value_changed", self, "_on_SeekSlider_value_changed")
	$Panel/MarginContainer/VBoxContainer/HBoxContainer4/SeekSlider.value = $AudioStreamPlayer.get_playback_position()
	$Panel/MarginContainer/VBoxContainer/HBoxContainer4/SeekSlider.connect("value_changed", self, "_on_SeekSlider_value_changed")

func _on_SeekSlider_value_changed(value):
	$AudioStreamPlayer.seek(value)


func _on_PlayButton_pressed():
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	$AudioStreamPlayer.stream_paused = false
