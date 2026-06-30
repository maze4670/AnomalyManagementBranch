extends CanvasLayer

const CONTROLLER_NAME := "UIImageLightbox"

var overlay: Control
var dim_background: ColorRect
var enlarged_image: TextureRect
var close_button: Button


static func show_image(owner_node: Node, texture: Texture2D) -> void:
	if owner_node == null or texture == null or not owner_node.is_inside_tree():
		return

	var tree: SceneTree = owner_node.get_tree()
	var controller: CanvasLayer = tree.root.get_node_or_null(CONTROLLER_NAME) as CanvasLayer
	if controller == null:
		var controller_script: Script = load("res://scripts/ui/common/image_lightbox.gd") as Script
		controller = controller_script.new() as CanvasLayer
		controller.name = CONTROLLER_NAME
		tree.root.add_child(controller)
	controller.call("show_texture", texture)


func _ready() -> void:
	layer = 1100
	_build_overlay()
	hide_lightbox()


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		hide_lightbox()
		get_viewport().set_input_as_handled()


func show_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	enlarged_image.texture = texture
	overlay.visible = true
	set_process_unhandled_input(true)
	close_button.grab_focus()


func hide_lightbox() -> void:
	if enlarged_image != null:
		enlarged_image.texture = null
	if overlay != null:
		overlay.visible = false
	set_process_unhandled_input(false)


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "ImageLightboxOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	dim_background = ColorRect.new()
	dim_background.name = "DimBackground"
	dim_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_background.color = Color(0.0, 0.0, 0.0, 0.82)
	dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	overlay.add_child(dim_background)

	var image_bounds := Control.new()
	image_bounds.name = "ImageBounds"
	image_bounds.anchor_left = 0.1
	image_bounds.anchor_top = 0.1
	image_bounds.anchor_right = 0.9
	image_bounds.anchor_bottom = 0.9
	image_bounds.grow_horizontal = Control.GROW_DIRECTION_BOTH
	image_bounds.grow_vertical = Control.GROW_DIRECTION_BOTH
	image_bounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(image_bounds)

	enlarged_image = TextureRect.new()
	enlarged_image.name = "EnlargedImage"
	enlarged_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enlarged_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enlarged_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enlarged_image.mouse_filter = Control.MOUSE_FILTER_STOP
	image_bounds.add_child(enlarged_image)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(112.0, 42.0)
	close_button.anchor_left = 1.0
	close_button.anchor_right = 1.0
	close_button.offset_left = -112.0
	close_button.offset_bottom = 42.0
	close_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.add_theme_color_override("font_color", Color(0.82, 0.9, 0.88, 1.0))
	close_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.035, 0.07, 0.075, 0.96), Color(0.3, 0.5, 0.48, 0.9)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.07, 0.14, 0.14, 0.98), Color(0.48, 0.76, 0.7, 1.0)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.025, 0.055, 0.06, 1.0), Color(0.36, 0.58, 0.55, 1.0)))
	close_button.add_theme_stylebox_override("focus", _make_button_style(Color(0.055, 0.11, 0.11, 0.98), Color(0.48, 0.76, 0.7, 1.0)))
	close_button.pressed.connect(hide_lightbox)
	image_bounds.add_child(close_button)


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			dim_background.accept_event()
			hide_lightbox()


func _make_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
