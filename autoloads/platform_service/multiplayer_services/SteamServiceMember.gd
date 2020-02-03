extends HBServiceMember

class_name SteamServiceMember

var steam_avatar_cached = false

func _init(id).(id):
	# Do we actually need to do this or does steam cache getFriendPersonaName?
	member_name = Steam.getFriendPersonaName(member_id)
	cache_steam_avatar()

	
func cache_steam_avatar():
	if not steam_avatar_cached:
		var img_handle = Steam.getMediumFriendAvatar(member_id)
		var size = Steam.getImageSize(img_handle)
		var buffer = Steam.getImageRGBA(img_handle).buffer
		var avatar_image = Image.new()
		var avatar_texture = ImageTexture.new()
		avatar_image.create(size.width, size.height, false, Image.FORMAT_RGBAF)
		
		avatar_image.lock()
		
		for y in range(size.height):
			for x in range(size.width):
				var pixel = 4 * (x + y * size.height)
				var r = float(buffer[pixel]) / 255.0
				var g = float(buffer[pixel+1]) / 255.0
				var b = float(buffer[pixel+2]) / 255.0
				var a = float(buffer[pixel+3]) / 255.0
				avatar_image.set_pixel(x, y, Color(r, g, b, a))
		avatar_image.unlock()
		avatar_image.save_png("user://avatar.png")
		avatar_texture.create_from_image(avatar_image)
		avatar = avatar_texture
		steam_avatar_cached = true

func get_avatar():
	if not steam_avatar_cached:
		cache_steam_avatar()
	return avatar
