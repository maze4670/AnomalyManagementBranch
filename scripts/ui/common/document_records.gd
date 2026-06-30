extends RefCounted

const DATA_MANAGER_SCRIPT := preload("res://scripts/data/data_manager.gd")
const CONTAINER_NAME := "DocumentRecordsContainer"


static func ensure_records_container(basic_description_label: RichTextLabel) -> VBoxContainer:
	if basic_description_label == null:
		return null

	var parent: Node = basic_description_label.get_parent()
	var existing: VBoxContainer = parent.get_node_or_null(CONTAINER_NAME) as VBoxContainer
	if existing != null:
		return existing

	var document_container: VBoxContainer
	if parent is ScrollContainer:
		var scroll_container := parent as ScrollContainer
		scroll_container.remove_child(basic_description_label)
		document_container = VBoxContainer.new()
		document_container.name = "DocumentContentContainer"
		document_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		document_container.add_theme_constant_override("separation", 16)
		scroll_container.add_child(document_container)
		document_container.add_child(basic_description_label)
	else:
		document_container = parent as VBoxContainer

	var records_container := VBoxContainer.new()
	records_container.name = CONTAINER_NAME
	records_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	records_container.add_theme_constant_override("separation", 8)
	document_container.add_child(records_container)
	return records_container


static func populate_records(container: VBoxContainer, records: Array[Dictionary]) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	container.visible = not records.is_empty()
	if records.is_empty():
		return

	var section_title := Label.new()
	section_title.text = "추가 설명"
	section_title.add_theme_font_size_override("font_size", 18)
	section_title.add_theme_color_override("font_color", Color(0.2, 0.27, 0.25, 1.0))
	container.add_child(section_title)

	for record in records:
		_add_record_item(container, record)


static func build_current_run_records(case_id: String) -> Array[Dictionary]:
	var completed_node_ids: Array[String] = []
	for report_key in GameState.completed_reports.keys():
		var key_parts: PackedStringArray = str(report_key).split(":")
		if key_parts.size() == 2 and key_parts[0] == case_id:
			completed_node_ids.append(key_parts[1])
	var records: Array[Dictionary] = _build_records(case_id, completed_node_ids, GameState.completed_reports, true)
	for record in records:
		var report_key: String = GameState.make_report_key(case_id, str(record.get("node_id", "")))
		record["collected_day"] = int(GameState.completed_report_days.get(report_key, 0))
	return records


static func build_archive_records(case_id: String, report_keys: Variant) -> Array[Dictionary]:
	var node_ids: Array[String] = []
	if typeof(report_keys) == TYPE_ARRAY:
		for report_key in (report_keys as Array):
			var key_parts: PackedStringArray = str(report_key).split(":")
			if key_parts.size() == 2 and key_parts[0] == case_id and not node_ids.has(key_parts[1]):
				node_ids.append(key_parts[1])
	return _build_records(case_id, node_ids, {}, false)


static func build_archive_collected_records(case_id: String, saved_records: Variant) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if typeof(saved_records) != TYPE_ARRAY:
		return records
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	var all_nodes: Array = data_manager.get_all_report_route_nodes(case_reports)
	for saved_record in (saved_records as Array):
		if typeof(saved_record) != TYPE_DICTIONARY:
			continue
		var saved: Dictionary = saved_record as Dictionary
		if str(saved.get("case_id", "")) != case_id:
			continue
		var report_parts: PackedStringArray = str(saved.get("report_key", "")).split(":")
		if report_parts.size() != 2:
			continue
		var report_node: Dictionary = _find_node(all_nodes, report_parts[1])
		if report_node.is_empty():
			continue
		var record: Dictionary = {
			"title": str(saved.get("report_title", data_manager.get_report_label(report_node, "보고 기록"))),
			"body": data_manager.get_report_body(report_node),
			"choice": str(saved.get("selected_choice_text", "")),
			"result_title": "",
			"result_body": "",
			"collected_day": int(saved.get("collected_day", 0))
		}
		var result_parts: PackedStringArray = str(saved.get("result_report_key", "")).split(":")
		if result_parts.size() == 2 and result_parts[0] == case_id:
			var result_node: Dictionary = _find_node(all_nodes, result_parts[1])
			if not result_node.is_empty():
				record["result_title"] = data_manager.get_report_label(result_node, "")
				record["result_body"] = data_manager.get_report_body(result_node)
		records.append(record)
	data_manager.free()
	return records


