extends "res://tests/test_case.gd"

const TEST_PATH := "user://atomic_write_test.txt"
const COPY_PATH := "user://atomic_copy_test.txt"


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	DirAccess.remove_absolute(COPY_PATH)


func test_atomic_text_write_replaces_existing_content() -> void:
	expect_eq(HBUtils.write_text_atomic(TEST_PATH, "before"), OK)
	expect_eq(HBUtils.write_text_atomic(TEST_PATH, "after"), OK)
	expect_eq(FileAccess.get_file_as_string(TEST_PATH), "after")


func test_atomic_copy_replaces_existing_content() -> void:
	expect_eq(HBUtils.write_text_atomic(TEST_PATH, "source"), OK)
	expect_eq(HBUtils.write_text_atomic(COPY_PATH, "destination"), OK)
	expect_eq(HBUtils.copy_file_atomic(TEST_PATH, COPY_PATH), OK)
	expect_eq(FileAccess.get_file_as_string(COPY_PATH), "source")


func test_failed_atomic_copy_preserves_destination() -> void:
	expect_eq(HBUtils.write_text_atomic(COPY_PATH, "destination"), OK)
	expect_ne(HBUtils.copy_file_atomic("user://missing_atomic_source.txt", COPY_PATH), OK)
	expect_eq(FileAccess.get_file_as_string(COPY_PATH), "destination")
