extends Node

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")


func end_day_minimal(scene_tree: SceneTree) -> void:
	_increase_delay_for_uncompleted_active_reports()
	_process_pending_completed_choices()
	GameState.tick_scheduled_reports()
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


func _process_pending_completed_choices() -> void:
	for completed_choice in GameState.pending_completed_choices:
		if typeof(completed_choice) != TYPE_DICTIONARY:
			continue

		var completed_choice_data: Dictionary = completed_choice as Dictionary
		var case_id: String = str(completed_choice_data.get("case_id", ""))
		var node_id: String = str(completed_choice_data.get("node_id", ""))
		var next_node_id: String = str(completed_choice_data.get("next_node_id", ""))

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
