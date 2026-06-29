extends Node

const CONTROLLER_NAME := "UIButtonFeedback"
const HOVER_MODULATE := Color(1.04, 1.04, 1.04, 1.0)
const PRESSED_SCALE := Vector2(0.985, 0.985)
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")

var target_root: Node


static func install(root: Node) -> void:
	if root == null or not root.is_inside_tree() or root.has_node(CONTROLLER_NAME):
		return

	var controller_script: Script = load("res://scripts/ui/common/button_feedback.gd") as Script
	var controller: Node = controller_script.new()
	controller.name = CONTROLLER_NAME
	root.add_child(controller)
	controller.call("setup", root)


func setup(root: Node) -> void:
	target_root = root
	_scan(root)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if target_root == null or not is_instance_valid(target_root):
		return
	if node == target_root or target_root.is_ancestor_of(node):
		_scan(node)


func _scan(node: Node) -> void:
	if node is Button:
		_prepare_button(node as Button)
	for child in node.get_children():
		_scan(child)


func _prepare_button(button: Button) -> void:
	if button.has_meta("ui_feedback_ready"):
		return

	button.set_meta("ui_feedback_ready", true)
	button.set_meta("ui_pointer_hovered", false)
	button.set_meta("ui_focus_hovered", false)
	button.resized.connect(_update_pivot.bind(button))
	button.mouse_entered.connect(_set_pointer_hovered.bind(button, true))
	button.mouse_exited.connect(_set_pointer_hovered.bind(button, false))
	button.focus_entered.connect(_set_focus_hovered.bind(button, true))
	button.focus_exited.connect(_set_focus_hovered.bind(button, false))
	button.button_down.connect(_set_pressed.bind(button, true))
	button.button_up.connect(_set_pressed.bind(button, false))
	_update_pivot(button)


func _update_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _set_pointer_hovered(button: Button, is_hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	var was_hovered: bool = _is_button_hovered(button)
	button.set_meta("ui_pointer_hovered", is_hovered)
	_update_hover_state(button, was_hovered)


func _set_focus_hovered(button: Button, is_hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	var was_hovered: bool = _is_button_hovered(button)
	button.set_meta("ui_focus_hovered", is_hovered)
	_update_hover_state(button, was_hovered)


func _update_hover_state(button: Button, was_hovered: bool) -> void:
	var is_hovered: bool = _is_button_hovered(button)
	button.self_modulate = HOVER_MODULATE if is_hovered else Color.WHITE
	if is_hovered and not was_hovered and not button.disabled:
		AUDIO_FEEDBACK.play_button_hover()


func _is_button_hovered(button: Button) -> bool:
	return bool(button.get_meta("ui_pointer_hovered", false)) or bool(button.get_meta("ui_focus_hovered", false))


func _set_pressed(button: Button, is_pressed: bool) -> void:
	if not is_instance_valid(button):
		return
	button.scale = PRESSED_SCALE if is_pressed else Vector2.ONE
	if is_pressed and not button.disabled:
		_play_button_sound(button)


func _play_button_sound(button: Button) -> void:
	if _has_ancestor_named(button, ["ReportListContainer", "AnomalyListContainer", "ArchiveListContainer"]):
		AUDIO_FEEDBACK.play_report_open()
		return

	var scene: Node = get_tree().current_scene
	var scene_name: String = scene.name if scene != null else ""
	if button.name in ["EndDayButton", "QuitButton"]:
		AUDIO_FEEDBACK.play_danger()
	elif scene_name == "ContainmentFailureScreen":
		AUDIO_FEEDBACK.play_danger()
	elif scene_name == "EndingScreen" and str(get_tree().get_meta("ending_type", "bad")) != "good":
		AUDIO_FEEDBACK.play_danger()
	elif button.name in ["StartWorkButton", "ConfirmButton"]:
		AUDIO_FEEDBACK.play_confirm()
	else:
		AUDIO_FEEDBACK.play_button_click()


func _has_ancestor_named(node: Node, names: Array) -> bool:
	var current: Node = node.get_parent()
	while current != null:
		if current.name in names:
			return true
		current = current.get_parent()
	return false
