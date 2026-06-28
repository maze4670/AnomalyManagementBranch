extends Node

const CONTROLLER_NAME := "UIButtonFeedback"
const HOVER_MODULATE := Color(1.04, 1.04, 1.04, 1.0)
const PRESSED_SCALE := Vector2(0.985, 0.985)

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
	button.resized.connect(_update_pivot.bind(button))
	button.mouse_entered.connect(_set_hovered.bind(button, true))
	button.mouse_exited.connect(_set_hovered.bind(button, false))
	button.focus_entered.connect(_set_hovered.bind(button, true))
	button.focus_exited.connect(_set_hovered.bind(button, false))
	button.button_down.connect(_set_pressed.bind(button, true))
	button.button_up.connect(_set_pressed.bind(button, false))
	_update_pivot(button)


func _update_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _set_hovered(button: Button, is_hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	button.self_modulate = HOVER_MODULATE if is_hovered else Color.WHITE


func _set_pressed(button: Button, is_pressed: bool) -> void:
	if not is_instance_valid(button):
		return
	button.scale = PRESSED_SCALE if is_pressed else Vector2.ONE
