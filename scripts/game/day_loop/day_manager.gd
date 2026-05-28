extends Node

const BRIEFING_SCENE_PATH := "res://scenes/briefing/BriefingScreen.tscn"
const SAVE_MANAGER_SCRIPT := preload("res://scripts/save/save_manager.gd")


func end_day_minimal(scene_tree: SceneTree) -> void:
	_process_pending_completed_choices()
	GameState.tick_scheduled_reports()
	GameState.advance_day()
	GameState.reset_actions_for_new_day()
	var save_manager: Variant = SAVE_MANAGER_SCRIPT.new()
	save_manager.save_current_run()
	save_manager.free()
	scene_tree.change_scene_to_file(BRIEFING_SCENE_PATH)


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
