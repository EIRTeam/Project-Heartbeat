extends "res://addons/gut/test.gd"

class TestTimeFormat:
	extends "res://addons/gut/test.gd"
	func test_format_miliseconds():
		var r = HBUtils.format_time(500, HBUtils.TimeFormat.FORMAT_MILISECONDS)
		assert_eq(r, ".500")
	func test_format_seconds():
		var r = HBUtils.format_time(1100, HBUtils.TimeFormat.FORMAT_MILISECONDS | HBUtils.TimeFormat.FORMAT_SECONDS)
		assert_eq(r, "01.100")
	func test_format_minutes():
		var r = HBUtils.format_time(61100, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_MILISECONDS | HBUtils.TimeFormat.FORMAT_SECONDS)
		assert_eq(r, "01:01.100")

class TestMergeDict:
	extends "res://addons/gut/test.gd"
	func test_merge_dict():
		var resulting_dict = HBUtils.merge_dict({"test1": "test1"}, {"test2": "test2"})
		assert_has(resulting_dict, "test1")
		assert_has(resulting_dict, "test2")

	# Merge dict overwrites the children of the left dictionary
	func test_merge_dict_overwrite():
		var dict1 = {
			"test1": "test",
			"test3": "test"
		}
		var dict2 = {
			"test1": "test_overwrite",
			"test4": "test"
		}
		var resulting_dict = HBUtils.merge_dict(dict1, dict2)
		
		var expected_dict = {
			"test1": "test_overwrite",
			"test3": "test",
			"test4": "test"
		}

		assert_eq(resulting_dict, expected_dict)

func test_get_valid_filename():
	var invalid_filename = "اسم+`+`çḉtest UwU"
	assert_eq(HBUtils.get_valid_filename(invalid_filename), "test_uwu")


class TestVerifyOGG:
	extends "res://addons/gut/test.gd"
	func test_verify_valid_ogg():
		assert_eq(HBUtils.verify_ogg("res://songs/cloud_sky_2019/cloud_sky_2019.ogg"), HBUtils.OGG_ERRORS.OK)
	func test_verify_not_ogg():
		assert_eq(HBUtils.verify_ogg("res://graphics/credits/credits_image.png"), HBUtils.OGG_ERRORS.NOT_AN_OGG)
	func test_verify_not_vorbis():
		assert_eq(HBUtils.verify_ogg("res://tests/test_assets/opus_test.ogg"), HBUtils.OGG_ERRORS.NOT_VORBIS)

func test_find_key():
	var test_dict = {
		"Key1": "Val",
		"Key": "Value",
		"Key2": "Val"
	}
	assert_eq(HBUtils.find_key(test_dict, "Value"), "Key")

# TODO: test for user:// images
func test_image_from_fs():
	var image = HBUtils.image_from_fs("res://graphics/credits/credits_image.png")
	assert_true(image is Image)

# TODO: test for user:// images
func test_image_from_fs_async():
	var image = HBUtils.image_from_fs_async("res://graphics/credits/credits_image.png")
	gut.p(image)
	assert_true(image is Texture2D)
func test_thousands_sep():
	assert_eq(HBUtils.thousands_sep(1000000, "UwU"), "UwU1,000,000")
func test_thousands_sep_negative():
	assert_eq(HBUtils.thousands_sep(-1000000, "UwU"), "-UwU1,000,000")

func test_join_path():
	assert_eq(HBUtils.join_path("test", "test_second"), "test/test_second")
	assert_eq(HBUtils.join_path("test/", "test_second"), "test/test_second")
