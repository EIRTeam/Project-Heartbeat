extends "res://tests/test_case.gd"


func test_failed_result_uses_fail_rating() -> void:
	var result := HBResult.new()
	result.failed = true

	expect_eq(result.get_result_rating(), HBResult.RESULT_RATING.FAIL)


func test_perfect_result_requires_no_misses() -> void:
	var result := HBResult.new()
	result.max_score = 1000
	result.score = 1000

	expect_eq(result.get_result_rating(), HBResult.RESULT_RATING.PERFECT)


func test_percentage_caps_hold_and_slide_bonuses() -> void:
	var result := HBResult.new()
	result.max_score = 1000
	result.score = 1400
	result.hold_bonus = 200
	result.slide_bonus = 200

	expect_eq(result.get_capped_score(), 1150.0)
	expect_eq(result.get_percentage(), 1.15)
