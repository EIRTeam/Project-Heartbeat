class_name HBWorkshopBrowserQuery

const SORT_BY_MODES = [
	SteamworksConstants.UGC_QUERY_RANKED_BY_PUBLICATION_DATE,
	SteamworksConstants.UGC_QUERY_RANKED_BY_TOTAL_UNIQUE_SUBSCRIPTIONS,
	SteamworksConstants.UGC_QUERY_RANKED_BY_TREND
]

func make_query(page: int) -> HBSteamUGCQuery:
	return null

func get_query_title() -> String:
	return ""

static func sort_by_mode_to_string(mode: int):
	var text = ""
	match mode:
		SteamworksConstants.UGC_QUERY_RANKED_BY_PUBLICATION_DATE:
			text = "Most Recent"
		SteamworksConstants.UGC_QUERY_RANKED_BY_TOTAL_UNIQUE_SUBSCRIPTIONS:
			text = "Most Subscribed"
		SteamworksConstants.UGC_QUERY_RANKED_BY_TREND:
			text = "Most Popular this week"
	return text

func _apply_sort_mode(sort_mode: SteamworksConstants.UGCQuery, query: HBSteamUGCQuery):
	
	match sort_mode:
		SteamworksConstants.UGC_QUERY_RANKED_BY_PUBLICATION_DATE:
			query.ranked_by_publication_date()
		SteamworksConstants.UGC_QUERY_RANKED_BY_TOTAL_UNIQUE_SUBSCRIPTIONS:
			query.ranked_by_total_unique_subscriptions()
		SteamworksConstants.UGC_QUERY_RANKED_BY_TREND:
			query.ranked_by_trend()
			