static func _build_records(case_id: String, node_ids: Array[String], completed_reports: Dictionary, include_choices: bool) -> Array[Dictionary]:
	var data_manager: Variant = DATA_MANAGER_SCRIPT.new()
	var case_reports: Dictionary = data_manager.load_case_reports(case_id)
	var all_nodes: Array = data_manager.get_all_report_route_nodes(case_reports)
	var records: Array[Dictionary] = []

	for node_id in node_ids:
		var report_node: Dictionary = _find_node(all_nodes, node_id)
		if report_node.is_empty():
			continue
		var title: String = data_manager.get_report_label(report_node, "보고 기록")
		var body: String = data_manager.get_report_body(report_node)
		var record: Dictionary = {"node_id": node_id, "title": title, "body": body, "choice": "", "result_title": "", "result_body": "", "collected_day": 0}

		if include_choices:
			var choice_id: String = str(completed_reports.get(GameState.make_report_key(case_id, node_id), ""))
			var choice: Dictionary = _find_choice(report_node, choice_id)
			if not choice.is_empty():
				record["choice"] = str(choice.get("choice_text", ""))
				var next_node_id: String = str(choice.get("next_node_id", ""))
				if _has_arrived(case_id, next_node_id):
					var result_node: Dictionary = _find_node(all_nodes, next_node_id)
					if not result_node.is_empty():
						record["result_title"] = data_manager.get_report_label(result_node, "")
						record["result_body"] = data_manager.get_report_body(result_node)
		records.append(record)

	data_manager.free()
	return records


static func _add_record_item(container: VBoxContainer, record: Dictionary) -> void:
	var item := VBoxContainer.new()
	item.add_theme_constant_override("separation", 8)
	container.add_child(item)

	var title: String = str(record.get("title", "보고 기록"))
	var collected_day: int = int(record.get("collected_day", 0))
	if collected_day > 0:
		title = "%d일차 보고 — %s" % [collected_day, title]
	var toggle := Button.new()
	toggle.name = "RecordToggle"
	toggle.text = "▸ %s" % title
	toggle.set_meta("record_title", title)
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.add_theme_font_size_override("font_size", 15)
	toggle.add_theme_color_override("font_color", Color(0.16, 0.21, 0.2, 1.0))
	toggle.add_theme_color_override("font_hover_color", Color(0.05, 0.1, 0.09, 1.0))
	toggle.add_theme_stylebox_override("normal", _make_record_style(Color(0.79, 0.8, 0.74, 0.55)))
	toggle.add_theme_stylebox_override("hover", _make_record_style(Color(0.72, 0.76, 0.7, 0.8)))
	toggle.add_theme_stylebox_override("pressed", _make_record_style(Color(0.68, 0.72, 0.67, 0.9)))
	item.add_child(toggle)

	var detail := VBoxContainer.new()
	detail.name = "RecordDetail"
	detail.visible = false
	detail.add_theme_constant_override("separation", 7)
	item.add_child(detail)
	_add_record_text(detail, "보고 내용", str(record.get("body", "")))
	var choice_text: String = str(record.get("choice", ""))
	if not choice_text.is_empty():
		_add_record_text(detail, "선택한 대응", choice_text)
	var result_title: String = str(record.get("result_title", ""))
	var result_body: String = str(record.get("result_body", ""))
	if not result_title.is_empty() or not result_body.is_empty():
		_add_record_text(detail, "결과 보고", "%s\n%s" % [result_title, result_body])

	toggle.pressed.connect(func() -> void:
		var should_open: bool = not detail.visible
		if should_open:
			for sibling in container.get_children():
				if sibling == item:
					continue
				var sibling_detail: VBoxContainer = sibling.get_node_or_null("RecordDetail") as VBoxContainer
				var sibling_toggle: Button = sibling.get_node_or_null("RecordToggle") as Button
				if sibling_detail != null:
					sibling_detail.visible = false
				if sibling_toggle != null:
					sibling_toggle.text = "▸ %s" % str(sibling_toggle.get_meta("record_title", ""))
		detail.visible = should_open
		toggle.text = "%s %s" % ["▾" if detail.visible else "▸", title]
	)


static func _add_record_text(parent: VBoxContainer, heading: String, text: String) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.text = "%s\n%s" % [heading, text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.14, 0.17, 0.16, 1.0))
	parent.add_child(label)


static func _find_node(nodes: Array, node_id: String) -> Dictionary:
	for node in nodes:
		if typeof(node) == TYPE_DICTIONARY and str((node as Dictionary).get("node_id", "")) == node_id:
			return node as Dictionary
	return {}


static func _find_choice(report_node: Dictionary, choice_id: String) -> Dictionary:
	if choice_id.is_empty():
		return {}
	var choices: Variant = report_node.get("choices", [])
	if typeof(choices) != TYPE_ARRAY:
		return {}
	for choice in (choices as Array):
		if typeof(choice) == TYPE_DICTIONARY and str((choice as Dictionary).get("choice_id", "")) == choice_id:
			return choice as Dictionary
	return {}


static func _has_arrived(case_id: String, node_id: String) -> bool:
	if node_id.is_empty():
		return false
	return GameState.is_report_completed(case_id, node_id) or GameState.is_report_active(case_id, node_id)


static func _make_record_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
