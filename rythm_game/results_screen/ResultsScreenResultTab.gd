extends TabbedContainerTab

@onready var rating_results_container = get_node("%RatingResultsContainer")
@onready var combo_label = get_node("%ComboLabel")
@onready var total_notes_label = get_node("%TotalNotesLabel")
@onready var notes_hit_label = get_node("%NotesHitLabel")
@onready var level_up_container = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/LevelUpContainer")
@onready var experience_container = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/ExperienceContainer")
@onready var experience_label = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/ExperienceContainer/ExperienceLabel")

@onready var hiscore_percent_label = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/PercentContainer/HBoxContainer/Previous")
@onready var current_percent_label = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/PercentContainer/HBoxContainer/Current")
@onready var hiscore_score_label = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/ScoreContainer/HBoxContainer/Previous")
@onready var current_score_label = get_node("VBoxContainer2/HBoxContainer2/VBoxContainer/HBoxContainer/Panel2/MarginContainer/RatingResultsContainer/ScoreContainer/HBoxContainer/Current")
