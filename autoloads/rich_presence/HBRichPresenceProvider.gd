class_name HBRichPresenceProvider

func _init_rich_presence() -> int:
	return OK

func _tick():
	pass

func _get_tick_rate() -> float:
	return 1.0 / 60.0

func _update_rich_presence(rich_presence_data: HBRichPresence):
	pass
	#match rich_presence_data.current_stage:
		#HBRichPresence.RichPresenceStage.AT_MAIN_MENU:
		#pass
