extends Node

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const ENDING_SCENE_PATH := "res://scenes/ending/EndingScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const TRUST_MANAGER_SCRIPT := preload("res://scripts/game/trust/trust_manager.gd")
const ENDING_MANAGER_SCRIPT := preload("res://scripts/game/endings/ending_manager.gd")
const DELAY_PENALTY_DELTA := -1
const DEFAULT_FOLLOWUP_DELAY_DAYS := 1
const SPECIAL_EVENT_ROLL_MAX := 100


func end_day_minimal(scene_tree: SceneTree) -> void:
	if _should_move_to_good_ending():
		_move_to_ending(scene_tree, "good")
		return

	_increase_delay_for_uncompleted_active_reports()
	_apply_delay_penalties()
	_process_pending_completed_choices()
	GameState.tick_scheduled_reports()
	_update_trust_value()
	if _should_move_to_bad_ending():
		_move_to_ending(scene_tree, "bad")
		return

	GameState.increment_stabilized_day_counts()
	_process_stabilized_case_special_event_candidates()
	_try_introduce_new_test_case()
	GameState.advance_day()
	GameState.reset_actions_for_new_day()
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.save_current_run()
	save_manager.free()
	scene_tree.change_scene_to_file(BRIEFING_SCENE_PATH)


func _increase_delay_for_uncompleted_active_reports() -> void:
	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		var case_id: String = str(active_report_data.get("case_id", ""))
		var node_id: String = str(active_report_data.get("node_id", ""))
		if case_id.is_empty() or node_id.is_empty():
			continue

		if not _is_report_pending_completion(case_id, node_id) and not GameState.is_report_completed(case_id, node_id):
			GameState.increase_delay_for_report(case_id, node_id)


func _apply_delay_penalties() -> void:
	for report_key in GameState.delayed_reports.keys():
		var key_parts: PackedStringArray = str(report_key).split(":")
		if key_parts.size() != 2:
			continue

		var case_id: String = key_parts[0]
		var node_id: String = key_parts[1]
		var delay_days: int = int(GameState.delayed_reports.get(report_key, 0))
		if delay_days <= 0:
			continue

		if GameState.has_delay_penalty_been_applied(case_id, node_id, delay_days):
			continue

		GameState.apply_anomaly_state_delta(case_id, DELAY_PENALTY_DELTA)
		GameState.mark_delay_penalty_applied(case_id, node_id, delay_days)


func _process_pending_completed_choices() -> void:
	for completed_choice in GameState.pending_completed_choices:
		if typeof(completed_choice) != TYPE_DICTIONARY:
			continue

		var completed_choice_data: Dictionary = completed_choice as Dictionary
		var case_id: String = str(completed_choice_data.get("case_id", ""))
		var node_id: String = str(completed_choice_data.get("node_id", ""))
		var choice_id: String = str(completed_choice_data.get("choice_id", ""))
		var next_node_id: String = str(completed_choice_data.get("next_node_id", ""))

		_apply_choice_state_delta(case_id, node_id, choice_id)
		GameState.remove_active_report(case_id, node_id)
		if not next_node_id.is_empty():
			var delay_days: int = _get_next_report_delay_days(case_id, node_id, choice_id, next_node_id)
			GameState.schedule_report(case_id, next_node_id, delay_days)

	GameState.pending_completed_choices = []


func _is_report_pending_completion(case_id: String, node_id: String) -> bool:
	for completed_choice in GameState.pending_completed_choices:
		if typeof(completed_choice) != TYPE_DICTIONARY:
			continue

		var completed_choice_data: Dictionary = completed_choice as Dictionary
		if str(completed_choice_data.get("case_id", "")) == case_id and str(completed_choice_data.get("node_id", "")) == node_id:
			return true

	return false


func _apply_choice_state_delta(case_id: String, node_id: String, choice_id: String) -> void:
	if case_id.is_empty() or node_id.is_empty() or choice_id.is_empty():
		return

	var state_delta: int = _get_choice_state_delta(case_id, node_id, choice_id)
	GameState.apply_anomaly_state_delta(case_id, state_delta)


