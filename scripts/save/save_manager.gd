extends Node

const CURRENT_RUN_SAVE_PATH := "user://current_run_save.json"
const SETTINGS_SAVE_PATH := "user://settings_save.json"


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
		"delayed_reports": GameState.delayed_reports,
		"anomaly_states": GameState.anomaly_states,
		"applied_delay_penalties": GameState.applied_delay_penalties,
		"trust_value": GameState.trust_value
	}
	var json_text: String = JSON.stringify(save_data)
	var file: FileAccess = FileAccess.open(CURRENT_RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_text)
	return true


func current_run_save_exists() -> bool:
	return FileAccess.file_exists(CURRENT_RUN_SAVE_PATH)


func delete_current_run_save() -> bool:
	if not current_run_save_exists():
		return true

	var user_dir: DirAccess = DirAccess.open("user://")
	if user_dir == null:
		return false

	return user_dir.remove("current_run_save.json") == OK


func save_settings(settings_data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(settings_data)
	var file: FileAccess = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_text)
	return true


func load_settings() -> Dictionary:
	var default_settings: Dictionary = _get_default_settings()
	if not FileAccess.file_exists(SETTINGS_SAVE_PATH):
		return default_settings

	var file: FileAccess = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_settings

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_settings

	var settings_data: Dictionary = parsed as Dictionary
	return {
		"save_version": int(settings_data.get("save_version", default_settings["save_version"])),
		"volume": int(settings_data.get("volume", default_settings["volume"])),
		"screen_mode": _normalize_screen_mode(str(settings_data.get("screen_mode", default_settings["screen_mode"]))),
		"text_size": _normalize_text_size(str(settings_data.get("text_size", default_settings["text_size"])))
	}


func _get_default_settings() -> Dictionary:
	return {
		"save_version": 1,
		"volume": 100,
		"screen_mode": "windowed",
		"text_size": "normal"
	}


func _normalize_screen_mode(screen_mode: String) -> String:
	if screen_mode == "fullscreen":
		return screen_mode

	return "windowed"


func _normalize_text_size(text_size: String) -> String:
	if text_size == "small" or text_size == "large":
		return text_size

	return "normal"


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
	var anomaly_states: Variant = save_data.get("anomaly_states", {"case_001": 0})
	if typeof(anomaly_states) == TYPE_DICTIONARY:
		GameState.anomaly_states = anomaly_states as Dictionary
	else:
		GameState.anomaly_states = {"case_001": 0}
	var applied_delay_penalties: Variant = save_data.get("applied_delay_penalties", {})
	if typeof(applied_delay_penalties) == TYPE_DICTIONARY:
		GameState.applied_delay_penalties = applied_delay_penalties as Dictionary
	else:
		GameState.applied_delay_penalties = {}
	var trust_value: Variant = save_data.get("trust_value", 100)
	if typeof(trust_value) == TYPE_INT:
		GameState.set_trust_value(int(trust_value))
	else:
		GameState.set_trust_value(100)
	return true
