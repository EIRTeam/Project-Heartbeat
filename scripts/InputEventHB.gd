extends InputEventAction

class_name InputEventHB

var triggered_actions_count = 0
var event_uid: int
# List of actions triggered together with this event, use action to check for the specific one
var actions = []
var game_time := 0