func _get_choice_state_delta(case_id: String, node_id: String, choice_id: String) -> int:
	var choice_data: Dictionary = _get_choice_data(case_id, node_id, choice_id)
	if choice_data.is_empty():
		return 0

	var state_delta: Variant = choice_data.get("state_delta", 0)
	if typeof(state_delta) == TYPE_INT:
		return state_delta

	return 0


func _get_next_report_delay_days(case_id: String, node_id: String, choice_id: String, next_node_id: String) -> int:
	if not _is_general_report_node(case_id, next_node_id):
		return DEFAULT_FOLLOWUP_DELAY_DAYS

	var choice_data: Dictionary = _get_choice_data(case_id, node_id, choice_id)
	if choice_data.is_empty():
		return DEFAULT_FOLLOWUP_DELAY_DAYS

	return _get_delay_days_from_choice(choice_data)


func _get_choice_data(case_id: String, node_id: String, choice_id: String) -> Dictionary:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	var nodes: Array = data_manager.get_all_report_route_nodes(case_reports)
	data_manager.free()

	for node in nodes:
		if typeof(node) != TYPE_DICTIONARY:
			continue

		var report_node: Dictionary = node as Dictionary
		if str(report_node.get("node_id", "")) != node_id:
			continue

		var choices: Array = report_node.get("choices", []) as Array
		for choice in choices:
			if typeof(choice) != TYPE_DICTIONARY:
				continue

			var choice_data: Dictionary = choice as Dictionary
			if str(choice_data.get("choice_id", "")) != choice_id:
				continue

			return choice_data

	return {}


func _is_general_report_node(case_id: String, node_id: String) -> bool:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	var nodes: Array = data_manager.get_report_nodes(case_reports)
	data_manager.free()

	for node in nodes:
		if typeof(node) != TYPE_DICTIONARY:
			continue

		var report_node: Dictionary = node as Dictionary
		if str(report_node.get("node_id", "")) == node_id:
			return true

	return false


func _get_delay_days_from_choice(choice_data: Dictionary) -> int:
	var delay_range: Variant = choice_data.get("delay_range", null)
	if typeof(delay_range) != TYPE_DICTIONARY:
		return DEFAULT_FOLLOWUP_DELAY_DAYS

	var delay_data: Dictionary = delay_range as Dictionary
	var min_delay: Variant = delay_data.get("min", null)
	var max_delay: Variant = delay_data.get("max", null)
	if not _is_number(min_delay) or not _is_number(max_delay):
		return DEFAULT_FOLLOWUP_DELAY_DAYS
	var min_delay_days: int = int(min_delay)
	var max_delay_days: int = int(max_delay)
	if min_delay_days > max_delay_days:
		return DEFAULT_FOLLOWUP_DELAY_DAYS

	var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
	random_number_generator.randomize()
	return random_number_generator.randi_range(min_delay_days, max_delay_days)


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _update_trust_value() -> void:
	var trust_manager: Variant = TRUST_MANAGER_SCRIPT.new()
	var calculated_trust: int = trust_manager.calculate_trust_from_anomaly_states(GameState.anomaly_states)
	trust_manager.free()
	GameState.set_trust_value(calculated_trust)


func _should_move_to_bad_ending() -> bool:
	var ending_manager: Variant = ENDING_MANAGER_SCRIPT.new()
	var should_end: bool = ending_manager.is_bad_ending(GameState.get_trust_value())
	ending_manager.free()
	return should_end


func _should_move_to_good_ending() -> bool:
	var ending_manager: Variant = ENDING_MANAGER_SCRIPT.new()
	var should_end: bool = ending_manager.is_good_ending(GameState.current_day)
	ending_manager.free()
	return should_end


