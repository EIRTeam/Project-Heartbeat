extends HBoxContainer

signal value_changed(value) # Fired to update values
signal value_change_committed # Fired to commit the previous changes (for UndoRedo)

var property_name: String

# Sets the value without setting off any signal
func sync_value(value):
	pass
