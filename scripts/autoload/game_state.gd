extends Node

# Stores the minimal shared run state.

const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")

var current_day: int = 1
var run_id: String = _create_run_id()
var max_actions_per_day: int = 3
var remaining_actions: int = 3
var completed_reports: Dictionary = {}
var completed_report_days: Dictionary = {}
var active_reports: Array = get_default_active_reports()
var scheduled_reports: Array = []
var pending_completed_choices: Array = []
var delayed_reports: Dictionary = {}
var anomaly_states: Dictionary = get_default_anomaly_states()
var applied_delay_penalties: Dictionary = {}
var trust_value: int = 100
var known_cases: Array = get_default_known_cases()
var pending_special_events: Array = []
var stabilized_day_counts: Dictionary = {}
var last_anomaly_introduction_day: int = 1


func reset_for_new_run() -> void:
	current_day = 1
	run_id = _create_run_id()
	max_actions_per_day = 3
	remaining_actions = max_actions_per_day
	completed_reports = {}
	completed_report_days = {}
	active_reports = get_default_active_reports()
	scheduled_reports = []
	pending_completed_choices = []
	delayed_reports = {}
	anomaly_states = get_default_anomaly_states()
	applied_delay_penalties = {}
	trust_value = 100
	known_cases = _case_ids_from_reports(active_reports)
	pending_special_events = []
	stabilized_day_counts = {}
	last_anomaly_introduction_day = current_day


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
	var case_pool: Dictionary = _load_case_pool()
	var starting_cases: Array = _get_starting_case_entries(case_pool)
	var default_reports: Array = _case_pool_entries_to_reports(starting_cases)
	if default_reports.is_empty():
		return [{"case_id": "case_001", "node_id": "report_001"}]

	return default_reports


func get_default_anomaly_states() -> Dictionary:
	var anomaly_state_defaults: Dictionary = {}
	var case_pool: Dictionary = _load_case_pool()
	_add_case_pool_entries_to_anomaly_states(anomaly_state_defaults, _get_new_anomaly_case_entries(case_pool))
	if anomaly_state_defaults.is_empty():
		return {
			"case_001": 0,
			"case_002": 0,
			"case_003": 0
		}

	return anomaly_state_defaults


func get_default_known_cases() -> Array:
	var known_case_defaults: Array = _case_ids_from_reports(active_reports)

	if known_case_defaults.is_empty():
		return ["case_001"]

	return known_case_defaults


func has_known_case(case_id: String) -> bool:
	return known_cases.has(case_id)


func mark_case_known(case_id: String) -> void:
	if case_id.is_empty():
		return
	if not has_known_case(case_id):
		known_cases.append(case_id)


func get_next_test_case_to_introduce() -> Dictionary:
	var case_pool: Dictionary = _load_case_pool()
	var available_cases: Array = _get_unintroduced_new_anomaly_case_entries(case_pool)
	if available_cases.is_empty():
		return {}

	var case_entry: Dictionary = _pick_random_case_entry(available_cases)
	var case_id: String = str(case_entry.get("case_id", ""))
	var node_id: String = str(case_entry.get("start_node_id", ""))
	if case_id.is_empty() or node_id.is_empty():
		return {}

	return {
		"case_id": case_id,
		"node_id": node_id
	}


func has_unintroduced_new_anomaly_case() -> bool:
	var case_pool: Dictionary = _load_case_pool()
	return not _get_unintroduced_new_anomaly_case_entries(case_pool).is_empty()


func get_known_introducible_case_count() -> int:
	var known_introducible_count: int = 0
	var case_pool: Dictionary = _load_case_pool()
	for case_entry in _get_new_anomaly_case_entries(case_pool):
		if typeof(case_entry) != TYPE_DICTIONARY:
			continue

		var case_id: String = str((case_entry as Dictionary).get("case_id", ""))
		if not case_id.is_empty() and has_known_case(case_id):
			known_introducible_count += 1

	return known_introducible_count


func mark_anomaly_introduced(day: int) -> void:
	last_anomaly_introduction_day = day


func get_days_since_last_anomaly_introduction() -> int:
	return max(0, current_day - last_anomaly_introduction_day)


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


