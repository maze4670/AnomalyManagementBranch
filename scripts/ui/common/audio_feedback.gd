extends RefCounted

# Audio assets are intentionally not assigned yet. These no-op entry points let a
# later audio pass connect UI sounds without changing the current settings format.

static func play_button_hover() -> void:
	pass


static func play_button_click() -> void:
	pass


static func play_confirm() -> void:
	pass


static func play_danger() -> void:
	pass


static func play_report_open() -> void:
	pass


static func play_text_tick() -> void:
	pass


static func play_bgm(_track_name: String) -> void:
	pass


static func stop_bgm() -> void:
	pass


static func fade_bgm_to(_track_name: String) -> void:
	pass
