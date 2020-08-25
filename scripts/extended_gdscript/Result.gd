class_name Result

var ok_value: Ok = null
var error: HBError = null

func is_err():
	return error != null

# Prints the error if there's any and returns if it is an error
func is_err_p() -> bool:
	var err = is_err()
	if err:
		print(error)
		pass
	return err
	
func _init(ok, err):
	ok_value = ok
	error = err
