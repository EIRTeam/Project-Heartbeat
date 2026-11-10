extends "res://tests/test_case.gd"

var _setup_ran := false


func before_each() -> void:
	_setup_ran = true


func test_fixture_lifecycle() -> void:
	expect_true(_setup_ran, "before_each should run before the test")


func test_value_assertions() -> void:
	expect_eq(2 + 2, 4)
	expect_ne("heartbeat", "project")
	expect_null(null)
	expect_not_null(self)
