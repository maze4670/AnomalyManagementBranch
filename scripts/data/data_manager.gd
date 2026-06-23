extends Node

const CASE_DOCUMENT_DIR := "res://data/anomalies"
const CASE_REPORT_DIR := "res://data/reports"
const CASE_DOCUMENT_SUFFIX := "_document.json"
const CASE_REPORT_SUFFIX := "_reports.json"
const DEFAULT_START_NODE_ID := "report_001"

func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed


func load_case_document(case_id: String) -> Dictionary:
	return load_json_file("%s/%s_document.json" % [CASE_DOCUMENT_DIR, case_id])


func load_case_reports(case_id: String) -> Dictionary:
	return load_json_file("%s/%s_reports.json" % [CASE_REPORT_DIR, case_id])


func get_available_case_ids() -> Array:
	var document_case_ids: Array = _get_case_ids_from_files(CASE_DOCUMENT_DIR, CASE_DOCUMENT_SUFFIX)
	var report_case_ids: Array = _get_case_ids_from_files(CASE_REPORT_DIR, CASE_REPORT_SUFFIX)
	var available_case_ids: Array = []

	for case_id in document_case_ids:
		if report_case_ids.has(case_id):
			available_case_ids.append(case_id)
		else:
			print("Case document has no matching reports file: %s" % case_id)

	for case_id in report_case_ids:
		if not document_case_ids.has(case_id):
			print("Case reports has no matching document file: %s" % case_id)

	available_case_ids.sort()
	return available_case_ids


func get_eligible_starting_case_entries(case_pool: Dictionary) -> Array:
	var excluded_cases: Array = _get_case_id_list(case_pool.get("exclude_from_starting_pool", []))
	excluded_cases.append_array(_get_case_id_list(case_pool.get("late_game_only_cases", [])))
	return _case_ids_to_entries(_filter_case_ids(get_available_case_ids(), excluded_cases))


func get_eligible_introducible_case_entries(case_pool: Dictionary) -> Array:
	var excluded_cases: Array = _get_case_id_list(case_pool.get("exclude_from_introduction_pool", []))
	excluded_cases.append_array(_get_case_id_list(case_pool.get("exclude_from_new_anomaly_pool", [])))
	excluded_cases.append_array(_get_case_id_list(case_pool.get("late_game_only_cases", [])))
	return _case_ids_to_entries(_filter_case_ids(get_available_case_ids(), excluded_cases))


func get_report_nodes(case_reports: Dictionary) -> Array:
	var report_nodes: Variant = case_reports.get("report_nodes", [])
	if typeof(report_nodes) == TYPE_ARRAY:
		return report_nodes as Array

	var nodes: Variant = case_reports.get("nodes", [])
	if typeof(nodes) == TYPE_ARRAY:
		return nodes as Array

	return []


func get_all_report_route_nodes(case_reports: Dictionary) -> Array:
	var route_nodes: Array = []
	route_nodes.append_array(get_report_nodes(case_reports))

	_append_report_nodes(route_nodes, case_reports.get("stable_nodes", []))
	_append_report_nodes(route_nodes, case_reports.get("failure_nodes", []))

	for special_event in get_special_events(case_reports):
		if typeof(special_event) != TYPE_DICTIONARY:
			continue

		var special_event_data: Dictionary = special_event as Dictionary
		_append_report_nodes(route_nodes, special_event_data.get("nodes", []))
		_append_report_nodes(route_nodes, special_event_data.get("stable_nodes", []))
		_append_report_nodes(route_nodes, special_event_data.get("failure_nodes", []))

	return route_nodes


func find_report_node(case_reports: Dictionary, node_id: String) -> Dictionary:
	if node_id.is_empty():
		return {}

	for node in get_all_report_route_nodes(case_reports):
		if typeof(node) != TYPE_DICTIONARY:
			continue

		var report_node: Dictionary = node as Dictionary
		if str(report_node.get("node_id", "")) == node_id:
			return report_node

	return {}


func is_containment_failure_node(report_node: Dictionary) -> bool:
	var node_type: String = str(report_node.get("node_type", ""))
	var result: String = str(report_node.get("result", ""))
	return node_type == "failure" or node_type == "special_failure" or result == "containment_failed"


func get_special_events(case_reports: Dictionary) -> Array:
	var special_events: Variant = case_reports.get("special_events", [])
	if typeof(special_events) == TYPE_ARRAY:
		return special_events as Array

	return []


func _append_report_nodes(route_nodes: Array, nodes: Variant) -> void:
	if typeof(nodes) == TYPE_ARRAY:
		route_nodes.append_array(nodes as Array)


