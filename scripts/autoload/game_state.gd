extends Node

# Stores the minimal shared run state.

var current_day: int = 1
var max_actions_per_day: int = 3
var remaining_actions: int = 3
var completed_reports: Dictionary = {}


func reset_for_new_run() -> void:
	current_day = 1
	max_actions_per_day = 3
	remaining_actions = max_actions_per_day
	completed_reports = {}


func reset_actions_for_new_day() -> void:
	remaining_actions = max_actions_per_day


func consume_action() -> bool:
	if remaining_actions <= 0:
		return false

	remaining_actions -= 1
	return true


func advance_day() -> void:
	current_day += 1


func get_action_label() -> String:
	return "[잔여 대응 절차 %d/%d]" % [remaining_actions, max_actions_per_day]


func make_report_key(case_id: String, node_id: String) -> String:
	return "%s:%s" % [case_id, node_id]


func mark_report_completed(case_id: String, node_id: String, choice_id: String) -> void:
	completed_reports[make_report_key(case_id, node_id)] = choice_id


func is_report_completed(case_id: String, node_id: String) -> bool:
	return completed_reports.has(make_report_key(case_id, node_id))


func get_completed_report_choice(case_id: String, node_id: String) -> String:
	return str(completed_reports.get(make_report_key(case_id, node_id), ""))
