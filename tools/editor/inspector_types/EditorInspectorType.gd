extends HBoxContainer

# Emitted by child classes
# warning-ignore:unused_signal
signal value_changed(value) # Fired to update values
# warning-ignore:unused_signal
signal value_change_committed # Fired to commit the previous changes (for UndoRedo)

var property_name: String

# Sets the value without setting off any signal
func sync_value(value):
	pass

func set_params(params):
	pass
