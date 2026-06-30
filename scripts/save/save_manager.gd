extends Node

const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const CURRENT_RUN_SAVE_PATH := "user://current_run_save.json"
const SETTINGS_SAVE_PATH := "user://settings_save.json"
const ARCHIVE_SAVE_PATH := "user://archive_save.json"


func save_current_run() -> bool:
	var save_data: Dictionary = {
		"save_version": 1,
		"run_id": GameState.run_id,
		"current_day": GameState.current_day,
		"remaining_actions": GameState.remaining_actions,
		"max_actions_per_day": GameState.max_actions_per_day,
		"completed_reports": GameState.completed_reports,
		"completed_report_days": GameState.completed_report_days,
		"active_reports": GameState.active_reports,
		"scheduled_reports": GameState.scheduled_reports,
		"pending_completed_choices": GameState.pending_completed_choices,
		"delayed_reports": GameState.delayed_reports,
		"anomaly_states": GameState.anomaly_states,
		"applied_delay_penalties": GameState.applied_delay_penalties,
		"trust_value": GameState.trust_value,
		"known_cases": GameState.known_cases,
		"pending_special_events": GameState.pending_special_events,
		"stabilized_day_counts": GameState.stabilized_day_counts
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
	var collected_records: Variant = archive_data.get("collected_records", [])
	var applied_run_ids: Variant = archive_data.get("applied_run_ids", [])

	if typeof(unlocked_cases) != TYPE_DICTIONARY:
		unlocked_cases = {}
	if typeof(endings_seen) != TYPE_DICTIONARY:
		endings_seen = {}
	if typeof(collected_records) != TYPE_ARRAY:
		collected_records = []
	if typeof(applied_run_ids) != TYPE_ARRAY:
		applied_run_ids = []

	var normalized_endings_seen: Dictionary = endings_seen as Dictionary
	return {
		"save_version": int(archive_data.get("save_version", default_archive["save_version"])),
		"unlocked_cases": unlocked_cases as Dictionary,
		"collected_records": collected_records as Array,
		"applied_run_ids": applied_run_ids as Array,
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
	var run_id: String = str(run_data.get("run_id", ""))
	if run_id.is_empty():
		run_id = _make_legacy_run_id(run_data)
	var applied_run_ids: Array = archive_data.get("applied_run_ids", []) as Array
	if applied_run_ids.has(run_id):
		return true

	var endings_seen: Dictionary = archive_data.get("endings_seen", {}) as Dictionary
	endings_seen[ending_type] = true
	archive_data["endings_seen"] = endings_seen

	var collected_records: Array = archive_data.get("collected_records", []) as Array
	var run_records: Array = _build_current_run_collected_records(run_data, ending_type)
	var new_records: Array = run_records.duplicate(true)
	new_records = _exclude_existing_records(new_records, collected_records)
	if ending_type == "bad":
		new_records = _exclude_legacy_unlocked_records(new_records, archive_data.get("unlocked_cases", {}) as Dictionary, collected_records)
		new_records.shuffle()
		var keep_count: int = ceili(float(new_records.size()) * 0.5)
		var selected_records: Array = []
		for index in range(mini(keep_count, new_records.size())):
			selected_records.append(new_records[index])
		new_records = selected_records

	for record in new_records:
		collected_records.append(record)
	archive_data["collected_records"] = collected_records
	archive_data["unlocked_cases"] = _merge_record_keys_into_unlocked_cases(
		archive_data.get("unlocked_cases", {}) as Dictionary,
		run_records if ending_type == "good" else new_records,
		ending_type
	)
	applied_run_ids.append(run_id)
	archive_data["applied_run_ids"] = applied_run_ids
	return save_archive_save(archive_data)


func _build_current_run_collected_records(run_data: Dictionary, ending_type: String) -> Array:
	var completed_reports: Variant = run_data.get("completed_reports", {})
	if typeof(completed_reports) != TYPE_DICTIONARY:
		return []
	var completed_report_days: Dictionary = run_data.get("completed_report_days", {}) as Dictionary
	var records: Array = []
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()

	for report_key_value in (completed_reports as Dictionary).keys():
		var report_key: String = str(report_key_value)
		var key_parts: PackedStringArray = report_key.split(":")
		if key_parts.size() != 2:
			continue
		var case_id: String = key_parts[0]
		var node_id: String = key_parts[1]
		var case_reports: Dictionary = data_manager.load_case_reports(case_id)
		var report_node: Dictionary = data_manager.find_report_node(case_reports, node_id)
		if report_node.is_empty():
			continue

		var choice_id: String = str((completed_reports as Dictionary).get(report_key_value, ""))
		var choice: Dictionary = _find_report_choice(report_node, choice_id)
		var result_report_key: String = ""
		if not choice.is_empty():
			var next_node_id: String = str(choice.get("next_node_id", ""))
			if _run_report_has_arrived(run_data, case_id, next_node_id):
				result_report_key = GameState.make_report_key(case_id, next_node_id)

		records.append({
			"case_id": case_id,
			"record_key": "%s|%s" % [report_key, choice_id],
			"report_key": report_key,
			"report_title": data_manager.get_report_label(report_node, ""),
			"selected_choice_text": str(choice.get("choice_text", "")),
			"result_report_key": result_report_key,
			"collected_day": int(completed_report_days.get(report_key, run_data.get("current_day", 0))),
			"ending_source": ending_type
		})

	data_manager.free()
	return records


func _find_report_choice(report_node: Dictionary, choice_id: String) -> Dictionary:
	if choice_id.is_empty():
		return {}
	var choices: Variant = report_node.get("choices", [])
	if typeof(choices) != TYPE_ARRAY:
		return {}
	for choice in (choices as Array):
		if typeof(choice) == TYPE_DICTIONARY and str((choice as Dictionary).get("choice_id", "")) == choice_id:
			return choice as Dictionary
	return {}


func _run_report_has_arrived(run_data: Dictionary, case_id: String, node_id: String) -> bool:
	if node_id.is_empty():
		return false
	var report_key: String = GameState.make_report_key(case_id, node_id)
	var completed_reports: Variant = run_data.get("completed_reports", {})
	if typeof(completed_reports) == TYPE_DICTIONARY and (completed_reports as Dictionary).has(report_key):
		return true
	var active_reports: Variant = run_data.get("active_reports", [])
	if typeof(active_reports) == TYPE_ARRAY:
		for active_report in (active_reports as Array):
			if typeof(active_report) != TYPE_DICTIONARY:
				continue
			var report_data: Dictionary = active_report as Dictionary
			if str(report_data.get("case_id", "")) == case_id and str(report_data.get("node_id", "")) == node_id:
				return true
	return false


func _exclude_existing_records(records: Array, existing_records: Array) -> Array:
	var existing_keys: Dictionary = {}
	for record in existing_records:
		if typeof(record) == TYPE_DICTIONARY:
			existing_keys[str((record as Dictionary).get("record_key", ""))] = true
	var new_records: Array = []
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var record_key: String = str((record as Dictionary).get("record_key", ""))
		if record_key.is_empty() or existing_keys.has(record_key):
			continue
		new_records.append(record)
	return new_records


func _exclude_legacy_unlocked_records(records: Array, unlocked_cases: Dictionary, existing_records: Array) -> Array:
	var collected_report_keys: Dictionary = {}
	for record in existing_records:
		if typeof(record) == TYPE_DICTIONARY:
			collected_report_keys[str((record as Dictionary).get("report_key", ""))] = true
	var legacy_report_keys: Dictionary = {}
	for case_id in unlocked_cases.keys():
		if typeof(unlocked_cases.get(case_id, {})) != TYPE_DICTIONARY:
			continue
		for report_key in _get_existing_unlocked_report_keys(unlocked_cases.get(case_id, {}) as Dictionary):
			var report_key_text: String = str(report_key)
			if not collected_report_keys.has(report_key_text):
				legacy_report_keys[report_key_text] = true
	var filtered_records: Array = []
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		if legacy_report_keys.has(str((record as Dictionary).get("report_key", ""))):
			continue
		filtered_records.append(record)
	return filtered_records


func _merge_record_keys_into_unlocked_cases(unlocked_cases: Dictionary, records: Array, ending_type: String) -> Dictionary:
	for record in records:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var record_data: Dictionary = record as Dictionary
		var case_id: String = str(record_data.get("case_id", ""))
		var report_key: String = str(record_data.get("report_key", ""))
		if case_id.is_empty() or report_key.is_empty():
			continue
		var case_data: Dictionary = {}
		if typeof(unlocked_cases.get(case_id, {})) == TYPE_DICTIONARY:
			case_data = unlocked_cases.get(case_id, {}) as Dictionary
		var report_keys: Array = _get_existing_unlocked_report_keys(case_data)
		if not report_keys.has(report_key):
			report_keys.append(report_key)
		var unlock_level: String = str(case_data.get("unlock_level", "partial"))
		if ending_type == "good":
			unlock_level = "full"
		unlocked_cases[case_id] = {
			"unlock_level": unlock_level,
			"unlocked_report_keys": report_keys
		}
	return unlocked_cases


func _make_legacy_run_id(run_data: Dictionary) -> String:
	var identity_data: Dictionary = {
		"current_day": int(run_data.get("current_day", 0)),
		"completed_reports": run_data.get("completed_reports", {})
	}
	return "legacy_%s" % JSON.stringify(identity_data).sha256_text()


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
		"collected_records": [],
		"applied_run_ids": [],
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


func _get_completed_report_keys_by_case_id(run_data: Dictionary) -> Dictionary:
	var completed_reports: Variant = run_data.get("completed_reports", {})
	if typeof(completed_reports) != TYPE_DICTIONARY:
		return {}

	var report_keys_by_case_id: Dictionary = {}
	for report_key in (completed_reports as Dictionary).keys():
		var report_key_text: String = str(report_key)
		var key_parts: PackedStringArray = report_key_text.split(":")
		if key_parts.size() != 2:
			continue

		var case_id: String = key_parts[0]
		if not report_keys_by_case_id.has(case_id):
			report_keys_by_case_id[case_id] = []

		var case_report_keys: Array = report_keys_by_case_id[case_id] as Array
		case_report_keys.append(report_key_text)
		report_keys_by_case_id[case_id] = case_report_keys

	return report_keys_by_case_id


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
	GameState.run_id = str(save_data.get("run_id", ""))
	if GameState.run_id.is_empty():
		GameState.run_id = _make_legacy_run_id(save_data)
	GameState.remaining_actions = int(save_data.get("remaining_actions"))
	GameState.max_actions_per_day = int(save_data.get("max_actions_per_day"))
	var completed_reports: Variant = save_data.get("completed_reports", {})
	if typeof(completed_reports) == TYPE_DICTIONARY:
		GameState.completed_reports = completed_reports as Dictionary
	else:
		GameState.completed_reports = {}
	var completed_report_days: Variant = save_data.get("completed_report_days", {})
	if typeof(completed_report_days) == TYPE_DICTIONARY:
		GameState.completed_report_days = completed_report_days as Dictionary
	else:
		GameState.completed_report_days = {}
	var known_cases: Variant = save_data.get("known_cases", GameState.get_default_known_cases())
	if typeof(known_cases) == TYPE_ARRAY:
		GameState.known_cases = known_cases as Array
	else:
		GameState.known_cases = GameState.get_default_known_cases()
	var active_reports: Variant = save_data.get("active_reports", GameState.get_default_active_reports())
	if typeof(active_reports) == TYPE_ARRAY:
		GameState.active_reports = active_reports as Array
	else:
		GameState.active_reports = GameState.get_default_active_reports()
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
	GameState.prune_resolved_report_state()
	var pending_special_events: Variant = save_data.get("pending_special_events", [])
	if typeof(pending_special_events) == TYPE_ARRAY:
		GameState.pending_special_events = pending_special_events as Array
	else:
		GameState.pending_special_events = []
	var stabilized_day_counts: Variant = save_data.get("stabilized_day_counts", {})
	if typeof(stabilized_day_counts) == TYPE_DICTIONARY:
		GameState.stabilized_day_counts = stabilized_day_counts as Dictionary
	else:
		GameState.stabilized_day_counts = {}
	var delayed_reports: Variant = save_data.get("delayed_reports", {})
	if typeof(delayed_reports) == TYPE_DICTIONARY:
		GameState.delayed_reports = delayed_reports as Dictionary
	else:
		GameState.delayed_reports = {}
	var anomaly_states: Variant = save_data.get("anomaly_states", GameState.get_default_anomaly_states())
	if typeof(anomaly_states) == TYPE_DICTIONARY:
		GameState.anomaly_states = anomaly_states as Dictionary
	else:
		GameState.anomaly_states = GameState.get_default_anomaly_states()
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
	_rebuild_known_cases_from_loaded_progress()
	return true


func _ensure_default_anomaly_states() -> void:
	var default_anomaly_states: Dictionary = GameState.get_default_anomaly_states()
	for case_id in default_anomaly_states.keys():
		if not GameState.anomaly_states.has(case_id):
			GameState.anomaly_states[case_id] = default_anomaly_states[case_id]


func _rebuild_known_cases_from_loaded_progress() -> void:
	GameState.known_cases = []
	for report_key in GameState.completed_reports.keys():
		var key_parts: PackedStringArray = str(report_key).split(":")
		if key_parts.size() == 2:
			GameState.mark_case_known(key_parts[0])
	for active_report in GameState.active_reports:
		if typeof(active_report) != TYPE_DICTIONARY:
			continue

		var active_report_data: Dictionary = active_report as Dictionary
		GameState.mark_case_known(str(active_report_data.get("case_id", "")))
	for scheduled_report in GameState.scheduled_reports:
		if typeof(scheduled_report) != TYPE_DICTIONARY:
			continue

		var scheduled_report_data: Dictionary = scheduled_report as Dictionary
		GameState.mark_case_known(str(scheduled_report_data.get("case_id", "")))
	for case_id in GameState.get_stabilized_case_ids():
		GameState.mark_case_known(str(case_id))
