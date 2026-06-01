extends Node

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
	return load_json_file("res://data/anomalies/%s_document.json" % case_id)


func load_case_reports(case_id: String) -> Dictionary:
	return load_json_file("res://data/reports/%s_reports.json" % case_id)


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


func get_special_events(case_reports: Dictionary) -> Array:
	var special_events: Variant = case_reports.get("special_events", [])
	if typeof(special_events) == TYPE_ARRAY:
		return special_events as Array

	return []


func _append_report_nodes(route_nodes: Array, nodes: Variant) -> void:
	if typeof(nodes) == TYPE_ARRAY:
		route_nodes.append_array(nodes as Array)


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
		"starting_cases",
		"introducible_cases"
	], label, messages)

	if case_pool.get("is_test_data", false) != true:
		messages.append("%s is_test_data must be true for current test data." % label)

	_validate_case_pool_entries(case_pool.get("starting_cases", []), "starting_cases", messages)
	_validate_case_pool_entries(case_pool.get("introducible_cases", []), "introducible_cases", messages)


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
