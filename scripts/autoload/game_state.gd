extends Node

# Stores the minimal shared run state.

var current_day: int = 1
var max_actions_per_day: int = 3
var remaining_actions: int = 3
var completed_reports: Dictionary = {}
var active_reports: Array = [{"case_id": "case_001", "node_id": "report_001"}]
var scheduled_reports: Array = []
var pending_completed_choices: Array = []


func reset_for_new_run() -> void:
	current_day = 1
	max_actions_per_day = 3
	remaining_actions = max_actions_per_day
	completed_reports = {}
	active_reports = [{"case_id": "case_001", "node_id": "report_001"}]
	scheduled_reports = []
	pending_completed_choices = []


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


func record_completed_choice_for_end_day(case_id: String, node_id: String, choice_id: String, next_node_id: String) -> void:
	pending_completed_choices.append({
		"case_id": case_id,
		"node_id": node_id,
		"choice_id": choice_id,
		"next_node_id": next_node_id
	})


func is_report_active(case_id: String, node_id: String) -> bool:
	for report in active_reports:
		if typeof(report) == TYPE_DICTIONARY:
			var report_data: Dictionary = report as Dictionary
			if str(report_data.get("case_id", "")) == case_id and str(report_data.get("node_id", "")) == node_id:
				return true

	return false


func remove_active_report(case_id: String, node_id: String) -> void:
	var remaining_reports: Array = []
	for report in active_reports:
		if typeof(report) == TYPE_DICTIONARY:
			var report_data: Dictionary = report as Dictionary
			if str(report_data.get("case_id", "")) == case_id and str(report_data.get("node_id", "")) == node_id:
				continue
		remaining_reports.append(report)

	active_reports = remaining_reports


func schedule_report(case_id: String, node_id: String, days_remaining: int) -> void:
	if node_id.is_empty():
		return

	scheduled_reports.append({
		"case_id": case_id,
		"node_id": node_id,
		"days_remaining": days_remaining
	})


func tick_scheduled_reports() -> void:
	var remaining_scheduled_reports: Array = []
	for report in scheduled_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var report_data: Dictionary = report as Dictionary
		var case_id: String = str(report_data.get("case_id", ""))
		var node_id: String = str(report_data.get("node_id", ""))
		var days_remaining: int = int(report_data.get("days_remaining", 0)) - 1

		if days_remaining <= 0:
			if not is_report_active(case_id, node_id):
				active_reports.append({
					"case_id": case_id,
					"node_id": node_id
				})
		else:
			report_data["days_remaining"] = days_remaining
			remaining_scheduled_reports.append(report_data)

	scheduled_reports = remaining_scheduled_reports
