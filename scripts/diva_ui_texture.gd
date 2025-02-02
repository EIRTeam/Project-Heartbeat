## Special kind of texture that does conversions and manipulations on the GPU when displayed
extends AtlasTexture

class_name HBDIVAUITexture

var processed := false
var texture_2d_rd: Texture2DRD

var process_flags: int
var texture_processor: DIVATextureProcessor
var images: Array[Image]

func _init(_images: Array[Image], _process_flags: int) -> void:
	process_flags = _process_flags
	images = _images
	assert(not images.is_empty(), "Must provide at least 1 image")
	if process_flags & DIVATextureProcessor.Flags.FLAG_YCBCR_TO_RGB:
		assert(images.size() == 2, "DIVA YCBCRA -> RGBA images must be 2")

func _on_processing_completed():
	atlas = texture_2d_rd
	texture_processor = null
	images.clear()
func notify_visible():
	if processed:
		return
	
	if process_flags != 0:
		texture_processor = DIVATextureProcessor.new(images, process_flags)
		texture_processor.completed.connect(
			func():
				texture_2d_rd = texture_processor.get_texture_2d_rd()
				_on_processing_completed()
		)
	processed = true
		
		
