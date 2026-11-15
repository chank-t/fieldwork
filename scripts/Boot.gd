extends Control
const Layout55 = preload("res://scripts/ResponsiveLayout55.gd")
## Stable native startup UI. Language can be selected BEFORE creating a farmer.
const SAVE_FILE = "user://fieldwork_native_6_0.json"
const V59_SAVE_FILE = "user://fieldwork_native_5_9.json"
const V58_SAVE_FILE = "user://fieldwork_native_5_8.json"
const V57_SAVE_FILE = "user://fieldwork_native_5_7.json"
const V56_SAVE_FILE = "user://fieldwork_native_5_6.json"
const V55_SAVE_FILE = "user://fieldwork_native_5_5.json"
const V54_SAVE_FILE = "user://fieldwork_native_5_4.json"
const V53_SAVE_FILE = "user://fieldwork_native_5_3.json"
const V52_SAVE_FILE = "user://fieldwork_native_5_2.json"
const V51_SAVE_FILE = "user://fieldwork_native_5_1.json"
const V50_SAVE_FILE = "user://fieldwork_native_5_0.json"
const PRIOR_SAVE_FILE = "user://fieldwork_native_4_9.json"
const PREVIOUS_SAVE_FILE = "user://fieldwork_native_4_8.json"
const LEGACY_SAVE_FILE = "user://fieldwork_native_4_5.json"
const OLD_SAVE_FILE = "user://fieldwork_native_4_1.json"
const SETTINGS_FILE = "user://fieldwork_settings.cfg"
var language: String = "en"
var en_button: Button
var es_button: Button

func _ready() -> void:
	Layout55.configure_window(get_window())
	var settings: ConfigFile = ConfigFile.new()
	if settings.load(SETTINGS_FILE) == OK:
		language = str(settings.get_value("presentation","language","en"))
	if not ["en","es"].has(language):
		language = "en"
	$Center/Frame/Content/NewGame.pressed.connect(_launch.bind("new"))
	$Center/Frame/Content/Continue.pressed.connect(_launch.bind("continue"))
	$Center/Frame/Content/Continue.disabled = not _has_previous_save()
	$Center/Frame.custom_minimum_size.x = minf(560.0,maxf(300.0,get_viewport_rect().size.x-30.0))
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = Color("#fffdf6")
	panel.set_corner_radius_all(24)
	panel.content_margin_left = 27.0
	panel.content_margin_right = 27.0
	panel.content_margin_top = 24.0
	panel.content_margin_bottom = 24.0
	$Center/Frame.add_theme_stylebox_override("panel",panel)
	$Center/Frame/Content/Title.add_theme_color_override("font_color",Color("#24543e"))
	for path in ["Center/Frame/Content/NewGame","Center/Frame/Content/Continue"]:
		var control: Button = get_node(path) as Button
		control.add_theme_font_size_override("font_size",18)
		control.add_theme_color_override("font_color",Color("#fffdf7") if path.ends_with("NewGame") else Color("#254737"))
		var box: StyleBoxFlat = StyleBoxFlat.new()
		box.bg_color = Color("#3c7657") if path.ends_with("NewGame") else Color("#e4eedf")
		box.set_corner_radius_all(12)
		box.content_margin_left = 14.0
		box.content_margin_right = 14.0
		box.content_margin_top = 11.0
		box.content_margin_bottom = 11.0
		control.add_theme_stylebox_override("normal",box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	$Center/Frame/Content.add_child(row)
	$Center/Frame/Content.move_child(row,3)
	en_button = Button.new()
	en_button.text = "English"
	en_button.custom_minimum_size.y = 44.0
	en_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	en_button.pressed.connect(_set_language.bind("en"))
	row.add_child(en_button)
	es_button = Button.new()
	es_button.text = "Español"
	es_button.custom_minimum_size.y = 44.0
	es_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	es_button.pressed.connect(_set_language.bind("es"))
	row.add_child(es_button)
	_apply_language()

func _has_previous_save() -> bool:
	for save_path in [SAVE_FILE,V59_SAVE_FILE,V58_SAVE_FILE,V57_SAVE_FILE,V56_SAVE_FILE,V55_SAVE_FILE,V54_SAVE_FILE,V53_SAVE_FILE,V52_SAVE_FILE,V51_SAVE_FILE,V50_SAVE_FILE,PRIOR_SAVE_FILE,PREVIOUS_SAVE_FILE,LEGACY_SAVE_FILE,OLD_SAVE_FILE]:
		for suffix in ["", ".bak", ".bak2"]:
			if FileAccess.file_exists(str(save_path)+suffix):
				return true
	return false

func _set_language(value: String) -> void:
	language = value
	var settings: ConfigFile = ConfigFile.new()
	settings.load(SETTINGS_FILE)
	settings.set_value("presentation","language",language)
	settings.save(SETTINGS_FILE)
	_apply_language()

func _apply_language() -> void:
	$Center/Frame/Content/Subtitle.text = "LA FINCA COMPLETA  |  GODOT NATIVO 6.0" if language == "es" else "COMPLETE FARMING EXPERIENCE  |  NATIVE GODOT 6.0"
	$Center/Frame/Content/About.text = "Gestiona tu finca, consulta el nuevo Compass, completa objetivos y explora ocho regiones del valle." if language == "es" else "Grow your farm, follow the new Farm Compass, complete long-term goals and explore eight valley regions."
	$Center/Frame/Content/NewGame.text = "Crear una finca nueva" if language == "es" else "Create a new farm"
	$Center/Frame/Content/Continue.text = "Continuar partida" if language == "es" else "Continue saved farm"
	$Center/Frame/Content/SmallPrint.text = "Sin conexión · Sin cuenta · Godot 4.4+" if language == "es" else "Offline · No account · Godot 4.4+"
	for button in [en_button,es_button]:
		var box: StyleBoxFlat = StyleBoxFlat.new()
		var selected: bool = (button == es_button and language == "es") or (button == en_button and language == "en")
		box.bg_color = Color("#3c7657") if selected else Color("#e5efe4")
		box.set_corner_radius_all(11)
		button.add_theme_stylebox_override("normal",box)
		button.add_theme_color_override("font_color",Color.WHITE if selected else Color("#284c3b"))
		button.add_theme_font_size_override("font_size",16)

func _launch(mode: String) -> void:
	$Center/Frame/Content/Status.text = "Abriendo la finca..." if language == "es" else "Opening your farm..."
	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	if scene == null:
		$Center/Frame/Content/Status.text = "No se pudo cargar el juego. Revisa el depurador de Godot." if language == "es" else "Unable to load Main.tscn. Check the Godot debugger."
		return
	get_tree().set_meta("fieldwork_boot_mode",mode)
	get_tree().set_meta("fieldwork_language",language)
	var result: int = get_tree().change_scene_to_packed(scene)
	if result != OK:
		$Center/Frame/Content/Status.text = "Error al abrir la finca: " + str(result) if language == "es" else "Scene loading error: " + str(result)
