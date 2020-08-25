class_name ResultF

static func get_stack_origin(level = 1):
	var stack = get_stack()
	return stack[level+1]

static func make_ok(val) -> Result:
	return Result.new(Ok.new(val), null)

static func make_err(val) -> Result:
	var stack = get_stack_origin()
	return Result.new(null, HBError.new(HBError.OWN_ERRORS.CUSTOM_ERROR, val, stack))

static func wrap_godot_error(error_code) -> Result:
	var stack = get_stack_origin()
	return Result.new(null, HBError.new(error_code, null, stack))
