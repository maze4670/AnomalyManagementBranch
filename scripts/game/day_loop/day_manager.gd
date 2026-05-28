extends Node

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const ENDING_SCENE_PATH := "res://scenes/ending/EndingScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")
const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const TRUST_MANAGER_SCRIPT := preload("res://scripts/game/trust/trust_manager.gd")
const ENDING_MANAGER_SCRIPT := preload("res://scripts/game/endings/ending_manager.gd")
const DELAY_PENALTY_DELTA := -1


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
			GameState.schedule_report(case_id, next_node_id, 1)

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
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	data_manager.free()

	var nodes: Array = case_reports.get("nodes", []) as Array
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

			var state_delta: Variant = choice_data.get("state_delta", 0)
			if typeof(state_delta) == TYPE_INT:
				return state_delta
			return 0

	return 0


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
