extends Node

const CURRENT_RUN_SAVE_PATH := "user://current_run_save.json"


func save_current_run() -> bool:
	var save_data: Dictionary = {
		"save_version": 1,
		"current_day": GameState.current_day,
		"remaining_actions": GameState.remaining_actions,
		"max_actions_per_day": GameState.max_actions_per_day,
		"completed_reports": GameState.completed_reports,
		"active_reports": GameState.active_reports,
		"scheduled_reports": GameState.scheduled_reports,
		"pending_completed_choices": GameState.pending_completed_choices,
		"delayed_reports": GameState.delayed_reports
	}
	var json_text: String = JSON.stringify(save_data)
	var file: FileAccess = FileAccess.open(CURRENT_RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_text)
	return true


func current_run_save_exists() -> bool:
	return FileAccess.file_exists(CURRENT_RUN_SAVE_PATH)


func load_current_run_minimal() -> Dictionary:
	if not current_run_save_exists():
		return {}

	var file: FileAccess = FileAccess.open(CURRENT_RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed


func apply_current_run_to_game_state() -> bool:
	var save_data: Dictionary = load_current_run_minimal()
	if save_data.is_empty():
		return false

	if not save_data.has("save_version"):
		return false
	if int(save_data.get("save_version")) != 1:
		return false

	if not save_data.has("current_day"):
		return false
	if not save_data.has("remaining_actions"):
		return false
	if not save_data.has("max_actions_per_day"):
		return false

	GameState.current_day = int(save_data.get("current_day"))
	GameState.remaining_actions = int(save_data.get("remaining_actions"))
	GameState.max_actions_per_day = int(save_data.get("max_actions_per_day"))
	var completed_reports: Variant = save_data.get("completed_reports", {})
	if typeof(completed_reports) == TYPE_DICTIONARY:
		GameState.completed_reports = completed_reports as Dictionary
	else:
		GameState.completed_reports = {}
	var active_reports: Variant = save_data.get("active_reports", [{"case_id": "case_001", "node_id": "report_001"}])
	if typeof(active_reports) == TYPE_ARRAY:
		GameState.active_reports = active_reports as Array
	else:
		GameState.active_reports = [{"case_id": "case_001", "node_id": "report_001"}]
	var scheduled_reports: Variant = save_data.get("scheduled_reports", [])
	if typeof(scheduled_reports) == TYPE_ARRAY:
		GameState.scheduled_reports = scheduled_reports as Array
	else:
		GameState.scheduled_reports = []
	var pending_completed_choices: Variant = save_data.get("pending_completed_choices", [])
	if typeof(pending_completed_choices) == TYPE_ARRAY:
		GameState.pending_completed_choices = pending_completed_choices as Array
	else:
		GameState.pending_completed_choices = []
	var delayed_reports: Variant = save_data.get("delayed_reports", {})
	if typeof(delayed_reports) == TYPE_DICTIONARY:
		GameState.delayed_reports = delayed_reports as Dictionary
	else:
		GameState.delayed_reports = {}
	return true
