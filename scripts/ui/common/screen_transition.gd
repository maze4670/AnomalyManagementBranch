extends RefCounted

const LAYER_NAME := "UITransitionLayer"
const FADE_DURATION := 0.22
const AUDIO_FEEDBACK := preload("res://scripts/ui/common/audio_feedback.gd")


static func fade_in(owner: Node) -> void:
	if owner == null or not owner.is_inside_tree():
		return

	var tree: SceneTree = owner.get_tree()
	var layer: CanvasLayer = _get_or_create_layer(tree)
	var overlay: ColorRect = layer.get_node("Overlay") as ColorRect
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if overlay.color.a <= 0.0:
		overlay.color.a = 1.0

	var tween: Tween = tree.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(func() -> void:
		tree.set_meta("ui_transition_busy", false)
		if is_instance_valid(layer):
			layer.queue_free()
	)


static func transition_to_scene(owner: Node, scene_path: String) -> void:
	if owner == null or not owner.is_inside_tree() or scene_path.is_empty():
		return

	var tree: SceneTree = owner.get_tree()
	_fade_out(tree, func() -> void:
		tree.change_scene_to_file(scene_path)
	)


static func fade_then(owner: Node, action: Callable) -> void:
	if owner == null or not owner.is_inside_tree() or not action.is_valid():
		return

	_fade_out(owner.get_tree(), action)


static func _fade_out(tree: SceneTree, action: Callable) -> void:
	if bool(tree.get_meta("ui_transition_busy", false)):
		return

	tree.set_meta("ui_transition_busy", true)
	AUDIO_FEEDBACK.play_scene_transition()
	var layer: CanvasLayer = _get_or_create_layer(tree)
	var overlay: ColorRect = layer.get_node("Overlay") as ColorRect
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.color.a = 0.0

	var tween: Tween = tree.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(action)


static func _get_or_create_layer(tree: SceneTree) -> CanvasLayer:
	var existing: CanvasLayer = tree.root.get_node_or_null(LAYER_NAME) as CanvasLayer
	if existing != null:
		return existing

	var layer := CanvasLayer.new()
	layer.name = LAYER_NAME
	layer.layer = 1000
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.008, 0.014, 0.016, 0.0)
	layer.add_child(overlay)
	tree.root.add_child(layer)
	return layer
