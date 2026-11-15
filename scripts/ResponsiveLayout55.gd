extends RefCounted
## Layout rules for Fieldwork 5.5. Pure presentation only; no saved-game changes.
## 0 = phone / portrait, 1 = tablet / small PC, 2 = full desktop.
const PHONE_WIDTH: float = 730.0
const DESKTOP_WIDTH: float = 1190.0

static func is_mobile_device() -> bool:
	return OS.get_name() in ["Android", "iOS"]

static func configure_window(window: Window) -> void:
	# Desktop keeps a 1280x720 design canvas. Phones get their own logical
	# reference size, so text and touch targets do NOT shrink to tiny pixels
	# when a 16:9 canvas is shown on a portrait display.
	var pixels: Vector2i = DisplayServer.window_get_size()
	if pixels.x <= 0 or pixels.y <= 0:
		return
	var portrait: bool = float(pixels.x) / float(pixels.y) < 0.92
	var target: Vector2i = Vector2i(1280,720)
	if portrait:
		target = Vector2i(440,800)
	elif is_mobile_device():
		target = Vector2i(960,540)
	if window.content_scale_size != target:
		window.content_scale_size = target

static func mode(window_pixels: Vector2i, viewport_size: Vector2) -> int:
	var physical_width: float = float(window_pixels.x) if window_pixels.x > 0 else viewport_size.x
	var physical_height: float = float(window_pixels.y) if window_pixels.y > 0 else viewport_size.y
	var aspect: float = physical_width / maxf(1.0,physical_height)
	# Portrait is a phone-like layout even on a narrow desktop debug window.
	if is_mobile_device() or aspect < 0.92 or physical_width < PHONE_WIDTH or viewport_size.x < PHONE_WIDTH:
		return 0
	if physical_width < DESKTOP_WIDTH or viewport_size.x < 960.0 or aspect < 1.31:
		return 1
	return 2

static func inspector_width(viewport_width: float) -> float:
	return clampf(viewport_width*0.30,330.0,488.0)

static func map_tab(tab: String) -> bool:
	return tab in ["Farm", "Valley"]
