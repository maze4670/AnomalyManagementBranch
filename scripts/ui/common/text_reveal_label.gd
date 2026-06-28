extends Node

const REVEALER_NAME := "UITextRevealer"

var target_label: Control
var full_text: String = ""
var characters_per_second: float = 55.0
var revealed_characters: float = 0.0
var is_revealing: bool = false


static func reveal(owner: Node, label: Control, text: String, speed: float = 55.0) -> void:
	if owner == null or label == null:
		return

	var revealer: Node = owner.get_node_or_null(REVEALER_NAME)
	if revealer == null:
		var revealer_script: Script = load("res://scripts/ui/common/text_reveal_label.gd") as Script
		revealer = revealer_script.new()
		revealer.name = REVEALER_NAME
		owner.add_child(revealer)
	revealer.call("start", label, text, speed)


func start(label: Control, text: String, speed: float) -> void:
	target_label = label
	full_text = text
	characters_per_second = maxf(speed, 1.0)
	revealed_characters = 0.0
	is_revealing = not full_text.is_empty()
	_set_label_text("")
	_reset_parent_scroll()
	set_process(is_revealing)
	set_process_input(is_revealing)
	if not is_revealing:
		_finish()


func _process(delta: float) -> void:
	if not is_revealing:
		return

	revealed_characters += characters_per_second * delta
	var visible_count: int = mini(int(revealed_characters), full_text.length())
	_set_label_text(full_text.substr(0, visible_count))
	if visible_count >= full_text.length():
		_finish()


func _input(event: InputEvent) -> void:
	if not is_revealing:
		return

	var skip_requested := event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		skip_requested = skip_requested or ((event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not skip_requested:
		return

	get_viewport().set_input_as_handled()
	_finish()


func _finish() -> void:
	is_revealing = false
	_set_label_text(full_text)
	set_process(false)
	set_process_input(false)


func _set_label_text(value: String) -> void:
	if not is_instance_valid(target_label):
		return
	if target_label is Label:
		(target_label as Label).text = value
	elif target_label is RichTextLabel:
		(target_label as RichTextLabel).text = value


func _reset_parent_scroll() -> void:
	var parent: Node = target_label.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			(parent as ScrollContainer).scroll_vertical = 0
			return
		parent = parent.get_parent()
