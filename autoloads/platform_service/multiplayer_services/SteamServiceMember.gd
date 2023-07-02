extends HBServiceMember

class_name SteamServiceMember

var steam_avatar_cached = false

func _init(id):
	super(id)
	# Do we actually need to do this or does steam cache getFriendPersonaName?
	Steam.requestUserInformation(id, false)
	member_name = Steam.getFriendPersonaName(id)
	Steam.connect("persona_state_change", Callable(self, "_persona_state_change"))
	cache_steam_avatar()

func _persona_state_change(steam_id, flags):
	if steam_id == member_id:
		member_name = Steam.getFriendPersonaName(steam_id)
		cache_steam_avatar()
		emit_signal("persona_state_change", flags)
	
func cache_steam_avatar():
	var img_handle = Steam.getMediumFriendAvatar(member_id)
	var size = Steam.getImageSize(img_handle)
	var dict = Steam.getImageRGBA(img_handle)
	var buffer = dict.buffer
	var avatar_image = Image.create(size.width, size.height, false, Image.FORMAT_RGBAF)
	
	for y in range(size.height):
		for x in range(size.width):
			var pixel = 4 * (x + y * size.height)
			var r = float(buffer[pixel]) / 255.0
			var g = float(buffer[pixel+1]) / 255.0
			var b = float(buffer[pixel+2]) / 255.0
			var a = float(buffer[pixel+3]) / 255.0
			avatar_image.set_pixel(x, y, Color(r, g, b, a))
	var avatar_texture = ImageTexture.create_from_image(avatar_image)
	avatar = avatar_texture
	steam_avatar_cached = true

func get_avatar():
	if not steam_avatar_cached:
		cache_steam_avatar()
	return avatar

func is_local_user():
	return member_id == Steam.getSteamID()
