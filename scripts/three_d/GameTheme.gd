extends RefCounted
## Shared keyboard-readable theme for launcher, forms and game HUD.
const SANS = preload("res://assets/fonts/FieldSans.ttf")
const SERIF = preload("res://assets/fonts/FieldSerif.ttf")
const INK = Color("#233c32")
const PAPER = Color("#f7f4e9")
const GREEN = Color("#3f6652")

static func panel(color: Color = PAPER, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	return style

static func readable_text(background: Color) -> Color:
	if background.a < 0.5:
		return INK
	var luminance := background.srgb_to_linear().get_luminance()
	var dark := (luminance + 0.05) / (INK.srgb_to_linear().get_luminance() + 0.05)
	var light := 1.05 / (luminance + 0.05)
	return Color.WHITE if light > dark else INK

static func button_states(button: Button, normal: StyleBoxFlat, hover: StyleBoxFlat, pressed: StyleBoxFlat) -> void:
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_color_override("font_color", readable_text(normal.bg_color))
	button.add_theme_color_override("font_focus_color", readable_text(normal.bg_color))
	button.add_theme_color_override("font_hover_color", readable_text(hover.bg_color))
	button.add_theme_color_override("font_pressed_color", readable_text(pressed.bg_color))
	button.add_theme_color_override("font_hover_pressed_color", readable_text(pressed.bg_color))

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font = SANS
	theme.default_font_size = 14
	for type in ["Label","Button","CheckBox","CheckButton","LineEdit","TextEdit","OptionButton","PopupMenu","SpinBox"]:
		theme.set_color("font_color",type,INK)
		theme.set_color("font_disabled_color",type,Color("#7e877a"))
		theme.set_color("font_hover_color",type,INK)
		theme.set_color("font_focus_color",type,INK)
		theme.set_color("font_pressed_color",type,INK)
		theme.set_color("font_hover_pressed_color",type,INK)
	theme.set_stylebox("panel","PanelContainer",panel())
	theme.set_stylebox("panel","PopupMenu",panel())
	theme.set_stylebox("panel","AcceptDialog",panel())
	theme.set_stylebox("normal","LineEdit",panel(Color("#fffdf6"),8))
	theme.set_stylebox("focus","LineEdit",focus())
	theme.set_stylebox("normal","Button",panel(Color("#e6eadb"),8))
	theme.set_stylebox("hover","Button",panel(Color("#d4dec9"),8))
	theme.set_stylebox("pressed","Button",panel(Color("#c2d2b6"),8))
	theme.set_stylebox("disabled","Button",panel(Color("#e2e3d8"),8))
	theme.set_stylebox("focus","Button",focus())
	theme.set_stylebox("background","ProgressBar",panel(Color("#dbe1cf"),4))
	theme.set_stylebox("fill","ProgressBar",panel(Color("#7e9c62"),4))
	return theme

static func focus() -> StyleBoxFlat:
	var style := panel(Color.TRANSPARENT,8)
	style.set_border_width_all(2)
	style.border_color = Color("#b88c42")
	return style
