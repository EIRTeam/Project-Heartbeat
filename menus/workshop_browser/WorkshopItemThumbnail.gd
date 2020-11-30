extends HBHovereableButton

var request = HTTPRequest.new()

onready var texture_rect = get_node("VBoxContainer/TextureRect")
onready var title_label = get_node("VBoxContainer/Label")

var data: HBWorkshopPreviewData

func _ready():
	request.connect("request_completed", self, "_on_request_completed")

func set_data(_data: HBWorkshopPreviewData):
	add_child(request)
	data = _data
	request.use_threads = true
	request.request(data.preview_url)
	title_label.text = data.title
	
func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if result == OK and response_code == 200:
		var tex = ImageTexture.new()
		var img = Image.new()
		if body.subarray(0, 2) == PoolByteArray([0xFF, 0xD8, 0xFF]):
			img.load_jpg_from_buffer(body)
		elif body.subarray(0, 3) == PoolByteArray([0x89, 0x50, 0x4E, 0x47]):
			img.load_png_from_buffer(body)
		elif body.subarray(0, 3) == PoolByteArray([0x52, 0x49, 0x46, 0x46]):
			img.load_webp_from_buffer(body)

		tex.create_from_image(img)
		texture_rect.texture = tex
