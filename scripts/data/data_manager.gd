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


func load_day_rules() -> Dictionary:
	return load_json_file("res://data/system/day_rules.json")


func load_briefing_messages() -> Dictionary:
	return load_json_file("res://data/text/briefing_messages.json")


func load_ui_messages() -> Dictionary:
	return load_json_file("res://data/text/ui_messages.json")
