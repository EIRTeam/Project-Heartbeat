extends TabbedContainerTab

@onready var rating_results_container = get_node("%RatingResultsContainer")
@onready var combo_label = get_node("%ComboLabel")
@onready var total_notes_label = get_node("%TotalNotesLabel")
@onready var notes_hit_label = get_node("%NotesHitLabel")

@onready var rating_label: Label = get_node("%RatingLabel")
@onready var percentage_new_record_label: RichTextLabel = get_node("%PercentageNewRecordLabel")
@onready var new_percentage_label: Label = get_node("%NewPercentageLabel")
@onready var percentage_delta_label: Label = get_node("%PercentageDeltaLabel")

@onready var score_new_record_label: RichTextLabel = get_node("%ScoreNewRecordLabel")
@onready var new_score_label: Label = get_node("%NewScoreLabel")
@onready var score_delta_label: Label = get_node("%ScoreDeltaLabel")

@onready var experience_info_container: Control = get_node("%ExperienceInfoContainer")
@onready var experience_gain_label: Label = get_node("%ExperienceGainLabel")
@onready var experience_breakdown_label: Label = get_node("%ExperienceBreakdownLabel")
@onready var to_next_level_label: Label = get_node("%ToNextLevelLabel")
