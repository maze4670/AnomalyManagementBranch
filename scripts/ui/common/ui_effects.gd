extends RefCounted

const EFFECT_TWEEN_META := "ui_effect_tween"


static func play_status_reveal(target: CanvasItem) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return

	_kill_effect_tween(target)
	target.modulate.a = 0.0
	var tween: Tween = target.get_tree().create_tween()
	target.set_meta(EFFECT_TWEEN_META, tween)
	tween.tween_property(target, "modulate:a", 1.0, 0.2)


static func play_choice_selected(target: CanvasItem) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return

	_kill_effect_tween(target)
	target.modulate = Color(1.14, 1.1, 0.94, 1.0)
	var tween: Tween = target.get_tree().create_tween()
	target.set_meta(EFFECT_TWEEN_META, tween)
	tween.tween_property(target, "modulate", Color.WHITE, 0.11)


static func play_result_panel_reveal(target: CanvasItem) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return

	_kill_effect_tween(target)
	target.modulate.a = 0.0
	var tween: Tween = target.get_tree().create_tween()
	target.set_meta(EFFECT_TWEEN_META, tween)
	tween.tween_property(target, "modulate:a", 1.0, 0.3)


static func _kill_effect_tween(target: CanvasItem) -> void:
	var existing: Variant = target.get_meta(EFFECT_TWEEN_META, null)
	if existing is Tween and (existing as Tween).is_valid():
		(existing as Tween).kill()