func _try_introduce_new_test_case() -> void:
	if GameState.current_day < 1:
		return

	var next_case_report: Dictionary = GameState.get_next_test_case_to_introduce()
	if next_case_report.is_empty():
		return

	GameState.introduce_case_report(
		str(next_case_report.get("case_id", "")),
		str(next_case_report.get("node_id", ""))
	)


func _process_stabilized_case_special_event_candidates() -> void:
	for case_id in GameState.get_stabilized_case_ids():
		if GameState.has_active_report_for_case(case_id) or GameState.has_scheduled_report_for_case(case_id):
			continue

		var stabilized_days: int = GameState.get_stabilized_day_count(case_id)
		var event_chance: int = _get_special_event_chance(stabilized_days)
		if event_chance <= 0:
			continue
		if not _roll_special_event_chance(event_chance):
			continue

		var special_event: Dictionary = _pick_special_event(case_id)
		if special_event.is_empty():
			continue

		var start_node_id: String = str(special_event.get("start_node_id", ""))
		if start_node_id.is_empty():
			continue
		if GameState.is_report_completed(case_id, start_node_id):
			continue

		GameState.clear_case_stabilized(case_id)
		GameState.introduce_case_report(case_id, start_node_id)


func _get_special_event_chance(stabilized_days: int) -> int:
	if stabilized_days <= 2:
		return 0
	if stabilized_days == 3:
		return 10
	if stabilized_days == 4:
		return 20
	if stabilized_days == 5:
		return 30
	if stabilized_days == 6:
		return 50
	if stabilized_days == 7:
		return 70

	return 100


func _roll_special_event_chance(event_chance: int) -> bool:
	if event_chance >= SPECIAL_EVENT_ROLL_MAX:
		return true

	var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
	random_number_generator.randomize()
	return random_number_generator.randi_range(1, SPECIAL_EVENT_ROLL_MAX) <= event_chance


func _pick_special_event(case_id: String) -> Dictionary:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	var special_events: Array = data_manager.get_special_events(case_reports)
	data_manager.free()

	if special_events.is_empty():
		return {}

	var available_events: Array = []
	for special_event in special_events:
		if typeof(special_event) != TYPE_DICTIONARY:
			continue

		var special_event_data: Dictionary = special_event as Dictionary
		var start_node_id: String = str(special_event_data.get("start_node_id", ""))
		if start_node_id.is_empty():
			continue
		if GameState.is_report_completed(case_id, start_node_id):
			continue

		available_events.append(special_event_data)

	if available_events.is_empty():
		return {}

	var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
	random_number_generator.randomize()
	var event_index: int = random_number_generator.randi_range(0, available_events.size() - 1)
	return available_events[event_index] as Dictionary


func _check_internal_special_event_candidates() -> void:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var special_event_rules: Dictionary = data_manager.load_special_event_rules()
	data_manager.free()

	var rules: Variant = special_event_rules.get("rules", [])
	if typeof(rules) != TYPE_ARRAY:
		return

	for rule in (rules as Array):
		if typeof(rule) != TYPE_DICTIONARY:
			continue

		var rule_data: Dictionary = rule as Dictionary
		if not _is_special_event_condition_met(str(rule_data.get("condition_type", ""))):
			continue

		GameState.add_pending_special_event(
			str(rule_data.get("event_id", "")),
			str(rule_data.get("event_type", "")),
			GameState.current_day
		)


func _is_special_event_condition_met(condition_type: String) -> bool:
	if condition_type == "has_delayed_reports":
		return not GameState.delayed_reports.is_empty()

	return false


func _move_to_ending(scene_tree: SceneTree, ending_type: String) -> void:
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.apply_ending_to_archive(ending_type, _get_current_run_archive_data())
	save_manager.delete_current_run_save()
	save_manager.free()
	scene_tree.set_meta("ending_type", ending_type)
	scene_tree.change_scene_to_file(ENDING_SCENE_PATH)


func _get_current_run_archive_data() -> Dictionary:
	return {
		"completed_reports": GameState.completed_reports,
		"active_reports": GameState.active_reports,
		"current_day": GameState.current_day
	}