func _get_case_ids_from_files(directory_path: String, file_suffix: String) -> Array:
	var case_ids: Array = []
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		print("Case directory is missing: %s" % directory_path)
		return case_ids

	directory.list_dir_begin()
	while true:
		var file_name: String = directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if not file_name.ends_with(file_suffix):
			continue

		var case_id: String = file_name.substr(0, file_name.length() - file_suffix.length())
		if not _is_valid_case_id(case_id):
			continue
		if not case_ids.has(case_id):
			case_ids.append(case_id)

	directory.list_dir_end()
	case_ids.sort()
	return case_ids


func _is_valid_case_id(case_id: String) -> bool:
	if case_id.length() != 8:
		return false
	if not case_id.begins_with("case_"):
		return false

	var number_text: String = case_id.substr(5, 3)
	for index in range(number_text.length()):
		var code_point: int = number_text.unicode_at(index)
		if code_point < 48 or code_point > 57:
			return false

	return true


func _get_case_id_list(value: Variant) -> Array:
	var case_ids: Array = []
	if typeof(value) != TYPE_ARRAY:
		return case_ids

	for item in (value as Array):
		var case_id: String = str(item)
		if _is_valid_case_id(case_id) and not case_ids.has(case_id):
			case_ids.append(case_id)

	return case_ids


func _filter_case_ids(case_ids: Array, excluded_cases: Array) -> Array:
	var filtered_case_ids: Array = []
	for case_id in case_ids:
		if excluded_cases.has(case_id):
			continue

		filtered_case_ids.append(case_id)

	return filtered_case_ids


func _case_ids_to_entries(case_ids: Array) -> Array:
	var entries: Array = []
	for case_id in case_ids:
		entries.append({
			"case_id": case_id,
			"start_node_id": DEFAULT_START_NODE_ID,
			"pool_type": "general"
		})

	return entries


func get_report_body(report_node: Dictionary) -> String:
	if report_node.has("body"):
		return str(report_node.get("body", ""))

	return str(report_node.get("report_text", ""))


func get_report_label(report_node: Dictionary, fallback: String = "") -> String:
	if report_node.has("report_day_label"):
		return str(report_node.get("report_day_label", ""))
	if report_node.has("title"):
		return str(report_node.get("title", ""))

	return fallback


func load_day_rules() -> Dictionary:
	return load_json_file("res://data/system/day_rules.json")


func load_case_pool() -> Dictionary:
	return load_json_file("res://data/system/case_pool.json")


func load_new_anomaly_rules() -> Dictionary:
	return load_json_file("res://data/system/new_anomaly_rules.json")


func load_special_event_rules() -> Dictionary:
	return load_json_file("res://data/system/special_event_rules.json")


func load_briefing_messages() -> Dictionary:
	return load_json_file("res://data/text/briefing_messages.json")


func load_ui_messages() -> Dictionary:
	return load_json_file("res://data/text/ui_messages.json")


func validate_development_data() -> Array:
	var messages: Array = []

	_validate_case_document("case_001", messages)
	_validate_case_document("case_002", messages)
	_validate_case_reports("case_001", messages)
	_validate_case_reports("case_002", messages)
	_validate_case_pool(messages)
	_validate_special_event_rules(messages)

	return messages


func print_development_data_validation() -> void:
	var messages: Array = validate_development_data()
	if messages.is_empty():
		print("Development data validation passed.")
		return

	for message in messages:
		print(str(message))


func _validate_case_document(case_id: String, messages: Array) -> void:
	var case_document: Dictionary = load_case_document(case_id)
	var label: String = "%s document" % case_id
	if case_document.is_empty():
		messages.append("%s is missing or invalid." % label)
		return

	_validate_required_fields(case_document, [
		"case_id",
		"display_id",
		"alias",
		"category",
		"image_path",
		"basic_description",
		"additional_descriptions",
		"is_test_data",
		"note"
	], label, messages)

	if case_document.has("additional_descriptions") and typeof(case_document.get("additional_descriptions")) != TYPE_ARRAY:
		messages.append("%s additional_descriptions must be an Array." % label)
	if case_document.get("is_test_data", false) != true:
		messages.append("%s is_test_data must be true for current test data." % label)