func get_active_containment_failure_report() -> Dictionary:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()

	for report in active_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var report_data: Dictionary = report as Dictionary
		var case_id: String = str(report_data.get("case_id", ""))
		var node_id: String = str(report_data.get("node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue

		var case_reports: Dictionary = data_manager.load_case_reports(case_id)
		var report_node: Dictionary = data_manager.find_report_node(case_reports, node_id)
		if report_node.is_empty():
			continue
		if not data_manager.is_containment_failure_node(report_node):
			continue

		data_manager.free()
		return {
			"case_id": case_id,
			"node_id": node_id,
			"report_node": report_node
		}

	data_manager.free()
	return {}


func has_active_containment_failure_report() -> bool:
	return not get_active_containment_failure_report().is_empty()


func has_active_report_for_case(case_id: String) -> bool:
	for report in active_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var report_data: Dictionary = report as Dictionary
		if str(report_data.get("case_id", "")) == case_id:
			return true

	return false


func has_scheduled_report_for_case(case_id: String) -> bool:
	for report in scheduled_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var report_data: Dictionary = report as Dictionary
		if str(report_data.get("case_id", "")) == case_id:
			return true

	return false


func mark_case_stabilized(case_id: String) -> void:
	if case_id.is_empty():
		return

	stabilized_day_counts[case_id] = 0
	mark_case_known(case_id)


func clear_case_stabilized(case_id: String) -> void:
	stabilized_day_counts.erase(case_id)


func get_stabilized_case_ids() -> Array:
	var case_ids: Array = []
	for case_id in stabilized_day_counts.keys():
		case_ids.append(str(case_id))

	return case_ids


func get_stabilized_day_count(case_id: String) -> int:
	return int(stabilized_day_counts.get(case_id, 0))


func increment_stabilized_day_counts() -> void:
	for case_id in stabilized_day_counts.keys():
		stabilized_day_counts[case_id] = get_stabilized_day_count(str(case_id)) + 1


func has_pending_special_event(event_id: String) -> bool:
	for special_event in pending_special_events:
		if typeof(special_event) != TYPE_DICTIONARY:
			continue

		var special_event_data: Dictionary = special_event as Dictionary
		if str(special_event_data.get("event_id", "")) == event_id:
			return true

	return false


func add_pending_special_event(event_id: String, event_type: String, created_day: int) -> void:
	if event_id.is_empty() or has_pending_special_event(event_id):
		return

	pending_special_events.append({
		"event_id": event_id,
		"event_type": event_type,
		"created_day": created_day
	})


func clear_pending_special_events() -> void:
	pending_special_events = []


func _get_starting_case_entries(case_pool: Dictionary) -> Array:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var starting_pool: Array = data_manager.get_eligible_starting_case_entries(case_pool)
	data_manager.free()
	return _pick_random_case_entries(starting_pool, _get_starting_case_count(case_pool))


func _get_unintroduced_new_anomaly_case_entries(case_pool: Dictionary) -> Array:
	var available_cases: Array = []
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var introducible_cases: Array = data_manager.get_eligible_introducible_case_entries(case_pool)
	data_manager.free()
	for case_entry in introducible_cases:
		var case_id: String = str((case_entry as Dictionary).get("case_id", ""))
		if case_id.is_empty() or has_known_case(case_id):
			continue

		available_cases.append(case_entry)

	return available_cases


func _get_new_anomaly_case_entries(case_pool: Dictionary) -> Array:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_entries: Array = data_manager.get_eligible_introducible_case_entries(case_pool)
	data_manager.free()
	return case_entries


func _get_starting_case_count(case_pool: Dictionary) -> int:
	return max(0, int(case_pool.get("starting_case_count", 3)))


func _pick_random_case_entries(case_entries: Array, count: int) -> Array:
	var remaining_entries: Array = case_entries.duplicate()
	var picked_entries: Array = []
	var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
	random_number_generator.randomize()

	while picked_entries.size() < count and not remaining_entries.is_empty():
		var entry_index: int = random_number_generator.randi_range(0, remaining_entries.size() - 1)
		picked_entries.append(remaining_entries[entry_index])
		remaining_entries.remove_at(entry_index)

	return picked_entries


func _pick_random_case_entry(case_entries: Array) -> Dictionary:
	if case_entries.is_empty():
		return {}

	var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
	random_number_generator.randomize()
	var entry_index: int = random_number_generator.randi_range(0, case_entries.size() - 1)
	if typeof(case_entries[entry_index]) != TYPE_DICTIONARY:
		return {}

	return case_entries[entry_index] as Dictionary


func _case_ids_from_reports(reports: Array) -> Array:
	var case_ids: Array = []
	for report in reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var case_id: String = str((report as Dictionary).get("case_id", ""))
		if not case_id.is_empty() and not case_ids.has(case_id):
			case_ids.append(case_id)

	return case_ids


func _load_case_pool() -> Dictionary:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_pool: Dictionary = data_manager.load_case_pool()
	data_manager.free()
	return case_pool


func _case_pool_entries_to_reports(case_entries: Variant) -> Array:
	var reports: Array = []
	if typeof(case_entries) != TYPE_ARRAY:
		return reports

	for case_entry in (case_entries as Array):
		if typeof(case_entry) != TYPE_DICTIONARY:
			continue

		var case_entry_data: Dictionary = case_entry as Dictionary
		var case_id: String = str(case_entry_data.get("case_id", ""))
		var node_id: String = str(case_entry_data.get("start_node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue

		reports.append({
			"case_id": case_id,
			"node_id": node_id
		})

	return reports


func _add_case_pool_entries_to_anomaly_states(anomaly_state_defaults: Dictionary, case_entries: Variant) -> void:
	if typeof(case_entries) != TYPE_ARRAY:
		return

	for case_entry in (case_entries as Array):
		if typeof(case_entry) != TYPE_DICTIONARY:
			continue

		var case_id: String = str((case_entry as Dictionary).get("case_id", ""))
		if not case_id.is_empty():
			anomaly_state_defaults[case_id] = 0


func make_report_key(case_id: String, node_id: String) -> String:
	return "%s:%s" % [case_id, node_id]


func mark_report_completed(case_id: String, node_id: String, choice_id: String) -> void:
	var report_key: String = make_report_key(case_id, node_id)
	completed_reports[report_key] = choice_id
	if not completed_report_days.has(report_key):
		completed_report_days[report_key] = current_day


func _create_run_id() -> String:
	return "%d_%d" % [int(Time.get_unix_time_from_system()), randi()]


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


func is_report_pending_end_day(case_id: String, node_id: String) -> bool:
	for completed_choice in pending_completed_choices:
		if typeof(completed_choice) != TYPE_DICTIONARY:
			continue

		var completed_choice_data: Dictionary = completed_choice as Dictionary
		if str(completed_choice_data.get("case_id", "")) == case_id and str(completed_choice_data.get("node_id", "")) == node_id:
			return true

	return false


func prune_resolved_report_state() -> void:
	var remaining_active_reports: Array = []
	var active_report_keys: Dictionary = {}
	for report in active_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var report_data: Dictionary = report as Dictionary
		var case_id: String = str(report_data.get("case_id", ""))
		var node_id: String = str(report_data.get("node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue
		if is_report_completed(case_id, node_id) and not is_report_pending_end_day(case_id, node_id):
			continue

		var report_key: String = make_report_key(case_id, node_id)
		if active_report_keys.has(report_key):
			continue
		active_report_keys[report_key] = true
		remaining_active_reports.append(report_data)
	active_reports = remaining_active_reports

	var remaining_scheduled_reports: Array = []
	var scheduled_report_keys: Dictionary = {}
	for report in scheduled_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue

		var report_data: Dictionary = report as Dictionary
		var case_id: String = str(report_data.get("case_id", ""))
		var node_id: String = str(report_data.get("node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue
		if is_report_completed(case_id, node_id) or is_report_active(case_id, node_id):
			continue

		var report_key: String = make_report_key(case_id, node_id)
		if scheduled_report_keys.has(report_key):
			continue
		scheduled_report_keys[report_key] = true
		remaining_scheduled_reports.append(report_data)
	scheduled_reports = remaining_scheduled_reports


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
	if case_id.is_empty() or node_id.is_empty():
		return
	if is_report_completed(case_id, node_id) or is_report_active(case_id, node_id):
		return
	for report in scheduled_reports:
		if typeof(report) != TYPE_DICTIONARY:
			continue
		var report_data: Dictionary = report as Dictionary
		if str(report_data.get("case_id", "")) == case_id and str(report_data.get("node_id", "")) == node_id:
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
		if case_id.is_empty() or node_id.is_empty() or is_report_completed(case_id, node_id):
			continue
		var days_remaining: int = int(report_data.get("days_remaining", 0)) - 1

		if days_remaining <= 0:
			introduce_case_report(case_id, node_id)
		else:
			report_data["days_remaining"] = days_remaining
			remaining_scheduled_reports.append(report_data)

	scheduled_reports = remaining_scheduled_reports
