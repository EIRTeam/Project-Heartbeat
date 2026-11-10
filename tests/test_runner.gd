extends SceneTree

const TEST_ROOT := "res://tests/cases"
const TEST_FILE_SUFFIX := "_test.gd"
const TEST_METHOD_PREFIX := "test_"

var _has_run := false
var _filter := ""
var _single_file := ""
var _list_only := false
var _argument_error := ""


func _initialize() -> void:
	_parse_arguments(OS.get_cmdline_user_args())


func _process(_delta: float) -> bool:
	if _has_run:
		return false
	_has_run = true

	if not _argument_error.is_empty():
		printerr("Test runner error: %s" % _argument_error)
		quit(2)
		return true

	var test_files := _get_test_files()
	if not _argument_error.is_empty():
		printerr("Test runner error: %s" % _argument_error)
		quit(2)
		return true
	if test_files.is_empty():
		printerr("Test runner error: no test files found")
		quit(2)
		return true

	var result := _run_test_files(test_files)
	if result.runner_errors > 0:
		quit(2)
	elif result.failed > 0:
		quit(1)
	else:
		quit(0)
	return true


func _parse_arguments(arguments: PackedStringArray) -> void:
	for argument in arguments:
		if argument == "--gdscript-tests":
			continue
		elif argument == "--list":
			_list_only = true
		elif argument.begins_with("--filter="):
			_filter = argument.trim_prefix("--filter=")
		elif argument.begins_with("--file="):
			_single_file = argument.trim_prefix("--file=")
		else:
			_argument_error = "unknown argument '%s'" % argument
			return


func _get_test_files() -> PackedStringArray:
	var files := PackedStringArray()
	if not _single_file.is_empty():
		var path := _single_file
		if not path.begins_with("res://"):
			path = TEST_ROOT.path_join(path)
		if not FileAccess.file_exists(path):
			_argument_error = "test file does not exist: %s" % path
			return files
		files.push_back(path)
	else:
		_discover_test_files(TEST_ROOT, files)
	files.sort()
	return files


func _discover_test_files(path: String, output: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return

	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var entry_path := path.path_join(entry)
			if directory.current_is_dir():
				_discover_test_files(entry_path, output)
			elif entry.ends_with(TEST_FILE_SUFFIX):
				output.push_back(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _run_test_files(test_files: PackedStringArray) -> Dictionary:
	var totals := {
		"tests": 0,
		"passed": 0,
		"failed": 0,
		"runner_errors": 0,
	}

	for test_file in test_files:
		var script := load(test_file) as Script
		if script == null or not script.can_instantiate():
			_print_runner_error(test_file, "could not load or instantiate test script")
			totals.runner_errors += 1
			continue

		var probe: Object = script.new()
		if not _is_test_fixture(probe):
			_print_runner_error(test_file, "fixture must extend res://tests/test_case.gd")
			totals.runner_errors += 1
			continue

		var test_methods := _get_test_methods(probe)
		if test_methods.is_empty():
			_print_runner_error(test_file, "fixture has no zero-argument test_ methods")
			totals.runner_errors += 1
			continue

		for test_method in test_methods:
			var test_name := "%s::%s" % [test_file.get_file().trim_suffix(".gd"), test_method]
			if not _filter.is_empty() and not _filter.to_lower() in test_name.to_lower():
				continue
			if _list_only:
				print(test_name)
				continue

			totals.tests += 1
			var fixture: Object = script.new()
			fixture.before_each()
			fixture.call(test_method)
			fixture.after_each()

			var failures: Array = fixture._failures
			if failures.is_empty():
				print("[PASS] %s" % test_name)
				totals.passed += 1
			else:
				print("[FAIL] %s" % test_name)
				for failure in failures:
					_print_failure(failure)
				totals.failed += 1

	if not _list_only:
		print("")
		print(
			"Tests: %d | Passed: %d | Failed: %d | Runner errors: %d"
			% [totals.tests, totals.passed, totals.failed, totals.runner_errors]
		)
	return totals


func _is_test_fixture(instance: Object) -> bool:
	return instance.has_method("before_each") \
		and instance.has_method("after_each") \
		and "_failures" in instance \
		and "_assertion_count" in instance


func _get_test_methods(instance: Object) -> PackedStringArray:
	var methods := PackedStringArray()
	for method in instance.get_method_list():
		var method_name := method.name as String
		if method_name.begins_with(TEST_METHOD_PREFIX) and method.args.size() == 0:
			methods.push_back(method_name)
	methods.sort()
	return methods


func _print_failure(failure: Dictionary) -> void:
	printerr("       Expected: %s" % var_to_str(failure.expected))
	printerr("       Actual:   %s" % var_to_str(failure.actual))
	if not (failure.message as String).is_empty():
		printerr("       Message:  %s" % failure.message)


func _print_runner_error(path: String, message: String) -> void:
	printerr("[ERROR] %s: %s" % [path, message])
