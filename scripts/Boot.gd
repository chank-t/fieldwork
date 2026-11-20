extends Control
## Launcher over a private 3D farm; it never reads or writes game progress.
const Layout = preload("res://scripts/ResponsiveLayout.gd")
const Farm = preload("res://scripts/NativeFarm.gd")
const ThemeKit = preload("res://scripts/three_d/GameTheme.gd")
const Backdrop = preload("res://scripts/three_d/Backdrop3D.gd")
var language: String = "es"
var status: Label
var continue_button: Button
var frame: PanelContainer

func _ready() -> void:
	Layout.configure_window(get_window())
	DisplayServer.window_set_title("Fieldwork · The Living Valley 3D")
	theme = ThemeKit.create()
	var settings := ConfigFile.new()
	if settings.load("user://fieldwork_settings.cfg") == OK:
		language = str(settings.get_value("presentation","language","es"))
	if language not in ["es","en"]: language = "es"
	_build()
	resized.connect(_resize_card)

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var world := Backdrop.new()
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world)
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.farm.language = language
	var shade := ColorRect.new()
	shade.color = Color(0.10,0.20,0.16,0.12)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var align := CenterContainer.new()
	align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(align)
	frame = PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	frame.add_theme_stylebox_override("panel",ThemeKit.panel(Color(0.97,0.96,0.91,0.97),20))
	align.add_child(frame)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation",16)
	frame.add_child(body)
	_text(body,"THE LIVING VALLEY   /   3D",12,ThemeKit.GREEN)
	var title: Label = _text(body,"Fieldwork",48,ThemeKit.INK)
	title.add_theme_font_override("font",ThemeKit.SERIF)
	_text(body,"Cultiva a tu ritmo." if language == "es" else "A slower kind of growing.",22,ThemeKit.GREEN)
	var intro: Label = _text(body,"Tu tierra. Tus decisiones.\nUna vida nueva en el valle." if language == "es" else "Your land. Your decisions.\nA new life in the valley.",15,Color("#67715e"))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(body,"Empezar una nueva finca" if language == "es" else "Begin a new farm",_launch.bind("new"),true)
	continue_button = _button(body,"Continuar mi partida" if language == "es" else "Continue my farm",_launch.bind("continue"))
	continue_button.disabled = not _has_save()
	var languages := HBoxContainer.new()
	languages.add_theme_constant_override("separation",8)
	body.add_child(languages)
	_button(languages,"Español",_set_language.bind("es"),language == "es")
	_button(languages,"English",_set_language.bind("en"),language == "en")
	_text(body,"24 parcelas · 27 cultivos · 8 regiones" if language == "es" else "24 plots · 27 crops · 8 regions",12,Color("#67715e"))
	_text(body,"Sin conexión · Guardado local" if language == "es" else "Offline · Local saves",12,Color("#67715e"))
	status = _text(body,"",12,ThemeKit.GREEN)
	_resize_card()
	var prefs := ConfigFile.new()
	if prefs.load("user://fieldwork_settings.cfg") == OK:
		world.reduced_motion = bool(prefs.get_value("presentation","reduced_motion",false))
		world.performance_mode59 = str(prefs.get_value("presentation","render_preset_59","balanced"))

func _resize_card() -> void:
	if is_instance_valid(frame): frame.custom_minimum_size.x = minf(410,maxf(240,get_viewport_rect().size.x-70))

func _text(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node

func _button(parent: Node, value: String, callback: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 50
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		ThemeKit.button_states(node, ThemeKit.panel(ThemeKit.GREEN, 9),
			ThemeKit.panel(Color("#355a47"), 9), ThemeKit.panel(Color("#2c4b3b"), 9))
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func _has_save() -> bool:
	for path in [Farm.SAVE_FILE,Farm.V59_SAVE_FILE,Farm.V58_SAVE_FILE,Farm.V57_SAVE_FILE,Farm.PREVIOUS_SAVE_FILE,Farm.V54_SAVE_FILE,Farm.OLDER_SAVE_FILE,Farm.V52_SAVE_FILE,Farm.V51_SAVE_FILE,Farm.V50_SAVE_FILE,Farm.PRIOR_SAVE_FILE,Farm.V48_SAVE_FILE,Farm.LEGACY_SAVE_FILE,Farm.ANCIENT_SAVE_FILE]:
		for suffix in ["",".bak",".bak2"]:
			if FileAccess.file_exists(str(path)+suffix): return true
	return false

func _set_language(value: String) -> void:
	language = value
	var prefs := ConfigFile.new()
	prefs.load("user://fieldwork_settings.cfg")
	prefs.set_value("presentation","language",language)
	prefs.save("user://fieldwork_settings.cfg")
	_build()

func _launch(mode: String) -> void:
	status.text = "Abriendo la finca…" if language == "es" else "Opening your farm…"
	get_tree().set_meta("fieldwork_boot_mode",mode)
	get_tree().set_meta("fieldwork_language",language)
	var result: int = get_tree().change_scene_to_file("res://Main.tscn")
	if result != OK: status.text = "Error: " + error_string(result)
