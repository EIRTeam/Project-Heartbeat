extends RefCounted

var _failures: Array[Dictionary] = []
var _assertion_count := 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func expect_true(value: Variant, message := "") -> void:
	_record_assertion(bool(value), true, value, message)


func expect_false(value: Variant, message := "") -> void:
	_record_assertion(not bool(value), false, value, message)


func expect_eq(actual: Variant, expected: Variant, message := "") -> void:
	_record_assertion(actual == expected, expected, actual, message)


func expect_ne(actual: Variant, unexpected: Variant, message := "") -> void:
	_assertion_count += 1
	if actual == unexpected:
		_failures.push_back({
			"message": message,
			"expected": "a value different from %s" % _format_value(unexpected),
			"actual": actual,
		})


func expect_null(value: Variant, message := "") -> void:
	_record_assertion(value == null, null, value, message)


func expect_not_null(value: Variant, message := "") -> void:
	_assertion_count += 1
	if value == null:
		_failures.push_back({
			"message": message,
			"expected": "a non-null value",
			"actual": value,
		})


func fail(message: String) -> void:
	_assertion_count += 1
	_failures.push_back({
		"message": message,
		"expected": "test to pass",
		"actual": "explicit failure",
	})


func _record_assertion(passed: bool, expected: Variant, actual: Variant, message: String) -> void:
	_assertion_count += 1
	if not passed:
		_failures.push_back({
			"message": message,
			"expected": expected,
			"actual": actual,
		})


func _format_value(value: Variant) -> String:
	return var_to_str(value)
