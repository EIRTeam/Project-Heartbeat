extends TabbedContainerTab

class_name HBResultsScreenStatsTab


var result: HBResult:
	set(val):
		result = val
		_queue_stats_recalculation()
var song: HBSong:
	set(val):
		song = val
		_queue_stats_recalculation()

class StatsData:
	var median_msec: float
	var mean_msec: float
	var std_dev_msec: float

@onready var stats_histogram: HBStatsHistogram = get_node("%StatsHistogram")
@onready var stats_offset_chart: HBStatsOffsetChart = get_node("%StatsOffsetChart")

var stats_data: StatsData

var task_id: int

var stats_recalculation_queued = false
func _queue_stats_recalculation():
	if not stats_recalculation_queued:
		stats_recalculation_queued = true
		if not is_node_ready():
			await ready
		_do_calculate_stats.call_deferred()

func _do_calculate_stats():
	stats_recalculation_queued = false
	task_id = WorkerThreadPool.add_task(_calculate_stats, true, "Results Screen Stats Tab calculations")
	stats_offset_chart.song = song
	stats_offset_chart.end_time = result._song_end_time

func _calculation_task_completed(data: StatsData):
	stats_data = data
	stats_histogram.offset_map = result._hit_time_offsets
	stats_histogram.mean = data.mean_msec
	stats_histogram.median = data.median_msec
	stats_histogram.std_dev = data.std_dev_msec
	stats_offset_chart.offset_map = result._hit_time_offsets
	stats_offset_chart.judgement_map = result._hit_judgements
	stats_offset_chart.offset_map_times = result._hit_times
	WorkerThreadPool.wait_for_task_completion(task_id)

func _calculate_stats():
	var data := StatsData.new()
	if result._hit_time_offsets.size() > 2:
		var offsets_median := result._hit_time_offsets.duplicate()
		offsets_median.sort()
		if offsets_median.size() % 2 == 0:
			var center_1 := offsets_median.size() / 2
			var center_2 := center_1 + 1
			data.median_msec = (offsets_median[center_1] + offsets_median[center_2]) / 2.0
		else:
			data.median_msec = offsets_median[offsets_median.size()/2]
	data.mean_msec = 0.0
	for val in result._hit_time_offsets:
		data.mean_msec += val
	data.mean_msec = data.mean_msec / float(result._hit_time_offsets.size())
	
	# Standard deviation
	
	var variance := 0.0
	
	for val in result._hit_time_offsets:
		var deviation := (val - data.mean_msec) as float
		variance += deviation * deviation
	variance /= float(result._hit_time_offsets.size()-1)
	data.std_dev_msec = sqrt(variance)
	_calculation_task_completed.call_deferred(data)
	