func _validate_case_reports(case_id: String, messages: Array) -> void:
	var case_reports: Dictionary = load_case_reports(case_id)
	var label: String = "%s reports" % case_id
	if case_reports.is_empty():
		messages.append("%s is missing or invalid." % label)
		return

	_validate_required_fields(case_reports, ["case_id"], label, messages)
	if not case_reports.has("start_node_id") and not case_reports.has("report_nodes"):
		messages.append("%s missing required field: start_node_id" % label)
	if not case_reports.has("nodes") and not case_reports.has("report_nodes"):
		messages.append("%s missing required field: nodes or report_nodes" % label)

	if case_reports.has("is_test_data") and case_reports.get("is_test_data", false) != true:
		messages.append("%s is_test_data must be true for current test data." % label)

	var nodes: Array = get_report_nodes(case_reports)
	if nodes.is_empty():
		messages.append("%s nodes or report_nodes must be a non-empty Array." % label)
		return

	for node_index in range(nodes.size()):
		var node: Variant = nodes[node_index]
		var node_label: String = "%s node %d" % [label, node_index]
		if typeof(node) != TYPE_DICTIONARY:
			messages.append("%s must be a Dictionary." % node_label)
			continue

		var node_data: Dictionary = node as Dictionary
		_validate_required_fields(node_data, ["node_id", "choices"], node_label, messages)
		if not node_data.has("report_text") and not node_data.has("body"):
			messages.append("%s missing required field: report_text or body" % node_label)
		if not node_data.has("report_day_label") and not node_data.has("title"):
			messages.append("%s missing required field: report_day_label or title" % node_label)

		var choices: Variant = node_data.get("choices", [])
		if typeof(choices) != TYPE_ARRAY:
			messages.append("%s choices must be an Array." % node_label)
			continue

		for choice_index in range((choices as Array).size()):
			var choice: Variant = (choices as Array)[choice_index]
			var choice_label: String = "%s choice %d" % [node_label, choice_index]
			if typeof(choice) != TYPE_DICTIONARY:
				messages.append("%s must be a Dictionary." % choice_label)
				continue

			_validate_required_fields(choice as Dictionary, [
				"choice_id",
				"choice_text",
				"next_node_id",
				"state_delta",
				"delay_range"
			], choice_label, messages)


func _validate_case_pool(messages: Array) -> void:
	var case_pool: Dictionary = load_case_pool()
	var label: String = "case_pool"
	if case_pool.is_empty():
		messages.append("%s is missing or invalid." % label)
		return

	_validate_required_fields(case_pool, [
		"is_test_data",
		"note",
		"starting_case_count",
		"exclude_from_starting_pool",
		"exclude_from_introduction_pool",
		"late_game_only_cases"
	], label, messages)

	if case_pool.get("is_test_data", false) != true:
		messages.append("%s is_test_data must be true for current test data." % label)

	_validate_case_id_list(case_pool.get("exclude_from_starting_pool", []), "exclude_from_starting_pool", messages)
	_validate_case_id_list(case_pool.get("exclude_from_introduction_pool", []), "exclude_from_introduction_pool", messages)
	_validate_case_id_list(case_pool.get("late_game_only_cases", []), "late_game_only_cases", messages)


func _validate_case_pool_entries(entries: Variant, label: String, messages: Array) -> void:
	if typeof(entries) != TYPE_ARRAY:
		messages.append("%s must be an Array." % label)
		return

	for index in range((entries as Array).size()):
		var entry: Variant = (entries as Array)[index]
		var entry_label: String = "%s entry %d" % [label, index]
		if typeof(entry) != TYPE_DICTIONARY:
			messages.append("%s must be a Dictionary." % entry_label)
			continue

		_validate_required_fields(entry as Dictionary, [
			"case_id",
			"start_node_id"
		], entry_label, messages)


func _validate_case_id_list(entries: Variant, label: String, messages: Array) -> void:
	if typeof(entries) != TYPE_ARRAY:
		messages.append("%s must be an Array." % label)
		return

	for index in range((entries as Array).size()):
		var case_id: String = str((entries as Array)[index])
		if not _is_valid_case_id(case_id):
			messages.append("%s entry %d must be a case_XXX id." % [label, index])


func _validate_special_event_rules(messages: Array) -> void:
	var special_event_rules: Dictionary = load_special_event_rules()
	var label: String = "special_event_rules"
	if special_event_rules.is_empty():
		messages.append("%s is missing or invalid." % label)
		return

	_validate_required_fields(special_event_rules, [
		"is_test_data",
		"note",
		"rules"
	], label, messages)

	if special_event_rules.get("is_test_data", false) != true:
		messages.append("%s is_test_data must be true for current test data." % label)

	var rules: Variant = special_event_rules.get("rules", [])
	if typeof(rules) != TYPE_ARRAY:
		messages.append("%s rules must be an Array." % label)
		return

	for index in range((rules as Array).size()):
		var rule: Variant = (rules as Array)[index]
		var rule_label: String = "%s rule %d" % [label, index]
		if typeof(rule) != TYPE_DICTIONARY:
			messages.append("%s must be a Dictionary." % rule_label)
			continue

		var rule_data: Dictionary = rule as Dictionary
		_validate_required_fields(rule_data, [
			"event_id",
			"event_type",
			"condition_type"
		], rule_label, messages)

		var condition_type: String = str(rule_data.get("condition_type", ""))
		if condition_type != "has_delayed_reports":
			messages.append("%s condition_type is not supported in current test validation." % rule_label)


func _validate_required_fields(data: Dictionary, required_fields: Array, label: String, messages: Array) -> void:
	for field in required_fields:
		if not data.has(str(field)):
			messages.append("%s missing required field: %s" % [label, str(field)])
