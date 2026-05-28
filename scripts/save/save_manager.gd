extends Node

const CURRENT_RUN_SAVE_PATH := "user://current_run_save.json"


func save_current_run() -> bool:
	var save_data: Dictionary = {
		"save_version": 1,
		"current_day": GameState.current_day,
		"remaining_actions": GameState.remaining_actions,
		"max_actions_per_day": GameState.max_actions_per_day
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
