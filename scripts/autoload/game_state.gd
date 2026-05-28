extends Node

# Stores the minimal shared run state.

var current_day: int = 1
var max_actions_per_day: int = 3
var remaining_actions: int = 3
var completed_reports: Dictionary = {}
var active_reports: Array = get_default_active_reports()
var scheduled_reports: Array = []
var pending_completed_choices: Array = []
var delayed_reports: Dictionary = {}
var anomaly_states: Dictionary = get_default_anomaly_states()
var applied_delay_penalties: Dictionary = {}
var trust_value: int = 100
var known_cases: Array = ["case_001"]


func reset_for_new_run() -> void:
	current_day = 1
	max_actions_per_day = 3
	remaining_actions = max_actions_per_day
	completed_reports = {}
	active_reports = get_default_active_reports()
	scheduled_reports = []
	pending_completed_choices = []
	delayed_reports = {}
	anomaly_states = get_default_anomaly_states()
	applied_delay_penalties = {}
	trust_value = 100
	known_cases = ["case_001"]


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


func get_default_active_reports() -> Array:
	return [
		{"case_id": "case_001", "node_id": "report_001"}
	]


func get_default_anomaly_states() -> Dictionary:
	return {
		"case_001": 0,
		"case_002": 0
	}


func has_known_case(case_id: String) -> bool:
	return known_cases.has(case_id)


func mark_case_known(case_id: String) -> void:
	if case_id.is_empty():
		return
	if not has_known_case(case_id):
		known_cases.append(case_id)


func get_next_test_case_to_introduce() -> Dictionary:
	if has_known_case("case_002"):
		return {}

	return {
		"case_id": "case_002",
		"node_id": "report_001"
	}


func introduce_case_report(case_id: String, node_id: String) -> void:
	if case_id.is_empty() or node_id.is_empty():
		return
	if is_report_active(case_id, node_id):
		mark_case_known(case_id)
		return
	if is_report_completed(case_id, node_id):
		mark_case_known(case_id)
		return

	active_reports.append({
		"case_id": case_id,
		"node_id": node_id
	})
	mark_case_known(case_id)
	if not anomaly_states.has(case_id):
		anomaly_states[case_id] = 0


func make_report_key(case_id: String, node_id: String) -> String:
	return "%s:%s" % [case_id, node_id]


func mark_report_completed(case_id: String, node_id: String, choice_id: String) -> void:
	completed_reports[make_report_key(case_id, node_id)] = choice_id


func is_report_completed(case_id: String, node_id: String) -> bool:
	return completed_reports.has(make_report_key(case_id, node_id))


func get_completed_report_choice(case_id: String, node_id: String) -> String:
	return str(completed_reports.get(make_report_key(case_id, node_id), ""))


func increase_delay_for_report(case_id: String, node_id: String) -> void:
	var report_key: String = make_report_key(case_id, node_id)
	delayed_reports[report_key] = int(delayed_reports.get(report_key, 0)) + 1


func get_report_delay_days(case_id: String, node_id: String) -> int:
	return int(delayed_reports.get(make_report_key(case_id, node_id), 0))


func clear_delay_for_report(case_id: String, node_id: String) -> void:
	delayed_reports.erase(make_report_key(case_id, node_id))


func get_anomaly_state(case_id: String) -> int:
	return int(anomaly_states.get(case_id, 0))


func apply_anomaly_state_delta(case_id: String, delta: int) -> void:
	anomaly_states[case_id] = get_anomaly_state(case_id) + delta


func set_anomaly_state(case_id: String, value: int) -> void:
	anomaly_states[case_id] = value


func set_trust_value(value: int) -> void:
	trust_value = value


func get_trust_value() -> int:
	return trust_value


func make_delay_penalty_key(case_id: String, node_id: String, delay_days: int) -> String:
	return "%s:%s:%d" % [case_id, node_id, delay_days]


func has_delay_penalty_been_applied(case_id: String, node_id: String, delay_days: int) -> bool:
	return applied_delay_penalties.has(make_delay_penalty_key(case_id, node_id, delay_days))


func mark_delay_penalty_applied(case_id: String, node_id: String, delay_days: int) -> void:
	applied_delay_penalties[make_delay_penalty_key(case_id, node_id, delay_days)] = true


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
