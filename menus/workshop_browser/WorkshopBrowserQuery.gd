class_name HBWorkshopBrowserQuery

enum SORT_BY_MODES {
	k_EUGCQuery_RankedByTrend = 3,
	k_EUGCQuery_RankedByPublicationDate = 1,
	k_EUGCQuery_RankedByTotalUniqueSubscriptions = 12
}

func make_query(page: int) -> int:
	return -1

func get_query_title() -> String:
	return ""

static func sort_by_mode_to_string(mode: int):
	var text = ""
	match mode:
		SORT_BY_MODES.k_EUGCQuery_RankedByPublicationDate:
			text = "Most Recent"
		SORT_BY_MODES.k_EUGCQuery_RankedByTotalUniqueSubscriptions:
			text = "Most Subscribed"
		SORT_BY_MODES.k_EUGCQuery_RankedByTrend:
			text = "Most Popular this week"
	return text
