# Any script that interacts with the Project Heartbeat API is licensed under the
# AGPLv3 for the general public and also gives an exclusive, royalty-free license
# for EIRTeam to incorporate it in the game

# Documentation for the scripting system can be found here: https://steamcommunity.com/sharedfiles/filedetails/?id=2398390074

extends ScriptRunnerScript # Do not remove this

# We can use metadata tags so that the script is self-documenting by writing:
# #meta:<meta name>:<contents>
# The available meta tags are: name, description, and usage
# For example:
#meta:name:Example script
#meta:description:The default script
#meta:usage:Select the notes you want to edit

func run_script() -> int:
	# Get selected timing points
	var selected_timing_points := get_selected_timing_points()
	
	# Iterate over them
	# Alternatively, iterate without an index:
	#for point in selected_timing_points:
	for i in range(selected_timing_points.size()):
		var point := selected_timing_points[i] as HBTimingPoint
		
		# You can get points that happen at a certain time
		var points_at_time := get_points_at_time(1000) as Array
		
		# All notes inherit from HBBaseNote, which by itself inherits from HBTimingPoint
		# Check if point is a sustain note
		if point is HBSustainNote:
			pass
		# Check if point is a double note
		elif point is HBDoubleNote:
			pass
		# Check if point is a normal or slide note
		elif point is HBNoteData:
			# HBNoteData has special methods to deal with sliders...
			if point.is_slide_note():
				pass
			# ...and slide chain pieces
			elif point.is_slide_hold_piece():
				pass
		# Check if point is any type of note
		elif point is HBBaseNote:
			# You can set the values of any point property using the set_timing_point_property
			# method, refer to the editor documentation to know which properties are available
			set_timing_point_property(point, "time", 1000)

	# We can also create a new note or timing point
	var new_note = HBNoteData.new()
	new_note.note_type = HBBaseNote.NOTE_TYPE.UP
	new_note.time = 1000	# In ms
	create_timing_point(new_note)

	# Return OK to apply the script's changes, return anything else (such as -1)
	# to cancel it
	return OK
