extends Node

const CURRENT_RUN_SAVE_PATH := "user://current_run_save.json"
const SETTINGS_SAVE_PATH := "user://settings_save.json"
const ARCHIVE_SAVE_PATH := "user://archive_save.json"


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


func load_archive_save() -> Dictionary:
	var default_archive: Dictionary = _get_default_archive_save()
	if not FileAccess.file_exists(ARCHIVE_SAVE_PATH):
		return default_archive

	var file: FileAccess = FileAccess.open(ARCHIVE_SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_archive

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_archive

	var archive_data: Dictionary = parsed as Dictionary
	var unlocked_cases: Variant = archive_data.get("unlocked_cases", default_archive["unlocked_cases"])
	var endings_seen: Variant = archive_data.get("endings_seen", default_archive["endings_seen"])

	if typeof(unlocked_cases) != TYPE_DICTIONARY:
		unlocked_cases = {}
	if typeof(endings_seen) != TYPE_DICTIONARY:
		endings_seen = {}

	var normalized_endings_seen: Dictionary = endings_seen as Dictionary
	return {
		"save_version": int(archive_data.get("save_version", default_archive["save_version"])),
		"unlocked_cases": unlocked_cases as Dictionary,
		"endings_seen": {
			"good": bool(normalized_endings_seen.get("good", false)),
			"bad": bool(normalized_endings_seen.get("bad", false))
		}
	}


func save_archive_save(archive_data: Dictionary) -> bool:
	var json_text: String = JSON.stringify(archive_data)
	var file: FileAccess = FileAccess.open(ARCHIVE_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_text)
	return true


func apply_ending_to_archive(ending_type: String, run_data: Dictionary) -> bool:
	if ending_type != "good" and ending_type != "bad":
		return false

	var archive_data: Dictionary = load_archive_save()
	var endings_seen: Dictionary = archive_data.get("endings_seen", {}) as Dictionary
	endings_seen[ending_type] = true
	archive_data["endings_seen"] = endings_seen

	var unlocked_cases: Dictionary = archive_data.get("unlocked_cases", {}) as Dictionary
	var existing_case_data: Dictionary = {}
	if typeof(unlocked_cases.get("case_001", {})) == TYPE_DICTIONARY:
		existing_case_data = unlocked_cases.get("case_001", {}) as Dictionary

	if str(existing_case_data.get("unlock_level", "")) == "full" and ending_type == "bad":
		return save_archive_save(archive_data)

	var completed_report_keys: Array = _get_completed_report_keys(run_data)
	if ending_type == "good":
		var full_report_keys: Array = _get_existing_unlocked_report_keys(existing_case_data)
		for report_key in completed_report_keys:
			if not full_report_keys.has(report_key):
				full_report_keys.append(report_key)
		unlocked_cases["case_001"] = {
			"unlock_level": "full",
			"unlocked_report_keys": full_report_keys
		}
	else:
		var partial_report_keys: Array = _get_existing_unlocked_report_keys(existing_case_data)
		if completed_report_keys.size() > 0:
			var first_report_key: String = str(completed_report_keys[0])
			if not partial_report_keys.has(first_report_key):
				partial_report_keys.append(first_report_key)
		unlocked_cases["case_001"] = {
			"unlock_level": "partial",
			"unlocked_report_keys": partial_report_keys
		}

	archive_data["unlocked_cases"] = unlocked_cases
	return save_archive_save(archive_data)


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


func _get_default_archive_save() -> Dictionary:
	return {
		"save_version": 1,
		"unlocked_cases": {},
		"endings_seen": {
			"good": false,
			"bad": false
		}
	}


func _get_completed_report_keys(run_data: Dictionary) -> Array:
	var completed_reports: Variant = run_data.get("completed_reports", {})
	if typeof(completed_reports) != TYPE_DICTIONARY:
		return []

	var report_keys: Array = []
	for report_key in (completed_reports as Dictionary).keys():
		report_keys.append(str(report_key))

	return report_keys


func _get_existing_unlocked_report_keys(case_archive_data: Dictionary) -> Array:
	var unlocked_report_keys: Variant = case_archive_data.get("unlocked_report_keys", [])
	if typeof(unlocked_report_keys) != TYPE_ARRAY:
		return []

	var report_keys: Array = []
	for report_key in (unlocked_report_keys as Array):
		report_keys.append(str(report_key))

	return report_keys


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
	var active_reports: Variant = save_data.get("active_reports", _get_default_active_reports())
	if typeof(active_reports) == TYPE_ARRAY:
		GameState.active_reports = active_reports as Array
	else:
		GameState.active_reports = _get_default_active_reports()
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
	var anomaly_states: Variant = save_data.get("anomaly_states", _get_default_anomaly_states())
	if typeof(anomaly_states) == TYPE_DICTIONARY:
		GameState.anomaly_states = anomaly_states as Dictionary
	else:
		GameState.anomaly_states = _get_default_anomaly_states()
	_ensure_default_anomaly_states()
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


func _get_default_active_reports() -> Array:
	return [
		{"case_id": "case_001", "node_id": "report_001"},
		{"case_id": "case_002", "node_id": "report_001"}
	]


func _get_default_anomaly_states() -> Dictionary:
	return {
		"case_001": 0,
		"case_002": 0
	}


func _ensure_default_anomaly_states() -> void:
	var default_anomaly_states: Dictionary = _get_default_anomaly_states()
	for case_id in default_anomaly_states.keys():
		if not GameState.anomaly_states.has(case_id):
			GameState.anomaly_states[case_id] = default_anomaly_states[case_id]
