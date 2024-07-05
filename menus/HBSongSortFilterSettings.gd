extends HBSerializable

class_name HBSongSortFilterSettings

enum NoteUsageFilterMode {
	FILTER_MODE_ALL,
	FILTER_MODE_CONSOLE_ONLY,
	FILTER_MODE_ARCADE_ONLY
}

var filter_mode := "all"
var filter_mode__possibilities = [
	"all",
	"official",
	"local",
	"workshop",
	"ppd",
	"folders",
	"dsc",
	"mmplus",
	"mmplus_mod"
]

var sort_prop := "title"
var sort_prop__possibilities = [
	"title",
	"artist",
	"highest_score",
	"lowest_score",
	"creator",
	"bpm",
	"_times_played",
]

var workshop_tab_sort_prop = "title"
var workshop_tab_sort_prop__possibilities = sort_prop__possibilities + [
	"_added_time",
	"_released_time",
	"_updated_time"
]

var filter_has_media_only: bool = false
var star_filter_enabled: bool = false
var star_filter_min: int = 0
var star_filter_max: int = 10
var note_usage_filter_mode: NoteUsageFilterMode = NoteUsageFilterMode.FILTER_MODE_ALL

# We don't serialize the search term, it would be silly
var search_term: String

func _init():
	serializable_fields += [
		"filter_mode", "sort_prop", "workshop_tab_sort_prop", "filter_has_media_only", "star_filter_enabled", "star_filter_min",
		"star_filter_max", "note_usage_filter_mode"
	]
func get_serialized_type():
	return "SongSortFilterSettings"
