extends Control
## FIELDWORK NATIVE. The main menu is drawn synchronously in _ready.
## Nothing on the startup path requires Node.js, a web server, or credentials.

const FarmScript = preload("res://scripts/NativeFarm.gd")
const WorldScript = preload("res://scripts/World.gd")
const IsoWorld56 = preload("res://scripts/IsometricWorld56.gd")
const IllustratedScript = preload("res://scripts/IllustratedFarm.gd")
const ValleyScript = preload("res://scripts/Overworld.gd")
const PortraitScript = preload("res://scripts/FarmerPortrait.gd")
const InteriorScript = preload("res://scripts/Interior.gd")
const Data = preload("res://scripts/NativeData.gd")
const Decisions = preload("res://scripts/DecisionContent.gd")
const Chains = preload("res://scripts/ChoiceChains.gd")
const Life = preload("res://scripts/FarmingLife49.gd")
const World50 = preload("res://scripts/WorldWorth50.gd")
const Visual = preload("res://scripts/WorldPresentation.gd")
const Beauty51 = preload("res://scripts/BeautifulFarm51.gd")
const Fields52 = preload("res://scripts/FieldsOpportunity52.gd")
const Style53 = preload("res://scripts/FarmerStyle53.gd")
const Country54 = preload("res://scripts/LivingCountryside54.gd")
const Living57 = preload("res://scripts/LivingFarm57.gd")
const Beyond58 = preload("res://scripts/BeyondFarm58.gd")
const Layout55 = preload("res://scripts/ResponsiveLayout55.gd")
const Performance59 = preload("res://scripts/PerformanceAccessibility59.gd")
const Compass60 = preload("res://scripts/FarmCompass60.gd")

const INK = Color("#263a32")
const MUTED = Color("#687e70")
const BG = Color("#dce9d8")
const PANEL = Color("#fffcf2")
const ACCENT = Color("#347856")
const ACCENT2 = Color("#e0eddb")
const GOLD = Color("#dbb86b")
const DANGER = Color("#b8665a")

var farm: Variant = FarmScript.new()
var scene_root: Control
var game_base: VBoxContainer = null
var game_top_bar: PanelContainer = null
var game_safe_area: MarginContainer = null
var mobile_map_pane: VBoxContainer = null
var mobile_detail_pane: PanelContainer = null
var mobile_inspector_open: bool = false
var mobile_nav_buttons: Dictionary = {}
var primary_nav_buttons: Dictionary = {}
var right_scroll: ScrollContainer
var right_body: VBoxContainer
var world: Variant = null
var valley_view: Variant = null
var selected_region: String = "village"
var movement_bar: HBoxContainer = null
var header_label: Label
var status_label: Label
var active_tab: String = "Farm"
var selected_field: String = "plot1"
var selected_build_slot: int = -1
var selected_garden_slot57: int = 0
var selected_deco_id57: String = ""
var selected_building_kind: String = ""
var language: String = "en"
var speed: int = 0
var speed_accum: float = 0.0
var game_running: bool = false
var pending: Dictionary = {}
var confirm: ConfirmationDialog
var info: AcceptDialog
var import_dialog: FileDialog
var export_dialog: FileDialog
var modal: Control = null
var inside: Control = null
var selected_npc: String = "ines"
var nav_buttons: Dictionary = {}
# 5.5 responsive presentation remains separate from the farm simulation.
var sidebar_open: bool = true
var left_nav_holder: PanelContainer = null
var hud_values: Dictionary = {}
var context_title: Label = null
var context_detail: Label = null
var context_moisture: ProgressBar = null
var context_growth: ProgressBar = null
var context_manage: Button = null
var context_water: Button = null
var context_harvest: Button = null
var overlay_picker: OptionButton = null
var terrain_overlay: String = "none"
var use_25d: bool = true
var plot_status_label: Label = null
var compact_mode: bool = false
var reflow_pending: bool = false
var layout_band: int = 2
var high_contrast: bool = false
var ui_scale: float = 1.0
var visual_weather: bool = true
var visual_growth_labels: bool = true
var visual_animal_moods: bool = true
var reduced_motion: bool = false
var visible_status_labels: bool = false
var ambient_enabled: bool = true
var ambient_volume: float = 0.28
var ambient_player: AudioStreamPlayer = null
# Version 5.9 preferences never alter the economic simulation or its save.
var performance_mode59: String = "balanced"
var show_fps59: bool = false
var overlay_numbers59: bool = true
var fps_label59: Label = null
var fps_accum59: float = 0.0

func _toggle_menu_language() -> void:
	language = "es" if language == "en" else "en"
	_persist_language()
	_show_start_menu()

func _toggle_game_language() -> void:
	language = "es" if language == "en" else "en"
	farm.language = language
	_persist_language()
	# Rebuild all native navigation labels, not only the right-hand panel.
	_show_game()

func _persist_language() -> void:
	var prefs: ConfigFile = ConfigFile.new()
	prefs.load("user://fieldwork_settings.cfg")
	prefs.set_value("presentation","language",language)
	prefs.set_value("presentation","ui_scale",ui_scale)
	prefs.set_value("presentation","high_contrast",high_contrast)
	prefs.set_value("presentation","visual_weather",visual_weather)
	prefs.set_value("presentation","visual_growth_labels",visual_growth_labels)
	prefs.set_value("presentation","visual_animal_moods",visual_animal_moods)
	prefs.set_value("presentation","reduced_motion",reduced_motion)
	prefs.set_value("presentation","visible_status_labels",visible_status_labels)
	prefs.set_value("presentation","ambient_enabled",ambient_enabled)
	prefs.set_value("presentation","ambient_volume",ambient_volume)
	prefs.set_value("presentation","farm_overlay_51",terrain_overlay)
	prefs.set_value("presentation","isometric_56",use_25d)
	prefs.set_value("presentation","sidebar_open_55",sidebar_open)
	prefs.set_value("presentation","render_preset_59",performance_mode59)
	prefs.set_value("presentation","fps_counter_59",show_fps59)
	prefs.set_value("presentation","overlay_numbers_59",overlay_numbers59)
	prefs.save("user://fieldwork_settings.cfg")

func _set_ui_scale(value: float) -> void:
	ui_scale = clampf(value,1.0,1.65)
	_persist_language()
	if game_running:
		_show_game()

func _set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	_persist_language()
	if game_running:
		_show_game()

func _set_performance59(value: String) -> void:
	performance_mode59 = Performance59.normalize_preset(value)
	_persist_language()
	_apply_visual_preferences(world)
	if valley_view != null and is_instance_valid(valley_view):
		valley_view.performance_mode59 = performance_mode59
		valley_view.queue_redraw()
	if game_running:
		_render_panel()

func _toggle_fps59(enabled: bool) -> void:
	show_fps59 = enabled
	_persist_language()
	if fps_label59 != null and is_instance_valid(fps_label59):
		fps_label59.visible = enabled
		fps_label59.text = "FPS --" if enabled else ""

func _touch_direction59(value: Vector2, is_pressed: bool) -> void:
	if world != null and is_instance_valid(world):
		world.touchscreen_dir = value if is_pressed else Vector2.ZERO

func _set_ambience(enabled: bool) -> void:
	ambient_enabled = enabled
	_persist_language()
	if ambient_player != null and is_instance_valid(ambient_player):
		if enabled:
			_play_ambience()
		else:
			ambient_player.stop()

func _set_ambience_volume(value: float) -> void:
	ambient_volume = clampf(value,0.0,1.0)
	_persist_language()
	if ambient_player != null and is_instance_valid(ambient_player):
		ambient_player.volume_db = linear_to_db(maxf(0.001,ambient_volume))

func _play_ambience() -> void:
	if not game_running or not ambient_enabled or ambient_player == null or not is_instance_valid(ambient_player):
		return
	var season_id: String = World50.season_id(int(farm.state["time"]["season"]))
	var path: String = "res://assets/audio/"+season_id+".wav"
	if not ResourceLoader.exists(path):
		return
	var sample: AudioStream = load(path) as AudioStream
	if sample == null:
		return
	ambient_player.stream = sample
	ambient_player.volume_db = linear_to_db(maxf(0.001,ambient_volume))
	ambient_player.play()

func _set_accessibility(enabled: bool, key: String) -> void:
	match key:
		"motion": reduced_motion = enabled
		"labels": visible_status_labels = enabled
		"numbers": overlay_numbers59 = enabled
	_persist_language()
	_apply_visual_preferences(world)
	if valley_view != null and is_instance_valid(valley_view):
		valley_view.reduced_motion59 = reduced_motion
		valley_view.queue_redraw()

func _choose_field(index: int, ids: Array) -> void:
	selected_field = str(ids[index])
	if world != null:
		world.set_selected(selected_field)
	_render_panel()
	_update_header()

func _select_field_from_menu(field_id: String) -> void:
	if farm.field_of(field_id).is_empty():
		return
	selected_field = field_id
	if world != null:
		world.set_selected(selected_field)
	_render_panel()
	_update_header()

func _choose_npc(index: int, ids: Array) -> void:
	selected_npc = str(ids[index])
	_render_panel()

func _go_from_modal(tab: String) -> void:
	_close_modal()
	_change_tab(tab)

func _apply_visual_preferences(view: Variant) -> void:
	if view == null or not is_instance_valid(view):
		return
	view.show_ambient_effects = visual_weather
	view.show_growth_labels = visual_growth_labels
	view.show_animal_moods = visual_animal_moods
	view.reduced_motion = reduced_motion
	view.high_visibility_labels = visible_status_labels
	view.performance_mode59 = performance_mode59
	view.overlay_numbers59 = overlay_numbers59
	if view.is_inside_tree():
		view.queue_redraw()

func _set_visual_option(enabled: bool, key: String) -> void:
	match key:
		"weather": visual_weather = enabled
		"growth": visual_growth_labels = enabled
		"animals": visual_animal_moods = enabled
	_persist_language()
	_apply_visual_preferences(world)

func _ready() -> void:
	Layout55.configure_window(get_window())
	set_anchors_preset(Control.PRESET_FULL_RECT)
	language = str(get_tree().get_meta("fieldwork_language","en"))
	if not ["en","es"].has(language):
		language = "en"
	farm.language = language
	var settings: ConfigFile = ConfigFile.new()
	if settings.load("user://fieldwork_settings.cfg") == OK:
		ui_scale = clampf(float(settings.get_value("presentation","ui_scale",1.0)),1.0,1.65)
		high_contrast = bool(settings.get_value("presentation","high_contrast",false))
		visual_weather = bool(settings.get_value("presentation","visual_weather",true))
		visual_growth_labels = bool(settings.get_value("presentation","visual_growth_labels",true))
		visual_animal_moods = bool(settings.get_value("presentation","visual_animal_moods",true))
		reduced_motion = bool(settings.get_value("presentation","reduced_motion",false))
		visible_status_labels = bool(settings.get_value("presentation","visible_status_labels",false))
		ambient_enabled = bool(settings.get_value("presentation","ambient_enabled",true))
		ambient_volume = clampf(float(settings.get_value("presentation","ambient_volume",0.28)),0.0,1.0)
		performance_mode59 = Performance59.normalize_preset(str(settings.get_value("presentation","render_preset_59","balanced")))
		show_fps59 = bool(settings.get_value("presentation","fps_counter_59",false))
		overlay_numbers59 = bool(settings.get_value("presentation","overlay_numbers_59",true))
		terrain_overlay = str(settings.get_value("presentation","farm_overlay_51","none"))
		use_25d = bool(settings.get_value("presentation","isometric_56",true))
		if not Beauty51.OVERLAYS.has(terrain_overlay):
			terrain_overlay = "none"
		sidebar_open = bool(settings.get_value("presentation","sidebar_open_55",true))
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if Layout55.is_mobile_device() or Layout55.mode(DisplayServer.window_get_size(),get_viewport_rect().size) == 0:
		ui_scale = maxf(ui_scale,1.22)
	var entry: String = str(get_tree().get_meta("fieldwork_boot_mode", "menu"))
	if get_tree().has_meta("fieldwork_boot_mode"):
		get_tree().remove_meta("fieldwork_boot_mode")
	if entry == "new":
		_show_creator()
	elif entry == "continue":
		_continue()
	else:
		_show_start_menu()

func _layout_band() -> int:
	return Layout55.mode(DisplayServer.window_get_size(),get_viewport_rect().size)

func _on_viewport_size_changed() -> void:
	if Layout55.is_mobile_device():
		Layout55.configure_window(get_window())
	if game_running and not reflow_pending:
		reflow_pending = true
		call_deferred("_reflow_game")

func _reflow_game() -> void:
	reflow_pending = false
	if game_running:
		if scene_root != null and is_instance_valid(scene_root):
			scene_root.anchor_right = 1.0
			scene_root.anchor_bottom = 1.0
			scene_root.offset_left = 0.0
			scene_root.offset_top = 0.0
			scene_root.offset_right = 0.0
			scene_root.offset_bottom = 0.0
		_show_game()

func tx(en: String, es: String) -> String:
	return es if language == "es" else en

func _style(color: Color, radius: int = 14, stroke: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	b.content_margin_left = 12.0
	b.content_margin_right = 12.0
	b.content_margin_top = 9.0
	b.content_margin_bottom = 9.0
	if stroke.a > 0.0:
		b.border_color = stroke
		b.set_border_width_all(1)
	return b

func _text(value: String, font_size: int = 15, color: Color = INK) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",maxi(10,int(round(float(font_size) * ui_scale))))
	label.add_theme_color_override("font_color",color)
	return label

func _button(value: String, cb: Callable, parent: Node, primary: bool = false) -> Button:
	var b: Button = Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(0,48.0 * ui_scale)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size",maxi(12,int(round(14.0 * ui_scale))))
	b.add_theme_stylebox_override("normal", _style(Color("#24563c") if high_contrast and primary else (ACCENT if primary else (Color("#f1f9eb") if high_contrast else ACCENT2)),9))
	b.add_theme_stylebox_override("hover", _style(Color("#a9d2b1"),9))
	b.add_theme_stylebox_override("pressed", _style(Color("#94bd9d"),9))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT,9,Color("#f3b24e")))
	b.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _line(parent: Node, value: String, font_size: int = 14, color: Color = INK) -> Label:
	var label: Label = _text(value,font_size,color)
	if parent is HBoxContainer or parent is HFlowContainer:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

func _vbox(parent: Node, separation: int = 8) -> VBoxContainer:
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation",separation)
	parent.add_child(col)
	return col

func _hbox(parent: Node, separation: int = 7) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation",separation)
	parent.add_child(row)
	return row

func _caption(parent: Node, title: String, subtitle: String = "") -> void:
	_line(parent,title,22,INK)
	if subtitle != "":
		_line(parent,subtitle,13,MUTED)
	var separator: HSeparator = HSeparator.new()
	parent.add_child(separator)

func _select(parent: Node, ids: Array, labels: Array) -> OptionButton:
	# The default OptionButton grows to the longest item and uses OS theme
	# colors. That clipped character-creation selectors and 24-plot choices.
	var menu: OptionButton = OptionButton.new()
	menu.custom_minimum_size = Vector2(0,52.0 * ui_scale)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.fit_to_longest_item = false
	menu.clip_text = true
	menu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu.add_theme_font_size_override("font_size",maxi(14,int(16.0*ui_scale)))
	menu.add_theme_icon_override("arrow",load("res://assets/dropdown_arrow.png"))
	menu.add_theme_color_override("font_color",INK)
	menu.add_theme_color_override("font_hover_color",INK)
	menu.add_theme_color_override("font_pressed_color",INK)
	menu.add_theme_color_override("font_focus_color",INK)
	menu.add_theme_stylebox_override("normal",_style(Color("#fffdf5"),11,Color("#8baf99")))
	menu.add_theme_stylebox_override("hover",_style(Color("#ecf7e9"),11,ACCENT))
	menu.add_theme_stylebox_override("pressed",_style(Color("#dceedd"),11,ACCENT))
	menu.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,11,ACCENT))
	for i in range(ids.size()):
		menu.add_item(str(labels[i]),i)
		menu.set_item_metadata(i,ids[i])
	var popup: PopupMenu = menu.get_popup()
	popup.max_size = Vector2i(mini(450,maxi(260,int(get_viewport_rect().size.x)-38)),345)
	popup.add_theme_stylebox_override("panel",_style(Color("#fbfff7"),11,Color("#92b69f")))
	popup.add_theme_color_override("font_color",INK)
	popup.add_theme_color_override("font_hover_color",INK)
	popup.add_theme_font_size_override("font_size",16)
	parent.add_child(menu)
	if ids.size() > 0:
		menu.select(0)
	return menu

func _spin(parent: Node, initial: float, low: float, high: float, step: float = 1.0) -> SpinBox:
	var input: SpinBox = SpinBox.new()
	input.min_value = low
	input.max_value = high
	input.step = step
	input.value = initial
	input.custom_minimum_size = Vector2(118,42 * ui_scale)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.add_theme_font_size_override("font_size",15)
	parent.add_child(input)
	return input

func _field(parent: Node, starting: String = "", hint: String = "") -> LineEdit:
	var input: LineEdit = LineEdit.new()
	input.text = starting
	input.placeholder_text = hint
	input.custom_minimum_size = Vector2(0,38)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(input)
	return input

func _scenic_background(parent: Control) -> void:
	_background(parent)
	var landscape: TextureRect = TextureRect.new()
	landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	landscape.texture = load("res://assets/cover_landscape.png")
	parent.add_child(landscape)
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tint: ColorRect = ColorRect.new()
	tint.color = Color(0.10,0.20,0.14,0.30)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tint)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _clear_scene() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	game_running = false
	game_safe_area = null
	scene_root = null
	game_base = null
	game_top_bar = null
	mobile_map_pane = null
	mobile_detail_pane = null
	mobile_nav_buttons.clear()
	primary_nav_buttons.clear()
	world = null
	valley_view = null
	movement_bar = null
	plot_status_label = null
	left_nav_holder = null
	hud_values.clear()
	fps_label59 = null
	fps_accum59 = 0.0
	context_title = null
	context_detail = null
	context_moisture = null
	context_growth = null
	context_manage = null
	context_water = null
	context_harvest = null
	overlay_picker = null
	modal = null
	ambient_player = null
	nav_buttons.clear()

func _background(parent: Control) -> void:
	var color: ColorRect = ColorRect.new()
	color.color = BG
	parent.add_child(color)
	color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _show_start_menu() -> void:
	_clear_scene()
	speed = 0
	var layer: Control = Control.new()
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root = layer
	_scenic_background(layer)
	var center: CenterContainer = CenterContainer.new()
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame: PanelContainer = PanelContainer.new()
	frame.custom_minimum_size = Vector2(minf(560.0,maxf(320.0,get_viewport_rect().size.x-32.0)),0)
	frame.add_theme_stylebox_override("panel",_style(PANEL,22))
	center.add_child(frame)
	var body: VBoxContainer = _vbox(frame,14)
	var logo: Label = _line(body,"FIELDWORK",46,ACCENT)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle: Label = _line(body,tx("THE LIVING VALLEY  |  NATIVE GODOT EDITION","EL VALLE VIVO  |  EDICION NATIVA GODOT"),16,MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line(body,tx("A peaceful farm that rewards careful decisions. Begin with one field, learn the soil, and make the valley your own.","Una finca tranquila con decisiones importantes. Empieza con una parcela y haz tuyo el valle."),15)
	_button(tx("Create your farmer","Crear agricultor"),_show_creator,body,true)
	var cont: Button = _button(tx("Continue saved farm","Continuar finca guardada"),_continue,body)
	cont.disabled = true
	for save_path in [FarmScript.SAVE_FILE,FarmScript.V59_SAVE_FILE,FarmScript.V58_SAVE_FILE,FarmScript.V57_SAVE_FILE,FarmScript.PREVIOUS_SAVE_FILE,FarmScript.V54_SAVE_FILE,FarmScript.OLDER_SAVE_FILE,FarmScript.V52_SAVE_FILE,FarmScript.V51_SAVE_FILE,FarmScript.V50_SAVE_FILE,FarmScript.PRIOR_SAVE_FILE,FarmScript.V48_SAVE_FILE,FarmScript.LEGACY_SAVE_FILE,FarmScript.ANCIENT_SAVE_FILE]:
		for suffix in ["", ".bak", ".bak2"]:
			if FileAccess.file_exists(str(save_path)+str(suffix)):
				cont.disabled = false
	_button(tx("Language: English / Espanol","Idioma: English / Espanol"),_toggle_menu_language,body)
	_button(tx("How to play","Cómo jugar"),_show_rules,body)
	var foot: Label = _line(body,"Godot 4.4+  |  Native 6.0  |  Offline  |  No Node.js",12,MUTED)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _continue() -> void:
	var result: Dictionary = farm.load_file()
	if result["ok"]:
		_show_game()
	else:
		_show_start_menu()
		_notify(str(result["error"]))

func _show_rules() -> void:
	_notify(tx("Start with your first plot. Plant, check water and insects, and advance the clock. Sell harvests, buy land, build structures, keep livestock, study courses and learn talents. Every choice costs resources or time. Press Escape to leave an interior.","Empieza con tu parcela. Siembra, revisa agua y plagas, avanza el reloj y vende cosechas. Compra terrenos, construye, cria animales y aprende habilidades."))

func _avatar_field_title53(field: String) -> String:
	var titles: Dictionary = {
		"hair":["Hairstyle","Peinado"],"skin":["Skin tone","Tono de piel"],
		"outfit":["Shirt / coat","Camisa / chaqueta"],"hair_color":["Hair colour","Color de pelo"],
		"pants":["Trousers","Pantalones"],"boots":["Boots","Botas"],
		"hat":["Headwear","Sombrero / gorra"],"accessory":["Accessory","Accesorio"],
		"facial_hair":["Facial hair","Vello facial"],"body":["Body shape","Constitucion"],
		"eyes":["Eye colour","Color de ojos"],"pronouns":["Pronouns","Pronombres"]
	}
	var pair: Array = titles.get(field,[field.capitalize(),field.capitalize()])
	return str(pair[1]) if language == "es" else str(pair[0])

func _read_avatar_editor53(controls: Dictionary) -> Dictionary:
	var answer: Dictionary = Style53.defaults()
	for field in Style53.FIELDS:
		if not controls.has(field):
			continue
		var control: OptionButton = controls[field]
		if control.selected >= 0:
			answer[field] = str(control.get_item_metadata(control.selected))
	return answer

func _refresh_avatar_preview53(preview: Control, controls: Dictionary) -> void:
	preview.call("set_avatar",_read_avatar_editor53(controls))

func _build_avatar_editor53(parent: Node, preview: Control, current: Dictionary, game_state: Dictionary) -> Dictionary:
	var controls: Dictionary = {}
	var chosen: Dictionary = Style53.normalize(current)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",8)
	parent.add_child(grid)
	for field in Style53.FIELDS:
		var keys: Array = Style53.available(field,game_state)
		var names: Array = []
		for key in keys:
			names.append(Style53.display_name(field,str(key),language == "es"))
		var field_label: Label = _line(grid,_avatar_field_title53(field),14,INK)
		field_label.custom_minimum_size.x = 135
		var selection: OptionButton = _select(grid,keys,names)
		selection.custom_minimum_size.x = 178
		selection.select(maxi(0,keys.find(str(chosen[field]))))
		controls[field] = selection
		selection.item_selected.connect(func(_position):_refresh_avatar_preview53(preview,controls))
	_refresh_avatar_preview53(preview,controls)
	return controls

func _save_wardrobe_preview53(slot_index: int, controls: Dictionary) -> void:
	_direct("saveOutfitPreset",{"slot":slot_index,"look":_read_avatar_editor53(controls)})

func _show_creator() -> void:
	_clear_scene()
	var layer: Control = Control.new()
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root = layer
	_scenic_background(layer)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layer.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var frame: PanelContainer = PanelContainer.new()
	frame.custom_minimum_size = Vector2(minf(680.0,maxf(340.0,get_viewport_rect().size.x-32.0)),0)
	frame.add_theme_stylebox_override("panel",_style(PANEL,16))
	center.add_child(frame)
	var body: VBoxContainer = _vbox(frame,12)
	_caption(body,tx("Your new beginning","Un nuevo comienzo"),tx("See your farmer and starting advantages before committing.","Ve tu personaje y sus ventajas antes de empezar."))
	var portrait: Variant = PortraitScript.new()
	portrait.custom_minimum_size = Vector2(220,190)
	body.add_child(portrait)
	var name_input: LineEdit = _field(body,"Alex",tx("Your name","Tu nombre"))
	var farm_input: LineEdit = _field(body,"Little Valley",tx("Farm name","Nombre de finca"))
	_caption(body,tx("Your appearance","Tu aspecto"),tx("All cosmetic choices are free and can be changed later in your wardrobe.","Toda la personalizacion es gratuita y podras cambiarla despues en el vestuario."))
	var look_editor: Dictionary = _build_avatar_editor53(body,portrait,Style53.defaults(),{})
	_line(body,tx("Starting background","Formacion inicial"),14)
	var bg_ids: Array = farm.content.get("backgrounds",{}).keys()
	var bg_labels: Array = []
	for key in bg_ids:
		bg_labels.append(Data.name_of(farm.content["backgrounds"][key],language))
	var backgrounds: OptionButton = _select(body,bg_ids,bg_labels)
	var bonus_card: PanelContainer = PanelContainer.new()
	bonus_card.add_theme_stylebox_override("panel",_style(Color("#e7f3e5"),12,Color("#93bba2")))
	body.add_child(bonus_card)
	var bonus: Label = _line(bonus_card,"",14,INK)
	var update_perk: Callable = func():
		bonus.text = tx("STARTING ADVANTAGE: ","VENTAJA INICIAL: ") + Data.name_of(farm.content["backgrounds"][bg_ids[backgrounds.selected]],language,"perk")
	backgrounds.item_selected.connect(func(_i):update_perk.call())
	update_perk.call()
	_line(body,tx("Game mode and difficulty","Modo de juego y dificultad"),14)
	var modes: OptionButton = _select(body,["story","freeplay","challenge"],[tx("Story","Historia"),tx("Free play","Libre"),tx("Challenge","Desafio")])
	var difficulties: OptionButton = _select(body,["relaxed","standard","hard"],[tx("Relaxed","Tranquilo"),tx("Standard","Normal"),tx("Hard","Dificil")])
	difficulties.select(1)
	var seed_group: VBoxContainer = _vbox(body,4)
	_line(seed_group,tx("World seed","Semilla del mundo"),14)
	var seed: SpinBox = _spin(seed_group,47291,1,2147483647,1)
	seed.tooltip_text = tx("Change the generated farm world seed","Cambia la semilla generada del mundo")
	var buttons: HBoxContainer = _hbox(body)
	_button(tx("Back","Atras"),_show_start_menu,buttons)
	var begin_game: Callable = func():
		var options: Dictionary = {"language":language,"name":name_input.text.strip_edges(),"farm":farm_input.text.strip_edges(),
			"background":str(bg_ids[backgrounds.selected]),"mode":str(modes.get_item_metadata(modes.selected)),
			"difficulty":str(difficulties.get_item_metadata(difficulties.selected)),"seed":int(seed.value)}
		options.merge(_read_avatar_editor53(look_editor),true)
		if FileAccess.file_exists(FarmScript.SAVE_FILE):
			_confirm_action(tx("Replace current farm?","¿Sustituir la finca actual?"),
				tx("A different farm is already saved. It will be kept as a recovery backup, but the active farm will change.","Ya existe una finca guardada. Se conservará como copia de recuperación, pero la finca activa cambiará."),
				_start_new_farm.bind(options))
		else:
			_start_new_farm(options)
	_button(tx("Begin on your first field","Comenzar en tu parcela"),begin_game,buttons,true)

func _start_new_farm(options: Dictionary) -> void:
	farm.new_game(options)
	var result: Dictionary = farm.save_file()
	if result.get("ok",false):
		selected_field = "plot1"
		active_tab = "Farm"
		mobile_inspector_open = false
		_show_game()
	else:
		_notify(str(result.get("error", "Save failed")))

func _confirm_action(title: String, message: String, callback: Callable) -> void:
	var popup: ConfirmationDialog = ConfirmationDialog.new()
	popup.title = title
	popup.dialog_text = message
	add_child(popup)
	popup.confirmed.connect(func():
		callback.call()
		popup.queue_free())
	popup.canceled.connect(func(): popup.queue_free())
	popup.popup_centered(Vector2i(530,240))

func _hud_chip(parent: Node, key: String) -> void:
	var tile: PanelContainer = PanelContainer.new()
	tile.add_theme_stylebox_override("panel",_style(Color("#eef4e7"),9,Color("#d9e7d4")))
	parent.add_child(tile)
	var value: Label = _text("",13,INK)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.clip_text = true
	tile.add_child(value)
	hud_values[key] = value

func _toolbar_button(parent: Node, caption: String, action: Callable, important: bool = false) -> Button:
	var button: Button = _button(caption,action,parent,important)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size = Vector2(0,41.0*ui_scale)
	button.add_theme_font_size_override("font_size",maxi(12,int(13.0*ui_scale)))
	return button

func _toggle_sidebar() -> void:
	if compact_mode:
		_show_screen_picker()
		return
	sidebar_open = not sidebar_open
	if left_nav_holder != null and is_instance_valid(left_nav_holder):
		left_nav_holder.visible = sidebar_open
	_persist_language()

func _show_screen_picker() -> void:
	if not game_running:
		return
	var body: VBoxContainer = _modal_body(tx("All farm screens", "Todas las pantallas"))
	if body == null:
		return
	_line(body,tx("Choose a section. Your game and the live farm remain exactly where they were.","Elige una sección. La finca y la partida mantienen su estado."),13,MUTED)
	var groups: Array = Beauty51.navigation_groups(language == "es")
	for group in groups:
		_caption(body,str(group["heading"]))
		var buttons: HFlowContainer = HFlowContainer.new()
		buttons.add_theme_constant_override("h_separation",7)
		buttons.add_theme_constant_override("v_separation",7)
		body.add_child(buttons)
		for pair in group["tabs"]:
			_toolbar_button(buttons,str(pair[1]),_select_screen_51.bind(str(pair[0])),str(pair[0]) == active_tab)
	_button(tx("Close menu","Cerrar menú"),_close_modal,body)

func _select_screen_51(tab: String) -> void:
	_close_modal()
	_change_tab(tab)

func _toggle_perspective56() -> void:
	use_25d = not use_25d
	_persist_language()
	if game_running:
		_show_game()

func _set_overlay_51(index: int) -> void:
	if overlay_picker == null or index < 0 or index >= overlay_picker.item_count:
		return
	terrain_overlay = str(overlay_picker.get_item_metadata(index))
	_persist_language()
	if world != null and is_instance_valid(world):
		world.overlay_mode = terrain_overlay
		world.queue_redraw()

func _quick_inspect_51() -> void:
	if not bool(farm.field_of(selected_field).get("owned",false)):
		_ask("buyField",{"fieldId":selected_field})
	else:
		_change_tab("Fields")

func _quick_water_51() -> void:
	if bool(farm.field_of(selected_field).get("owned",false)):
		_ask("irrigate",{"fieldId":selected_field,"mm":15.0})

func _quick_harvest_51() -> void:
	var field: Dictionary = farm.field_of(selected_field)
	if not field.is_empty() and not field["crop"].is_empty() and float(field["crop"].get("development",0.0)) >= 0.995:
		_ask("harvest",{"fieldId":selected_field})

func _update_context_51() -> void:
	if context_title == null or not is_instance_valid(context_title):
		return
	var field: Dictionary = farm.field_of(selected_field)
	if field.is_empty():
		return
	var owned: bool = bool(field["owned"])
	var terrain: Dictionary = farm.content["terrains"][str(field["terrain"])]
	var crop: Dictionary = field["crop"]
	var plant_name: String = tx("Unclaimed land","Terreno disponible") if not owned else (tx("Unplanted","Sin sembrar") if crop.is_empty() else farm.n(farm.content["crops"][str(crop["id"])]))
	context_title.text = selected_field.to_upper() + "  ·  " + plant_name
	if compact_mode and plot_status_label != null and is_instance_valid(plot_status_label):
		plot_status_label.text = context_title.text
	var water: float = 100.0 * clampf(float(field["soil"]["water"]) / maxf(1.0,float(field["soil"]["capacity"])),0.0,1.0)
	var development: float = float(crop.get("development",0.0)) * 100.0
	context_detail.text = farm.n(terrain) + " / " + Fields52.localized(Fields52.PLOTS[str(field.get("plot_type","open"))],language) + "  ·  " + tx("Moisture ","Humedad ") + str(int(water)) + "%  ·  " + (tx("Growth ","Crecimiento ") + str(int(development)) + "%" if not crop.is_empty() else tx("Ready for your next plan","Lista para planificar"))
	context_moisture.value = water
	context_moisture.add_theme_stylebox_override("fill",_style(Color("#cb945f") if water < 25.0 else Color("#4b9ab3"),5))
	context_growth.value = development
	context_growth.visible = owned and not crop.is_empty()
	context_manage.text = tx("Buy land","Comprar") if not owned else tx("Manage","Gestionar")
	context_water.disabled = not owned
	context_harvest.disabled = not owned or crop.is_empty() or development < 99.5

func _nav_style55(fill: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _style(fill,9)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

func _create_mobile_nav55(parent: Node) -> void:
	var bar: PanelContainer = PanelContainer.new()
	bar.add_theme_stylebox_override("panel",_style(Color("#fafaf2"),12,Color("#bfdbc3")))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(bar)
	var nav: HBoxContainer = _hbox(bar,3)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in [["Farm",tx("Farm","Finca")],["Compass60",tx("Goals","Metas")],["Fields",tx("Plots","Campos")],["Valley",tx("Valley","Valle")],["Planning",tx("Tasks","Tareas")]]:
		var id: String = str(item[0])
		var b: Button = _button(str(item[1]),_change_tab.bind(id),nav,id == active_tab)
		b.custom_minimum_size = Vector2(0,55.0*ui_scale)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",maxi(12,int(13.0*ui_scale)))
		b.add_theme_stylebox_override("normal",_nav_style55(ACCENT if id == active_tab else ACCENT2))
		b.add_theme_stylebox_override("hover",_nav_style55(Color("#b7dac5")))
		mobile_nav_buttons[id] = b
	var more: Button = _button(tx("More","Más"),_show_screen_picker,nav)
	more.custom_minimum_size = Vector2(0,55.0*ui_scale)
	more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	more.add_theme_font_size_override("font_size",maxi(12,int(13.0*ui_scale)))
	more.add_theme_stylebox_override("normal",_nav_style55(ACCENT2))

func _sync_mobile_panels55() -> void:
	if not compact_mode or mobile_map_pane == null or mobile_detail_pane == null:
		return
	if not is_instance_valid(mobile_map_pane) or not is_instance_valid(mobile_detail_pane):
		return
	var showing_map: bool = (Layout55.map_tab(active_tab) or active_tab == "GardenStudio57") and not mobile_inspector_open
	mobile_map_pane.visible = showing_map
	mobile_detail_pane.visible = not showing_map

func _show_game() -> void:
	_clear_scene()
	game_running = true
	farm.language = language
	layout_band = _layout_band()
	compact_mode = layout_band == 0
	var layer: Control = Control.new()
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root = layer
	_background(layer)
	# A MarginContainer is a real layout parent. Its VBox always occupies the
	# available viewport; unlike a free-floating anchored VBox it cannot shrink
	# to the minimum widths of the toolbar children (the old 500px bug).
	var safe: MarginContainer = MarginContainer.new()
	layer.add_child(safe)
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_safe_area = safe
	var gutter: int = 6 if compact_mode else 12
	for edge in ["margin_left","margin_right","margin_top","margin_bottom"]:
		safe.add_theme_constant_override(edge,gutter)
	var base: VBoxContainer = _vbox(safe,6)
	game_base = base
	base.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var top: PanelContainer = PanelContainer.new()
	game_top_bar = top
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_theme_stylebox_override("panel", _style(PANEL,0))
	base.add_child(top)
	# 5.1: a compact, readable HUD, with the farm as the main canvas.
	var topbox: HBoxContainer = _hbox(top,9)
	var brand: Label = _text("FIELDWORK" if compact_mode else "FIELDWORK  6.0",18 if compact_mode else 19,ACCENT)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.custom_minimum_size.x = 106 if compact_mode else 184
	topbox.add_child(brand)
	header_label = _text("",12,MUTED)
	header_label.visible = false # Retained for scripts and compatibility.
	topbox.add_child(header_label)
	var stats: HFlowContainer = HFlowContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats.add_theme_constant_override("h_separation",6)
	stats.add_theme_constant_override("v_separation",3)
	topbox.add_child(stats)
	for key in (["cash","time"] if compact_mode else ["level","cash","time","water","weather"]):
		_hud_chip(stats,key)
	fps_label59 = _text("FPS --",12,ACCENT)
	fps_label59.visible = show_fps59
	fps_label59.autowrap_mode = TextServer.AUTOWRAP_OFF
	topbox.add_child(fps_label59)
	var clock_scroll: ScrollContainer = ScrollContainer.new()
	clock_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	clock_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	clock_scroll.custom_minimum_size = Vector2(0,58.0 if compact_mode else 52.0)
	clock_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base.add_child(clock_scroll)
	var clock_line: HBoxContainer = _hbox(clock_scroll,6)
	clock_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pair in [[tx("Pause","Pausa"),0],["1x",1],["4x",4]]:
		_toolbar_button(clock_line,str(pair[0]),_set_speed.bind(int(pair[1])))
	if not compact_mode:
		_toolbar_button(clock_line,"12x",_set_speed.bind(12))
	_toolbar_button(clock_line,"+1h",func():_direct("tick",{"hours":1}))
	if not compact_mode:
		for pair in [["Farm",tx("Farm","Finca")],["Compass60",tx("Goals","Metas")],["Fields",tx("Fields","Parcelas")],["Valley",tx("Valley","Valle")],["Animals",tx("Livestock","Ganado")],["Market",tx("Market","Mercado")],["Buildings",tx("Build","Construir")],["GardenStudio57",tx("Garden","Jardín")]]:
			var tab_id: String = str(pair[0])
			primary_nav_buttons[tab_id] = _toolbar_button(clock_line,str(pair[1]),_change_tab.bind(tab_id),tab_id == active_tab)
		_toolbar_button(clock_line,tx("All screens","Todas"),_show_screen_picker,true)
		_toolbar_button(clock_line,tx("Sidebar","Menú"),_toggle_sidebar)
	else:
		_toolbar_button(clock_line,tx("Sections","Secciones"),_show_screen_picker,true)
	var compact: bool = compact_mode
	var horizontal_nav: bool = layout_band < 2
	compact_mode = compact
	var center_row: BoxContainer
	var center_scroll: ScrollContainer = null
	if compact:
		center_row = VBoxContainer.new()
		center_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		base.add_child(center_row)
	else:
		center_row = HBoxContainer.new()
		center_row.add_theme_constant_override("separation",10)
		center_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		base.add_child(center_row)
	var nav_holder: PanelContainer = PanelContainer.new()
	left_nav_holder = nav_holder
	nav_holder.visible = sidebar_open and not compact
	nav_holder.custom_minimum_size = Vector2(0,66) if horizontal_nav else Vector2(192,0)
	nav_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL if horizontal_nav else Control.SIZE_SHRINK_BEGIN
	nav_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_holder.add_theme_stylebox_override("panel",_style(Color("#f6f9f1"),10))
	if horizontal_nav:
		base.add_child(nav_holder)
		base.move_child(nav_holder,base.get_child_index(center_row))
	else:
		center_row.add_child(nav_holder)
	var nav_scroll: ScrollContainer = ScrollContainer.new()
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal_nav else ScrollContainer.SCROLL_MODE_DISABLED
	if horizontal_nav:
		nav_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_holder.add_child(nav_scroll)
	var nav_list: BoxContainer
	if horizontal_nav:
		nav_list = HBoxContainer.new()
	else:
		nav_list = VBoxContainer.new()
	nav_scroll.add_child(nav_list)
	# Every management screen remains reachable via the grouped sidebar.
	var groups: Array = [
		{"heading":tx("EXPLORE","EXPLORAR"),"tabs":[["Farm",tx("Farm overview","Resumen")],["Compass60",tx("Farm Compass","Brújula de la finca")],["Explorer",tx("World guide","Guía del mundo")],["Fields",tx("Fields","Parcelas")],["CropGuide52",tx("Crop guide","Guía de cultivos")],["Valley",tx("Valley map","Mapa del valle")],["Countryside54",tx("Village life","Vida rural")],["Expeditions58",tx("Regional projects","Proyectos regionales")]]},
		{"heading":tx("MANAGE","GESTIONAR"),"tabs":[["Ecology",tx("Soil & pests","Suelo y plagas")],["Planning",tx("Daily plan","Plan diario")],["Machinery",tx("Machinery","Maquinaria")],["Resources",tx("Resources","Recursos")],["GardenStudio57",tx("Garden studio","Estudio del jardín")],["Buildings",tx("Buildings","Edificios")],["Animals",tx("Animals","Animales")],["Processing",tx("Processing","Elaboración")],["Market",tx("Markets","Mercado")],["Economy",tx("Business strategy","Estrategia")]]},
		{"heading":tx("COMMUNITY","COMUNIDAD"),"tabs":[["Neighbours",tx("Neighbours","Vecinos")],["Stories",tx("Village stories","Historias del pueblo")],["Community50",tx("Neighbour journeys","Historias vecinales")],["Festivals50",tx("Festivals & seasons","Fiestas y estaciones")],["Certifications50",tx("Professional mastery","Maestría profesional")],["Character",tx("Courses & talents","Cursos y talentos")],["Wardrobe53",tx("Farmer wardrobe","Vestuario del agricultor")],["Story",tx("Story & goals","Historia y objetivos")],["Journal",tx("Journal","Diario")],["Options",tx("Settings","Opciones")]]}
	]
	for group in groups:
		if not horizontal_nav:
			var heading: Label = _text(str(group["heading"]),11,MUTED)
			heading.add_theme_constant_override("line_spacing",2)
			nav_list.add_child(heading)
		for pair in group["tabs"]:
			var button: Button = _button(str(pair[1]),_change_tab.bind(str(pair[0])),nav_list,str(pair[0]) == active_tab)
			nav_buttons[str(pair[0])] = button
			button.add_theme_font_size_override("font_size",maxi(12,int(float(13 if not horizontal_nav else 14)*ui_scale)))
			if horizontal_nav:
				button.custom_minimum_size = Vector2(145,46 * ui_scale)
		if not horizontal_nav:
			var divider: HSeparator = HSeparator.new()
			nav_list.add_child(divider)
	var visual_side: VBoxContainer = _vbox(center_row,4)
	mobile_map_pane = visual_side
	if compact:
		visual_side.custom_minimum_size.y = 0.0
	visual_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_side.size_flags_stretch_ratio = 1.8
	visual_side.add_theme_constant_override("separation",6 if compact else 5)
	# Context is directly beside the live map, instead of in a distant menu.
	var map_toolbar: HBoxContainer = _hbox(visual_side,7)
	plot_status_label = _text(tx("YOUR FARM  ·  Click a plot to inspect","TU FINCA  ·  Pulsa una parcela"),14,ACCENT)
	plot_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	plot_status_label.clip_text = true
	plot_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_toolbar.add_child(plot_status_label)
	if not compact:
		var layer_title: Label = _text(tx("Map layer","Capa"),12,MUTED)
		map_toolbar.add_child(layer_title)
	var overlay_ids: Array = Beauty51.OVERLAY_ORDER
	var overlay_names: Array = Beauty51.overlay_labels(language == "es")
	overlay_picker = _select(map_toolbar,overlay_ids,overlay_names)
	overlay_picker.custom_minimum_size = Vector2(112,40*ui_scale)
	overlay_picker.size_flags_horizontal = Control.SIZE_SHRINK_END
	var overlay_index: int = maxi(0,overlay_ids.find(terrain_overlay))
	overlay_picker.select(overlay_index)
	overlay_picker.item_selected.connect(_set_overlay_51)
	var perspective_button: Button = _toolbar_button(map_toolbar, "2.5D" if use_25d else "2D", _toggle_perspective56, use_25d)
	perspective_button.custom_minimum_size = Vector2(54, 42 * ui_scale)
	perspective_button.tooltip_text = tx("Switch between isometric 2.5D and classic 2D map", "Cambiar entre mapa isométrico 2.5D y 2D clásico")
	var surface: PanelContainer = PanelContainer.new()
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface.custom_minimum_size = Vector2(0,240.0 if compact else 380.0)
	surface.add_theme_stylebox_override("panel",_style(Color("#edf2dd"),13,Color("#a5bfa9")))
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual_side.add_child(surface)
	world = IsoWorld56.new() if use_25d else WorldScript.new()
	_apply_visual_preferences(world)
	world.clip_contents = true
	world.custom_minimum_size = Vector2(220,240.0) if compact else Vector2(0,380.0)
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface.add_child(world)
	world.set_farm(farm)
	world.overlay_mode = terrain_overlay
	world.set_selected(selected_field)
	world.selected_field.connect(_picked_field)
	world.selected_npc.connect(_picked_npc)
	world.selected_building.connect(_picked_building)
	world.selected_build_slot.connect(_picked_build_slot)
	world.selected_animal.connect(_picked_animal)
	world.selected_decoration.connect(_picked_decoration)
	world.garden_slot_chosen57.connect(_picked_garden_slot57)
	world.machine_chosen57.connect(_picked_machine57)
	world.requested_move.connect(_move_to)
	valley_view = ValleyScript.new()
	valley_view.clip_contents = true
	valley_view.custom_minimum_size = Vector2(220,240.0) if compact else Vector2(0,380.0)
	valley_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	valley_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	valley_view.visible = false
	surface.add_child(valley_view)
	valley_view.set_farm(farm)
	valley_view.performance_mode59 = performance_mode59
	valley_view.reduced_motion59 = reduced_motion
	valley_view.region_selected.connect(_picked_region)
	# Context bar stays visible when switching management tabs and is live-updated.
	var context_card: PanelContainer = PanelContainer.new()
	context_card.add_theme_stylebox_override("panel",_style(Color("#fbf8eb"),12,Color("#dce9d8")))
	visual_side.add_child(context_card)
	var context_layout: BoxContainer
	context_layout = _hbox(context_card,7 if compact else 9)
	context_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var context_labels: VBoxContainer = _vbox(context_layout,3)
	context_labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_labels.visible = not compact
	context_title = _text("",16,ACCENT)
	context_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	context_title.clip_text = true
	context_labels.add_child(context_title)
	context_detail = _text("",12,MUTED)
	context_detail.autowrap_mode = TextServer.AUTOWRAP_OFF
	context_detail.clip_text = true
	context_labels.add_child(context_detail)
	var progress_row: HBoxContainer = _hbox(context_labels,5)
	context_moisture = ProgressBar.new()
	context_moisture.show_percentage = false
	context_moisture.custom_minimum_size = Vector2(72,7)
	context_moisture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(context_moisture)
	context_growth = ProgressBar.new()
	context_growth.show_percentage = false
	context_growth.custom_minimum_size = Vector2(70,7)
	context_growth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_growth.add_theme_stylebox_override("fill",_style(Color("#82ac61"),5))
	progress_row.add_child(context_growth)
	var context_actions: HFlowContainer = HFlowContainer.new()
	context_actions.add_theme_constant_override("h_separation",5)
	context_actions.add_theme_constant_override("v_separation",3)
	context_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	context_layout.add_child(context_actions)
	context_manage = _toolbar_button(context_actions,tx("Manage","Gestionar"),_quick_inspect_51,true)
	context_water = _toolbar_button(context_actions,tx("Water +15","Regar +15"),_quick_water_51)
	context_harvest = _toolbar_button(context_actions,tx("Harvest","Cosechar"),_quick_harvest_51)
	# Horizontal scrolling keeps all walking/zoom controls reachable on phones.
	var movement_scroll: ScrollContainer = ScrollContainer.new()
	movement_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	movement_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	movement_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	movement_scroll.custom_minimum_size.y = 49.0 * ui_scale
	visual_side.add_child(movement_scroll)
	movement_bar = _hbox(movement_scroll,4)
	var movement: HBoxContainer = movement_bar
	_line(movement,tx("Walk:","Mover:"),12,MUTED)
	for pair in [["<",-1,0],["^",0,-1],["v",0,1],[">",1,0]]:
		var b: Button = _button(str(pair[0]),_walk_step.bind(int(pair[1]),int(pair[2])),movement)
		b.custom_minimum_size = Vector2(Performance59.touch_target(ui_scale) if compact else 45.0,Performance59.touch_target(ui_scale) if compact else 46.0)
		b.tooltip_text = tx("Tap to move; hold to keep walking", "Pulsa para mover; manten pulsado para caminar")
		if compact:
			b.button_down.connect(_touch_direction59.bind(Vector2(int(pair[1]),int(pair[2])),true))
			b.button_up.connect(_touch_direction59.bind(Vector2.ZERO,false))
	_button("+",func():world.change_zoom(0.25),movement)
	_button("-",func():world.change_zoom(-0.25),movement)
	_button("1:1",func():world.reset_camera(),movement)
	_button(tx("Scenic view","Vista amplia"),_show_panorama,movement,true)
	var right_holder: PanelContainer = PanelContainer.new()
	mobile_detail_pane = right_holder
	right_holder.custom_minimum_size = Vector2(0,0) if compact else Vector2(Layout55.inspector_width(get_viewport_rect().size.x),0)
	right_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	right_holder.size_flags_stretch_ratio = 1.0
	right_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_holder.add_theme_stylebox_override("panel",_style(PANEL,10))
	center_row.add_child(right_holder)
	right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_holder.add_child(right_scroll)
	right_body = _vbox(right_scroll,10)
	right_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_body.custom_minimum_size = Vector2(0,0)
	if compact:
		_create_mobile_nav55(base)
	status_label = _text("",13,MUTED)
	status_label.clip_text = true
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base.add_child(status_label)
	confirm = ConfirmationDialog.new()
	confirm.title = tx("Confirm farm action","Confirmar accion")
	confirm.confirmed.connect(_commit_pending)
	layer.add_child(confirm)
	info = AcceptDialog.new()
	info.title = "Fieldwork"
	layer.add_child(info)
	_setup_file_dialogs(layer)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "SeasonalAmbience"
	layer.add_child(ambient_player)
	ambient_player.finished.connect(_play_ambience)
	_play_ambience()
	_refresh()

func _set_speed(value: int) -> void:
	speed = value
	speed_accum = 0.0
	if game_running:
		status_label.text = tx("Time: ","Tiempo: ") + (tx("paused","pausado") if speed == 0 else str(speed) + "x")
		_update_header()

func _change_tab(tab: String) -> void:
	active_tab = tab
	if compact_mode:
		mobile_inspector_open = not Layout55.map_tab(tab)
	_update_nav_state()
	_update_visual_mode()
	if right_scroll != null and is_instance_valid(right_scroll):
		right_scroll.scroll_vertical = 0
	_render_panel()

func _update_nav_state() -> void:
	for id in primary_nav_buttons.keys():
		var primary: Button = primary_nav_buttons[id]
		if is_instance_valid(primary):
			var active: bool = str(id) == active_tab
			primary.add_theme_stylebox_override("normal",_style(ACCENT if active else ACCENT2,9))
			primary.add_theme_color_override("font_color",Color.WHITE if active else INK)
	for id in mobile_nav_buttons.keys():
		var mobile: Button = mobile_nav_buttons[id]
		if is_instance_valid(mobile):
			var mobile_active: bool = str(id) == active_tab
			mobile.add_theme_stylebox_override("normal",_nav_style55(ACCENT if mobile_active else ACCENT2))
			mobile.add_theme_color_override("font_color",Color.WHITE if mobile_active else INK)
	for id in nav_buttons.keys():
		var button: Button = nav_buttons[id]
		if not is_instance_valid(button):
			continue
		var is_active: bool = str(id) == active_tab
		button.add_theme_stylebox_override("normal",_style(ACCENT if is_active else ACCENT2,9))
		button.add_theme_color_override("font_color",Color.WHITE if is_active else INK)

func _update_visual_mode() -> void:
	_sync_mobile_panels55()
	if world != null and valley_view != null:
		world.visible = active_tab != "Valley"
		if active_tab == "Valley":
			world.touchscreen_dir = Vector2.ZERO
		world.show_build_slots = active_tab == "Buildings"
		world.show_garden_slots57 = active_tab == "GardenStudio57"
		world.active_garden_slot57 = selected_garden_slot57
		world.overlay_mode = terrain_overlay
		world.active_build_slot = selected_build_slot
		world.queue_redraw()
		valley_view.visible = active_tab == "Valley"
		if movement_bar != null:
			movement_bar.visible = active_tab != "Valley"

func _picked_region(region_id: String) -> void:
	selected_region = region_id
	active_tab = "Valley"
	if compact_mode:
		mobile_inspector_open = true
	if valley_view != null:
		valley_view.set_selected(region_id)
	_update_nav_state()
	_update_visual_mode()
	_render_panel()

func _picked_field(id: String) -> void:
	selected_field = id
	if compact_mode:
		mobile_inspector_open = true
	if world != null:
		world.set_selected(id)
	active_tab = "Fields"
	_update_nav_state()
	_update_visual_mode()
	_render_panel()
	_update_header()

func _picked_npc(id: String) -> void:
	selected_npc = id
	active_tab = "Neighbours"
	_update_nav_state()
	_update_visual_mode()
	_render_panel()
	_show_neighbour(id)

func _picked_garden_slot57(slot: int) -> void:
	if slot < 0 or slot >= Living57.GARDEN_SLOTS:
		return
	selected_garden_slot57 = slot
	if world != null and is_instance_valid(world):
		world.active_garden_slot57 = slot
		world.queue_redraw()
	if active_tab == "GardenStudio57":
		if compact_mode:
			mobile_inspector_open = true
			_sync_mobile_panels55()
		_render_panel()

func _picked_machine57(_machine_id: String) -> void:
	_change_tab("Machinery")

func _show_garden_map57() -> void:
	if compact_mode:
		mobile_inspector_open = false
		_sync_mobile_panels55()
	if world != null and is_instance_valid(world):
		world.show_garden_slots57 = true
		world.queue_redraw()

func _choose_garden_slot57(slot: int) -> void:
	_picked_garden_slot57(slot)

func _set_source_garden57(source_id: String) -> void:
	selected_deco_id57 = source_id

func _picked_animal(_animal_id: String) -> void:
	active_tab = "Animals"
	_update_nav_state()
	_update_visual_mode()
	_render_panel()

func _picked_decoration(slot: int) -> void:
	for decoration in farm.state.get("decorations",[]):
		if int(decoration["slot"]) == slot:
			var name: String = farm.n(FarmScript.DECORATIONS[str(decoration["kind"])])
			var status: String = tx("Complete","Terminado") if bool(decoration["completed"]) else tx("Under construction","En construccion")
			_notify(name + "  /  " + tx("Garden position ","Posicion jardin ") + str(slot+1) + "\n" + status)
			return

func _picked_build_slot(slot: int) -> void:
	selected_build_slot = clampi(slot,0,Life.CONSTRUCTION_SLOT_COUNT-1)
	if world != null:
		world.active_build_slot = selected_build_slot
		world.queue_redraw()
	if active_tab == "Buildings":
		_render_panel()

func _picked_building(id: String) -> void:
	if id == "farmhouse" or id == "market":
		_enter_building(id)
		return
	for b in farm.state["buildings"]:
		if str(b["id"]) == id:
			if int(b["level"]) < 1:
				_notify(tx("Construction is not finished yet.","La obra todavia no ha terminado."))
			else:
				_enter_building(str(b["kind"]))
			return

func _move_to(x: float, y: float) -> void:
	if not game_running:
		return
	var result: Dictionary = farm.act("move", {"x":x,"y":y})
	if result.get("ok",false):
		world.queue_redraw()
		_update_header()

func _walk_step(dx: int, dy: int) -> void:
	if not game_running:
		return
	var p: Dictionary = farm.state["player"]
	_move_to(clampf(float(p["x"])+dx*0.8,1.0,63.0),clampf(float(p["y"])+dy*0.8,1.0,53.0))

func _show_illustrated_view() -> void:
	# Optional storybook painting of a developed farm. Click hotspots to open
	# real plot, animal, building and social panels. The live map remains the
	# accurate renderer of actual crops and building ownership.
	if not game_running or (modal != null and is_instance_valid(modal)):
		return
	speed = 0
	if world != null and is_instance_valid(world):
		world.controls_enabled = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color("#193528")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal = shade
	var padding: MarginContainer = MarginContainer.new()
	for edge in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		padding.add_theme_constant_override(edge,12)
	shade.add_child(padding)
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column: VBoxContainer = _vbox(padding,8)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var heading: HBoxContainer = _hbox(column,8)
	var title: Label = _text(tx("ILLUSTRATED COURTYARD - CLICK TO EXPLORE","PATIO ILUSTRADO - PULSA PARA EXPLORAR"),17,Color("#fff7df"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	heading.add_child(title)
	var live_button: Button = _button(tx("Live map","Mapa vivo"),_switch_to_live_map,heading)
	live_button.custom_minimum_size.x = 110
	var close: Button = _button(tx("Close","Cerrar"),_close_modal,heading)
	close.custom_minimum_size.x = 90
	var illustrated: Variant = IllustratedScript.new()
	illustrated.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustrated.size_flags_vertical = Control.SIZE_EXPAND_FILL
	illustrated.custom_minimum_size = Vector2(280,220)
	column.add_child(illustrated)
	illustrated.set_farm(farm)
	illustrated.hotspot_selected.connect(_illustrated_hotspot)
	var note: Label = _text(tx("Scenic illustration of a possible farm. Actual crops, construction and ownership are shown in Live map.","Ilustracion de una finca posible. Los cultivos y edificios reales se muestran en Mapa vivo."),12,Color("#fff2d5"))
	column.add_child(note)

func _switch_to_live_map() -> void:
	_close_modal()
	_show_panorama()

func _illustrated_hotspot(kind: String, reference: String) -> void:
	_close_modal()
	match kind:
		"field":
			_picked_field(reference)
		"npc":
			_picked_npc(reference)
		"animal":
			_change_tab("Animals")
		"market":
			_change_tab("Market")
		"building":
			if reference == "farmhouse" or farm.ready(reference):
				_enter_building(reference)
			else:
				_change_tab("Buildings")
				_notify(tx("Build this structure before entering it.","Construye el edificio antes de entrar."))

func _show_panorama() -> void:
	# The full-screen farm uses the same real World and game state as the
	# regular map. All crops, buildings and animals are drawn from farm.state.
	if not game_running or (modal != null and is_instance_valid(modal)):
		return
	speed = 0
	if world != null and is_instance_valid(world):
		world.controls_enabled = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color("#203a2c")
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal = shade
	var padding: MarginContainer = MarginContainer.new()
	for edge in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		padding.add_theme_constant_override(edge,12)
	shade.add_child(padding)
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shell: VBoxContainer = _vbox(padding,6)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bar: HBoxContainer = _hbox(shell,8)
	var title: Label = _text(tx("YOUR LIVING FARM - WALK, ZOOM, SELECT","TU FINCA VIVA - CAMINA, ACERCA, ELIGE"),17,Color("#fff5de"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	bar.add_child(title)
	var close: Button = _button(tx("Close","Cerrar"),_close_modal,bar)
	close.custom_minimum_size.x = 105
	var frame: PanelContainer = PanelContainer.new()
	frame.add_theme_stylebox_override("panel",_style(Color("#dce8d1"),12))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(frame)
	var grand: Variant = IsoWorld56.new() if use_25d else WorldScript.new()
	_apply_visual_preferences(grand)
	grand.overlay_mode = terrain_overlay
	grand.clip_contents = true
	grand.custom_minimum_size = Vector2(250,220)
	grand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(grand)
	grand.set_farm(farm)
	grand.set_selected(selected_field)
	grand.selected_field.connect(_panorama_field)
	grand.selected_npc.connect(_panorama_npc)
	grand.selected_building.connect(_panorama_building)
	grand.selected_animal.connect(_panorama_animal)
	grand.requested_move.connect(_move_to)
	var controls: HBoxContainer = _hbox(shell,6)
	_button(tx("Zoom in","Acercar"),func():grand.change_zoom(0.25),controls)
	_button(tx("Zoom out","Alejar"),func():grand.change_zoom(-0.25),controls)
	_button(tx("Reset camera","Recentrar"),func():grand.reset_camera(),controls)
	_button(tx("Photo","Foto"),_take_photo,controls)
	var hint: Label = _text(tx("Select a field, neighbour, or building. WASD/arrows to walk, mouse wheel to zoom, middle-click to pan.","Selecciona parcela, vecino o edificio. WASD/flechas para moverte, rueda para zoom y boton central para desplazar."),12,Color("#f6edcf"))
	shell.add_child(hint)

func _panorama_field(id: String) -> void:
	_close_modal()
	_picked_field(id)

func _panorama_npc(id: String) -> void:
	_close_modal()
	_picked_npc(id)

func _panorama_building(id: String) -> void:
	_close_modal()
	_picked_building(id)

func _panorama_animal(id: String) -> void:
	_close_modal()
	_picked_animal(id)

func _update_header() -> void:
	if not game_running:
		return
	var s: Dictionary = farm.status()
	if compact_mode:
		header_label.text = "LVL " + str(s["level"]) + "  |  XP " + str(220-int(s["xp_to_next"])) + "/220  |  EUR " + str(int(s["cash"])) + "  |  D" + str(s["day"]) + " " + str(s["hour"]) + ":00"
	else:
		header_label.text = "LEVEL " + str(s["level"]) + "  |  " + str(220-int(s["xp_to_next"])) + "/220 XP  |  EUR " + str(snappedf(float(s["cash"]),0.01)) + "  |  " + str(s["fields"]) + "/" + str(FarmScript.MAX_FIELDS) + " " + tx("fields","parcelas") + "  |  " + tx("Day ","Dia ") + str(s["day"]) + "  " + str(s["hour"]) + ":00"
	status_label.text = farm.weather_text() + "    |    " + str(snappedf(float(s["water"]),0.1)) + " m3 " + tx("water","agua") + "   |   " + str(s["season"])
	if not hud_values.is_empty():
		if hud_values.has("level"):
			(hud_values["level"] as Label).text = "LV " + str(s["level"])
		(hud_values["cash"] as Label).text = "€ " + str(int(s["cash"]))
		(hud_values["time"] as Label).text = tx("DAY ","DÍA ") + str(s["day"]) + " · " + str(s["hour"]) + ":00"
		if hud_values.has("water"):
			(hud_values["water"] as Label).text = "H₂O " + str(int(float(s["water"]))) + " m³"
		if hud_values.has("weather"):
			(hud_values["weather"] as Label).text = str(s["season"]) + " · " + str(farm.state["weather"].get("kind","clear"))
	_update_context_51()
	if plot_status_label != null and is_instance_valid(plot_status_label):
		var plot: Dictionary = farm.field_of(selected_field)
		if not plot.is_empty():
			var terrain: Dictionary = farm.content["terrains"][str(plot["terrain"])]
			var crop_title: String = tx("Fallow","Barbecho") if plot["crop"].is_empty() else farm.n(farm.content["crops"][str(plot["crop"]["id"])])
			plot_status_label.tooltip_text = tx("Selected: ","Parcela elegida: ") + selected_field.to_upper() + "  |  " + farm.n(terrain) + "  |  " + (crop_title if plot["owned"] else tx("For sale","En venta"))

func _refresh() -> void:
	_update_header()
	if world != null:
		world.queue_redraw()
	if valley_view != null:
		valley_view.queue_redraw()
	_update_visual_mode()
	_render_panel()
	if game_running and not farm.state["events"]["active"].is_empty() and modal == null:
		_show_decision_board()

func _render_panel() -> void:
	if not game_running or right_body == null:
		return
	for child in right_body.get_children():
		right_body.remove_child(child)
		child.queue_free()
	match active_tab:
		"Farm": _panel_farm()
		"Compass60": _panel_compass60()
		"Explorer": _panel_explorer()
		"Resources": _panel_resources()
		"Valley": _panel_valley()
		"Countryside54": _panel_countryside54()
		"Expeditions58": _panel_expeditions58()
		"Fields": _panel_fields()
		"CropGuide52": _panel_crop_guide52()
		"Ecology": _panel_ecology()
		"Planning": _panel_planning()
		"Machinery": _panel_machinery()
		"GardenStudio57": _panel_garden_studio57()
		"Economy": _panel_economy()
		"Buildings": _panel_buildings()
		"Animals": _panel_animals()
		"Processing": _panel_processing()
		"Market": _panel_market()
		"Neighbours": _panel_neighbours()
		"Stories": _panel_stories()
		"Community50": _panel_community50()
		"Festivals50": _panel_festivals50()
		"Certifications50": _panel_certifications50()
		"Character": _panel_character()
		"Wardrobe53": _panel_wardrobe53()
		"Story": _panel_story()
		"Journal": _panel_journal()
		"Options": _panel_options()

func _notify(message: String) -> void:
	if info == null or not is_instance_valid(info):
		info = AcceptDialog.new()
		add_child(info)
	info.dialog_text = farm.message(message)
	info.popup_centered()

func _ask(kind: String, args: Dictionary = {}) -> void:
	var preview: Dictionary = farm.quote(kind,args)
	if not preview.get("ok",false):
		_notify(str(preview.get("error","Action not available")))
		return
	var cost: float = float(preview.get("cost",0.0))
	var revenue: float = float(preview.get("revenue",0.0))
	if cost <= 0.0 and revenue <= 0.0:
		_direct(kind,args)
		return
	pending = {"type":kind,"args":args}
	confirm.dialog_text = farm.message(str(preview.get("message",kind))) + "\n" + ("EUR " + str(cost) + tx(" cost"," de coste") if cost > 0.0 else "EUR " + str(revenue) + tx(" income"," de ingreso")) + "\n" + tx("Confirm this action?","¿Confirmas esta acción?")
	confirm.popup_centered()

func _commit_pending() -> void:
	if pending.is_empty():
		return
	var next: Dictionary = pending.duplicate(true)
	pending = {}
	_direct(str(next["type"]),next["args"])

func _direct(kind: String, args: Dictionary = {}) -> void:
	var result: Dictionary = farm.act(kind,args)
	if not result.get("ok",false):
		_notify(str(result.get("error","Unknown failure")))
		return
	var saved59: Dictionary = {}
	if kind != "move" and kind != "inspect":
		saved59 = farm.save_file()
	if world != null and is_instance_valid(world):
		world.trigger_work_effect57(kind, str(args.get("fieldId", "")))
	_refresh()
	if not saved59.is_empty() and not bool(saved59.get("ok",false)):
		speed = 0
		_notify(tx("The action succeeded but autosave failed: ","La accion se ha completado, pero el guardado automatico fallo: ") + str(saved59.get("error","Unknown write error")))

func _process(delta: float) -> void:
	if game_running and show_fps59 and fps_label59 != null and is_instance_valid(fps_label59):
		fps_accum59 += delta
		if fps_accum59 >= 1.0:
			fps_accum59 = 0.0
			fps_label59.text = "FPS " + str(Engine.get_frames_per_second())
	if not game_running or speed <= 0 or modal != null or (confirm != null and is_instance_valid(confirm) and confirm.visible) or (info != null and is_instance_valid(info) and info.visible) or (import_dialog != null and is_instance_valid(import_dialog) and import_dialog.visible) or (export_dialog != null and is_instance_valid(export_dialog) and export_dialog.visible):
		return
	if not farm.state["events"]["active"].is_empty():
		_show_decision_board()
		return
	speed_accum += delta * speed
	if speed_accum < 2.2:
		return
	speed_accum -= 2.2
	var result: Dictionary = farm.act("tick",{"hours":1})
	if result.get("ok",false):
		_update_header()
		world.queue_redraw()
		if valley_view != null:
			valley_view.queue_redraw()
		if int(farm.state["time"]["total"]) % 4 == 0:
			_render_panel()
		if int(farm.state["time"]["total"]) % 12 == 0:
			var autosaved59: Dictionary = farm.save_file()
			if not bool(autosaved59.get("ok",false)):
				speed = 0
				_notify(tx("Autosave failed; the clock is paused: ","Fallo el autoguardado; reloj pausado: ") + str(autosaved59.get("error","Unknown write error")))
		if not farm.state["events"]["active"].is_empty():
			speed = 0
			_show_decision_board()
	else:
		speed = 0

func _setup_file_dialogs(parent: Node) -> void:
	export_dialog = FileDialog.new()
	export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	export_dialog.add_filter("*.json", "Fieldwork JSON saves")
	export_dialog.file_selected.connect(_export_file)
	parent.add_child(export_dialog)
	import_dialog = FileDialog.new()
	import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	import_dialog.add_filter("*.json", "Fieldwork JSON saves")
	import_dialog.file_selected.connect(_import_file)
	parent.add_child(import_dialog)

func _export_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		_notify("Cannot create export file")
		return
	file.store_string(farm.export_text())
	file.close()
	_notify("Farm exported to " + path)

func _import_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.READ)
	if file == null:
		_notify("Cannot open import file")
		return
	var result: Dictionary = farm.load_text(file.get_as_text())
	if result.get("ok",false):
		farm.save_file()
		_refresh()
	else:
		_notify(str(result.get("error","Invalid import")))

func _take_photo() -> void:
	var where: String = "user://fieldwork_photo.png"
	var snapshot: Image = get_viewport().get_texture().get_image()
	if snapshot.save_png(where) == OK:
		_notify(tx("Saved screenshot to: ","Foto guardada en: ") + ProjectSettings.globalize_path(where))
	else:
		_notify("Screenshot could not be saved")

func _jump_compass60(task: Dictionary) -> void:
	var field_id: String = str(task.get("field",""))
	if field_id != "" and not farm.field_of(field_id).is_empty():
		selected_field = field_id
		if world != null and is_instance_valid(world):
			world.set_selected(field_id)
	_change_tab(str(task.get("tab","Farm")))

func _panel_compass60() -> void:
	var overall: float = Compass60.overall_progress(farm)
	_caption(right_body,tx("FARM COMPASS · 6.0","BRÚJULA DE LA FINCA · 6.0"), tx("Real recommendations from your saved farm — never automatic spending.","Recomendaciones de tu finca real: nunca se gastan recursos automáticamente."))
	_line(right_body,Compass60.farm_stage(overall,language),21,ACCENT)
	var overall_bar: ProgressBar = ProgressBar.new()
	overall_bar.show_percentage = true
	overall_bar.value = overall*100.0
	overall_bar.custom_minimum_size = Vector2(0,22)
	overall_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_body.add_child(overall_bar)
	var s: Dictionary = Compass60.summary(farm)
	_line(right_body,tx("Ready ","Listas ")+str(s["ready"])+" · "+tx("Dry ","Secas ")+str(s["dry"])+" · "+tx("Pest alerts ","Plagas ")+str(s["pests"]),13,DANGER if int(s["dry"])+int(s["pests"])>0 else ACCENT)
	_caption(right_body,tx("Do next", "Siguiente acción"),tx("Tap a recommendation to open the relevant controls.","Pulsa una recomendación para abrir sus controles."))
	for task in Compass60.priorities(farm,language):
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel",_style(Color("#f1f7e8"),11,Color("#d2e4d3")))
		right_body.add_child(card)
		var column: VBoxContainer = _vbox(card,4)
		_line(column,Compass60.label(task,language) + (" ("+str(task["count"])+")" if int(task.get("count",0))>0 else ""),15,ACCENT)
		_line(column,Compass60.label(task,language,"detail"),12,MUTED)
		_button(tx("Open controls","Abrir controles"),_jump_compass60.bind(task),column)
	_caption(right_body,tx("Your long-term farm path", "Tu trayectoria a largo plazo"),tx("Six independent goals based on real production, ecology and community progress.","Seis objetivos basados en producción, ecología y relaciones reales."))
	var completed: int = 0
	for milestone in Compass60.pillars(farm):
		var progress: float = float(milestone["progress"])
		if progress >= 0.999:
			completed += 1
		_line(right_body,Compass60.label(milestone,language)+"  ·  "+str(int(progress*100.0))+"%",15,ACCENT if progress>=0.999 else INK)
		var bar: ProgressBar = ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0,10)
		bar.value = progress*100.0
		right_body.add_child(bar)
		_line(right_body,Compass60.label(milestone,language,"detail"),12,MUTED)
		_button(tx("Explore this goal","Ver objetivo"),_change_tab.bind(str(milestone["tab"])),right_body)
	_line(right_body,tx("Completed paths: ","Trayectorias completadas: ")+str(completed)+"/6",16,ACCENT)
	if completed == 6:
		_line(right_body,tx("Your farm is a valley landmark. Keep shaping its story!","Tu finca es un referente del valle. ¡Sigue construyendo su historia!"),15,ACCENT)
	var season_goal: Dictionary = farm.season_goal_info()
	if not season_goal.is_empty():
		_caption(right_body,tx("This season", "Esta temporada"))
		_line(right_body,World50.localized(season_goal["name"],language)+" · "+str(int(farm.season_goal_progress()))+"/"+str(season_goal["target"]),14)
		_button(tx("Festivals & season review","Fiestas y balance estacional"),_change_tab.bind("Festivals50"),right_body)
	_button(tx("Daily planner and budget", "Plan diario y presupuesto"),_change_tab.bind("Planning"),right_body,true)

func _panel_farm() -> void:
	var active60: Array = Compass60.priorities(farm,language)
	var overall60: float = Compass60.overall_progress(farm)
	_caption(right_body,tx("Your next steps", "Tus próximos pasos"),Compass60.farm_stage(overall60,language) + "  ·  " + str(int(overall60*100.0)) + "%")
	for task60 in active60.slice(0,mini(2,active60.size())):
		var button60: Button = _button(Compass60.label(task60,language),_jump_compass60.bind(task60),right_body,true)
		button60.tooltip_text = Compass60.label(task60,language,"detail")
	_button(tx("Open Farm Compass and long-term goals", "Abrir brújula y objetivos a largo plazo"),_change_tab.bind("Compass60"),right_body)
	var player: Dictionary = farm.state["player"]
	_caption(right_body, str(player["farm"]),tx("Your new beginning in a living valley","Tu comienzo en un valle lleno de vida"))
	var s: Dictionary = farm.status()
	_line(right_body,"EUR " + str(s["cash"]) + "   |   " + str(s["fields"]) + "/" + str(FarmScript.MAX_FIELDS) + " " + tx("plots","parcelas"),20,ACCENT)
	_line(right_body,tx("Water reserve: ","Reserva de agua: ") + str(snappedf(float(s["water"]),0.1)) + " m3")
	_line(right_body,tx("Storage: ","Almacen: ") + str(snappedf(float(s["inventory"]),0.1)) + "/" + str(s["capacity"]) + " kg")
	_line(right_body,tx("Reputation: ","Reputacion: ") + str(farm.state["economy"]["reputation"]))
	var living: Dictionary = farm.field_of(selected_field)
	if living.get("owned",false):
		var soil_v: String = Visual.soil_visual(living["soil"])
		var conditions: Dictionary = {"dry":tx("Dry soil","Suelo seco"),"wet":tx("Wet soil","Suelo humedo"),"balanced":tx("Balanced moisture","Humedad equilibrada")}
		_line(right_body,tx("Selected field: ","Parcela elegida: ")+selected_field.to_upper()+" · "+str(conditions.get(soil_v,"")),14,DANGER if soil_v=="dry" else ACCENT)
		if not living["crop"].is_empty():
			_line(right_body,farm.n(farm.content["crops"][str(living["crop"]["id"])])+" · "+Visual.crop_stage_text(float(living["crop"]["development"]),language=="es"),14)
	_level_progress(right_body)
	_button(tx("Gather materials and decorate","Recoger y decorar"),_change_tab.bind("Resources"),right_body)
	var quality: float = farm.soil_health(selected_field)
	_line(right_body,tx("Soil vitality: ","Vitalidad del suelo: ") + str(int(quality*100.0)) + "%",13,ACCENT if quality >= 0.85 else DANGER)
	var bank: Dictionary = farm.operating_budget()
	_line(right_body,tx("Fixed daily maintenance: EUR ","Mantenimiento fijo diario: EUR ") + str(snappedf(float(bank["fixed_daily"]),0.01)),13,MUTED)
	_button(tx("Open daily planner","Abrir plan diario"),_change_tab.bind("Planning"),right_body)
	var objective: Dictionary = farm.season_goal_info()
	if not objective.is_empty():
		_line(right_body,tx("Seasonal goal: ","Meta estacional: ")+World50.localized(objective["name"],language)+" ("+str(int(farm.season_goal_progress()))+"/"+str(objective["target"])+")",13,ACCENT)
		_button(tx("View festival & seasonal progress","Ver fiestas y progreso estacional"),_change_tab.bind("Festivals50"),right_body)
	var effect_list: Array = farm.active_effects()
	if not effect_list.is_empty():
		_caption(right_body,tx("Effects from your decisions","Efectos de tus decisiones"))
		for entry in effect_list:
			_line(right_body,_localized_effect(str(entry["id"])) + " · " + str(entry["hours"]) + " h",13,ACCENT)
	_button(tx("See every location and system","Ver todos los lugares y sistemas"),_change_tab.bind("Explorer"),right_body,true)
	_caption(right_body,tx("Today's work board","Tareas de hoy"),tx("Alerts are calculated from your actual fields and jobs.","Avisos calculados a partir de tus parcelas y trabajos."))
	var dry: int = 0
	var pests: int = 0
	var ripe: int = 0
	var constructing: int = 0
	for field in farm.state["fields"]:
		if not field["owned"]:
			continue
		if float(field["soil"]["water"]) < 30.0:
			dry += 1
		var worst: float = 0.0
		for pest in FarmScript.PEST_IDS:
			worst = maxf(worst,float(field["pests"].get(pest,0.0)))
		if worst >= 15.0:
			pests += 1
		if not field["crop"].is_empty() and float(field["crop"].get("development",0.0)) >= 0.995:
			ripe += 1
	_line(right_body,tx("Dry plots: ","Parcelas secas: ") + str(dry) + "   |   " + tx("Pest alerts: ","Alertas de plagas: ") + str(pests) + "   |   " + tx("Ready: ","Listas: ") + str(ripe),14,DANGER if (dry+pests)>0 else ACCENT)
	for building in farm.state["buildings"]:
		if int(building["target"]) > int(building["level"]):
			constructing += 1
	_line(right_body,tx("Construction jobs: ","Obras: ") + str(constructing) + "   |   " + tx("Processing jobs: ","Elaboración: ") + str(farm.state["processing"].size()),13,MUTED)
	var dashboard_buttons: HFlowContainer = HFlowContainer.new()
	right_body.add_child(dashboard_buttons)
	for pair in [[tx("Check crops","Revisar cultivos"),"Fields"],[tx("Inspect pests","Inspeccionar plagas"),"Ecology"],[tx("Open planner","Abrir diario"),"Journal"]]:
		var link: Button = _button(str(pair[0]),_change_tab.bind(str(pair[1])),dashboard_buttons)
		link.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var tip: int = int(farm.state["story"]["tutorial"])
	if tip < FarmScript.TUTORIAL.size():
		_caption(right_body,tx("Ines' field lessons","Lecciones de Ines"),tx("One small step at a time","Paso a paso"))
		_line(right_body,str(tip+1) + "/" + str(FarmScript.TUTORIAL.size()) + " - " + farm.n(FarmScript.TUTORIAL[tip], ""))
		_button(tx("Show the lesson tab","Abrir las lecciones"),_change_tab.bind("Story"),right_body)
	_caption(right_body,tx("Today's conditions","Condiciones de hoy"))
	_line(right_body,farm.weather_text(),14)
	var first: Dictionary = farm.field_of(selected_field)
	if first.is_empty() or not first["owned"]:
		first = farm.field_of("plot1")
	_line(right_body,tx("Selected field: ","Parcela seleccionada: ") + str(first["id"]))
	_line(right_body,tx("Water: ","Agua: ") + str(snappedf(float(first["soil"]["water"]),0.1)) + " mm")
	_line(right_body,tx("Soil N / P / K: ","Suelo N / P / K: ") + str(snappedf(float(first["soil"]["n"]),0.1)) + " / " + str(snappedf(float(first["soil"]["p"]),0.1)) + " / " + str(snappedf(float(first["soil"]["k"]),0.1)))
	_button(tx("Manage this field","Gestionar parcela"),_change_tab.bind("Fields"),right_body,true)
	_button(tx("Scout pests & natural allies","Revisar plagas y aliados"),_change_tab.bind("Ecology"),right_body)
	_button(tx("Scenic farm view","Vista panoramica de finca"),_show_panorama,right_body,true)
	_button(tx("Illustrated courtyard","Patio ilustrado"),_show_illustrated_view,right_body)
	_button(tx("Explore the valley map","Explorar el mapa del valle"),_change_tab.bind("Valley"),right_body)
	_button(tx("Visit the village market","Ir al mercado"),_enter_building.bind("market"),right_body)
	_button(tx("Talk to Ines","Hablar con Ines"),_show_neighbour.bind("ines"),right_body)
	var active_stories: int = farm.story_branches().size()
	var coming: int = farm.pending_story_events().size()
	if active_stories > 0:
		_caption(right_body,tx("Life in the village","La vida del pueblo"))
		_line(right_body,tx("Storylines started: ","Historias comenzadas: ")+str(active_stories)+"  ·  "+tx("Future visits: ","Próximas visitas: ")+str(coming),13,ACCENT)
		_button(tx("Review community consequences","Ver consecuencias comunitarias"),_change_tab.bind("Stories"),right_body,true)
	var event: Dictionary = farm.state["events"]["active"]
	if not event.is_empty():
		_caption(right_body,tx("Valley decision pending","Decision pendiente"))
		_line(right_body,Chains.title(str(event["id"]),language) if str(event.get("arc","")) != "" else Decisions.title(str(event["id"]),language))
		_button(tx("Review choices","Ver opciones"),_show_decision_board,right_body,true)


func _jump_to_field(id: String) -> void:
	_picked_field(id)
	if world != null:
		world.focus_field(id)

func _jump_to_region(region_id: String) -> void:
	selected_region = region_id
	active_tab = "Valley"
	if valley_view != null:
		valley_view.set_selected(region_id)
	_update_nav_state()
	_update_visual_mode()
	_render_panel()

func _localized_effect(id: String) -> String:
	var labels: Dictionary = {
		"water_saver":["Water-saving irrigation","Ahorro de agua"],
		"nutrient_shield":["Soil nutrient protection","Protección de nutrientes"],
		"spoilage_guard":["Refrigerated storage","Almacenamiento refrigerado"],
		"animal_welfare":["Livestock welfare support","Apoyo al bienestar animal"],
		"work_efficiency":["Well-maintained tools","Herramientas en buen estado"],
		"labor_slowdown":["Slower farm work","Trabajo más lento"],
		"pest_suppression":["Pest monitoring","Vigilancia de plagas"],
		"pollinator_bonus":["Pollinator corridors","Corredores de polinizadores"],
		"market_trust":["Village market trust","Confianza del mercado"]}
	var pair: Array = labels.get(id,[id,id])
	return str(pair[1] if language == "es" else pair[0])

func _panel_explorer() -> void:
	_caption(right_body,tx("Explore your entire farm","Explora toda tu finca"),tx("Everything is reachable from here, even while staying on the live map.","Desde aquí puedes acceder a todo sin salir del mapa vivo."))
	_button(tx("Open full-screen live farm","Abrir finca a pantalla completa"),_show_panorama,right_body,true)
	_button(tx("Visit the illustrated courtyard","Visitar patio ilustrado"),_show_illustrated_view,right_body)
	_caption(right_body,tx("FARM MANAGEMENT","GESTIÓN DE LA FINCA"))
	for pair in [["Farm",tx("Farm overview","Resumen de la finca")],["Fields",tx("Plant, water and harvest","Sembrar, regar y cosechar")],["Ecology",tx("Inspect soil, insects and disease","Revisar suelo, insectos y enfermedades")],["Resources",tx("Gather supplies and decorate","Recoger recursos y decorar")],["GardenStudio57",tx("Garden studio and relocation","Estudio del jardín y traslados")],["Expeditions58",tx("Explore regional projects","Explorar proyectos regionales")],["Planning",tx("Soil, forecast and today's plan","Suelo, pronostico y plan diario")],["Machinery",tx("Equipment maintenance","Mantenimiento de maquinaria")],["Economy",tx("Farm strategy and operating budget","Estrategia y presupuesto")],["Animals",tx("Visit and care for livestock","Visitar y cuidar animales")],["Buildings",tx("Construct and enter buildings","Construir y entrar en edificios")],["Processing",tx("Processing workshop","Taller de elaboración")],["Market",tx("Offers, contracts and the market","Ofertas, contratos y mercado")],["Stories",tx("Village relationships and story chains","Relaciones e historias del pueblo")]]:
		_button(str(pair[1]),_change_tab.bind(str(pair[0])),right_body)
	_caption(right_body,tx("YOUR FIELDS","TUS PARCELAS"),tx("Select a plot to centre the live map.","Elige una parcela para centrar el mapa vivo."))
	for field in farm.state["fields"]:
		if not bool(field["owned"]):
			continue
		var name: String = str(field["id"]).to_upper() + "  ·  " + farm.n(farm.content["terrains"][str(field["terrain"])])
		var crop_name: String = tx("Fallow","En barbecho") if field["crop"].is_empty() else farm.n(farm.content["crops"][str(field["crop"]["id"])])
		_button(name + " / " + crop_name,_jump_to_field.bind(str(field["id"])),right_body)
	_caption(right_body,tx("YOUR BUILDINGS","TUS EDIFICIOS"))
	_button(tx("Enter farmhouse","Entrar en casa"),_enter_building.bind("farmhouse"),right_body)
	_button(tx("Enter village market","Entrar en el mercado"),_enter_building.bind("market"),right_body)
	for built in farm.state["buildings"]:
		if int(built["level"]) > 0:
			_button(farm.n(farm.content["buildings"][str(built["kind"])]) + "  L" + str(built["level"]),_enter_building.bind(str(built["kind"])),right_body)
	_caption(right_body,tx("PEOPLE & PLACES","PERSONAS Y LUGARES"))
	_button(tx("Talk to the neighbours","Hablar con vecinos"),_change_tab.bind("Neighbours"),right_body)
	for region_id in FarmScript.REGIONS.keys():
		_button(farm.n(FarmScript.REGIONS[region_id]),_jump_to_region.bind(str(region_id)),right_body)
	_caption(right_body,tx("YOUR PROGRESS","TU PROGRESO"))
	for pair in [["Character",tx("Courses, talents and XP","Cursos, talentos y experiencia")],["Story",tx("Tutorial, quests and achievements","Tutorial, misiones y logros")],["Journal",tx("Diary and decisions","Diario y decisiones")],["Options",tx("Language and saves","Idioma y partidas")]]:
		_button(str(pair[1]),_change_tab.bind(str(pair[0])),right_body)

func _panel_expeditions58() -> void:
	_caption(right_body,tx("Beyond the Farm  ·  5.8","Mas alla de la finca  ·  5.8"),tx("Take part in lasting regional projects, collaborate with neighbours and choose your field profession.","Participa en proyectos regionales duraderos, colabora con vecinos y elige tu profesion de campo."))
	var rural58: Dictionary = farm.state["countryside54"]["beyond58"]
	var current_region58: String = str(farm.state["overworld"].get("last_region","village"))
	var day58: int = int(farm.state["time"]["day"])
	_line(right_body,tx("Regional projects completed: ","Proyectos regionales terminados: ") + str(rural58["completed"]) + "/" + str(Beyond58.PROJECTS.size()),16,ACCENT)
	_line(right_body,tx("Current region: ","Region actual: ") + farm.n(FarmScript.REGIONS.get(current_region58,FarmScript.REGIONS["village"])),13,MUTED)
	_caption(right_body,tx("Choose your field profession","Elige tu profesion de campo"))
	var profession58: String = str(rural58["profession"])
	_line(right_body,tx("Current: ","Actual: ") + (tx("Undecided","Sin elegir") if profession58 == "none" else Beyond58.label(Beyond58.PROFESSIONS[profession58],language)),15,ACCENT)
	var can_retrain58: bool = int(rural58["profession_change_day"]) < 1 or day58 - int(rural58["profession_change_day"]) >= 12
	for profession_id58 in Beyond58.PROFESSIONS.keys():
		var info58: Dictionary = Beyond58.PROFESSIONS[profession_id58]
		_line(right_body,Beyond58.label(info58,language),15,INK)
		_line(right_body,Beyond58.label(info58,language,"detail"),12,MUTED)
		var profession_button58: Button = _button(tx("Selected","Seleccionada") if profession58 == str(profession_id58) else (tx("Select", "Elegir") if profession58 == "none" else tx("Retrain for EUR 90","Cambiar por 90 EUR")),_ask.bind("chooseProfession58",{"profession":str(profession_id58)}),right_body)
		profession_button58.disabled = profession58 == str(profession_id58) or not can_retrain58
	_caption(right_body,tx("Regional expeditions","Expediciones regionales"),tx("Three persistent chapters in every region. Only one chapter per region per day.","Tres capitulos permanentes por region. Maximo un capitulo por region y dia."))
	var region_ids58: Array = Beyond58.REGION_ORDER
	var region_names58: Array = []
	for region_id58 in region_ids58:
		var region_project58: Dictionary = Beyond58.PROJECTS[str(region_id58)]
		var progress58: int = int(rural58["chapters"].get(str(region_id58),0))
		region_names58.append(Beyond58.label(region_project58,language) + "  " + str(progress58) + "/3")
	var region_menu58: OptionButton = _select(right_body,region_ids58,region_names58)
	region_menu58.select(maxi(0,region_ids58.find(selected_region)))
	region_menu58.item_selected.connect(_picked_countryside_region54.bind(region_ids58))
	var project58: Dictionary = Beyond58.PROJECTS.get(selected_region,{})
	if project58.is_empty():
		return
	var chapter58: int = int(rural58["chapters"].get(selected_region,0))
	var partner58: String = str(project58["partner"])
	var npc58: Dictionary = farm.content["npcs"].get(partner58,{})
	_line(right_body,Beyond58.label(project58,language),18,ACCENT)
	_line(right_body,Beyond58.label(project58,language,"story"),13,MUTED)
	_line(right_body,tx("Local partner: ","Colaborador: ") + farm.n(npc58) + "  ·  " + tx("Trust ","Confianza ") + str(farm.npc_trust(partner58)) + "/10",13)
	if selected_region != current_region58:
		_line(right_body,tx("Travel to this region to work on the project.","Viaja a esta region para trabajar en el proyecto."),13,MUTED)
		_button(tx("Travel to project region","Viajar a la region"),_ask.bind("explore",{"regionId":selected_region}),right_body,true)
	if chapter58 < 3:
		_line(right_body,tx("Next chapter ","Proximo capitulo ") + str(chapter58 + 1) + "/3  ·  " + Beyond58.step_label(project58,chapter58,language),15,INK)
		var fee58: float = float(project58["fee"]) * (0.85 if profession58 == "pathfinder" else 1.0) * (1.0 + 0.30 * float(chapter58))
		var energy58: float = float(project58["energy"]) * (0.80 if profession58 == "pathfinder" else 1.0)
		_line(right_body,"EUR " + str(snappedf(fee58,0.01)) + "  ·  " + str(project58["hours"]) + " h  ·  " + tx("Energy ","Energia ") + str(snappedf(energy58,0.1)),13,MUTED)
		if chapter58 == 1:
			var material58: String = str(project58["material"])
			_line(right_body,tx("Required: ","Necesitas: ") + str(project58["quantity"]) + " kg " + farm.n(farm.content["goods"].get(material58,{})) + "  (" + str(snappedf(farm.stock(material58),0.1)) + " kg)",13,MUTED)
		var cooldown58: bool = int(rural58["chapter_days"].get(selected_region,-1)) == day58
		if cooldown58:
			_line(right_body,tx("Next chapter available tomorrow.","El siguiente capitulo estara disponible manana."),13,DANGER)
		var project_button58: Button = _button(tx("Work on the next chapter","Trabajar en el siguiente capitulo"),_ask.bind("advanceProject58",{"regionId":selected_region,"approach":"protect"}),right_body,true)
		project_button58.disabled = cooldown58 or selected_region != current_region58
		if chapter58 == 2:
			var trade_button58: Button = _button(tx("Finish with trade (+EUR 65, less reputation)","Terminar con comercio (+65 EUR, menos reputacion)"),_ask.bind("advanceProject58",{"regionId":selected_region,"approach":"trade"}),right_body)
			trade_button58.disabled = cooldown58 or selected_region != current_region58
	else:
		_line(right_body,tx("Completed! Your project and relationship improvements are permanent.","Completado. Las mejoras del proyecto y las relaciones son permanentes."),14,ACCENT)
	_caption(right_body,tx("Your expedition journal","Tu diario de expediciones"))
	var records58: Array = rural58["history"]
	if records58.is_empty():
		_line(right_body,tx("No project chapters completed yet.","Todavia no has completado capitulos."),13,MUTED)
	else:
		for index58 in range(records58.size() - 1,maxi(-1,records58.size() - 9),-1):
			var record58: Dictionary = records58[index58]
			var area58: Dictionary = Beyond58.PROJECTS[str(record58["region"])]
			_line(right_body,tx("Day ","Dia ") + str(record58["day"]) + "  ·  " + Beyond58.label(area58,language) + "  " + str(record58["stage"]) + "/3",12,MUTED)
	_button(tx("Valley map and travel","Mapa del valle y viajes"),_change_tab.bind("Valley"),right_body)
	_button(tx("Local activities and villagers","Actividades y vecinos"),_change_tab.bind("Countryside54"),right_body)

func _panel_countryside54() -> void:
	_caption(right_body,tx("The living countryside","El campo vivo"),tx("Discover trails, meet villagers on their daily routes and enjoy local activities.","Descubre caminos, encuentra vecinos durante sus rutinas y participa en actividades."))
	var day: int = int(farm.state["time"]["day"])
	var hour: int = int(farm.state["time"]["hour"])
	var current_region: String = str(farm.state["overworld"].get("last_region","village"))
	var countryside_state: Dictionary = farm.state["countryside54"]
	_line(right_body,tx("You are currently at: ","Te encuentras en: ") + farm.n(FarmScript.REGIONS.get(current_region,FarmScript.REGIONS["village"])),14,ACCENT)
	_line(right_body,tx("Places found: ","Lugares descubiertos: ") + str(countryside_state["discovered"].size()) + "/" + str(Country54.SITES.size()) + "  |  " + tx("Activities: ","Actividades: ") + str(countryside_state["activities"]) + "  |  " + tx("Meetings: ","Encuentros: ") + str(countryside_state["meetings"]),12,MUTED)
	_caption(right_body,tx("Choose a destination on the valley map","Elige un destino en el mapa del valle"))
	var region_keys: Array = FarmScript.REGIONS.keys()
	var region_labels: Array = []
	for region_key in region_keys:
		region_labels.append(farm.n(FarmScript.REGIONS[region_key]))
	var region_picker: OptionButton = _select(right_body,region_keys,region_labels)
	var region_index: int = region_keys.find(selected_region)
	region_picker.select(maxi(0,region_index))
	region_picker.item_selected.connect(_picked_countryside_region54.bind(region_keys))
	_line(right_body,tx("Selected: ","Seleccionada: ") + farm.n(FarmScript.REGIONS.get(selected_region,FarmScript.REGIONS["village"])),15,ACCENT)
	if selected_region != current_region:
		_line(right_body,tx("Travel here before joining local activities. Your last travelled region is remembered.","Viaja aqui antes de participar en actividades locales. El juego recuerda tu ultimo destino."),12,MUTED)
		_button(tx("Travel to selected region","Viajar a la zona elegida"),_ask.bind("explore",{"regionId":selected_region}),right_body,true)
	_caption(right_body,tx("Scenic discoveries","Descubrimientos del paisaje"),tx("One-time discoveries; progress is saved in your journal.","Descubrimientos unicos; tu progreso queda guardado."))
	for site_id in Country54.locations_in(selected_region):
		var site_info: Dictionary = Country54.SITES[site_id]
		_line(right_body,Country54.label(site_info,language) + "  ·  " + (tx("Discovered","Descubierto") if countryside_state["discovered"].has(site_id) else tx("Unexplored","Sin explorar")),15,ACCENT)
		_line(right_body,Country54.label(site_info,language,"description"),12,MUTED)
		if not countryside_state["discovered"].has(site_id):
			var discover_button: Button = _button(tx("Explore site","Explorar lugar") + "  · EUR " + str(site_info["cost"]),_ask.bind("discoverSite54",{"siteId":str(site_id)}),right_body)
			discover_button.disabled = selected_region != current_region
	_caption(right_body,tx("Regional activity","Actividad de la zona"),tx("One activity per location and simulated day; each has real costs.","Una actividad por lugar y dia simulado, con costes reales."))
	for activity_id in Country54.activities_in(selected_region):
		var activity_info: Dictionary = Country54.ACTIVITIES[activity_id]
		_line(right_body,Country54.label(activity_info,language),15,ACCENT)
		_line(right_body,Country54.label(activity_info,language,"description"),12,MUTED)
		var already_done: bool = int(countryside_state["activity_days"].get(activity_id,-1)) == day
		var detail: String = "EUR " + str(activity_info["fee"]) + " · " + str(activity_info["hours"]) + "h · " + tx("Energy ","Energia ") + str(activity_info["energy"])
		_line(right_body,detail,12,MUTED)
		var activity_button: Button = _button(tx("Done today","Completado hoy") if already_done else tx("Join activity","Participar"),_ask.bind("countrysideActivity54",{"activityId":str(activity_id)}),right_body)
		activity_button.disabled = already_done or selected_region != current_region
	_caption(right_body,tx("Neighbours here now","Vecinos presentes ahora"),tx("Schedules change during the day and every seventh market day.","Las rutinas cambian durante el dia y cada septimo dia de mercado."))
	var villagers: Array = Country54.villagers_at(selected_region,day,hour)
	if villagers.is_empty():
		_line(right_body,tx("Nobody is scheduled here at this hour.","No hay vecinos previstos aqui a esta hora."),13,MUTED)
	for npc_id in villagers:
		var npc_data: Dictionary = farm.content["npcs"].get(str(npc_id),{})
		var met_today: bool = int(countryside_state["met_days"].get(npc_id,-1)) == day
		var npc_row: HBoxContainer = _hbox(right_body)
		_line(npc_row,farm.n(npc_data) + "  · " + tx("Trust ","Confianza ") + str(farm.npc_trust(str(npc_id))) + "/10",13)
		var meet_button: Button = _button(tx("Met today","Ya os visteis") if met_today else tx("Meet","Quedar"),_ask.bind("meetNeighbour54",{"npcId":str(npc_id)}),npc_row)
		meet_button.disabled = met_today or selected_region != current_region or hour < 7 or hour >= 21
	_caption(right_body,tx("Useful links","Accesos utiles"))
	_button(tx("Full valley travel map","Mapa del valle"),_change_tab.bind("Valley"),right_body)
	_button(tx("Talk and help neighbours","Hablar y ayudar a vecinos"),_change_tab.bind("Neighbours"),right_body)
	_button(tx("Explore regional projects","Explorar proyectos regionales"),_change_tab.bind("Expeditions58"),right_body,true)
	_button(tx("Farmhands and automation","Trabajadores y automatizacion"),_change_tab.bind("Planning"),right_body)

func _picked_countryside_region54(index: int, keys: Array) -> void:
	if index < 0 or index >= keys.size():
		return
	selected_region = str(keys[index])
	if valley_view != null and is_instance_valid(valley_view):
		valley_view.set_selected(selected_region)
	_render_panel()

func _panel_valley() -> void:
	_caption(right_body,tx("The living valley","El valle vivo"),tx("Choose a region on the map, then prepare for your trip.","Elige una zona en el mapa y prepara tu viaje."))
	_line(right_body,tx("Every region offers travel, forage and unique gathering opportunities.","Cada region ofrece viaje, recoleccion y materiales unicos."),13,MUTED)
	var region: Dictionary = FarmScript.REGIONS.get(selected_region,{})
	if region.is_empty():
		selected_region = "village"
		region = FarmScript.REGIONS[selected_region]
	_line(right_body,farm.n(region),21,ACCENT)
	_line(right_body,farm.n(region,"description"),14,MUTED)
	_line(right_body,tx("Travel time: ","Duracion del viaje: ") + str(region["hours"]) + " h",15)
	_line(right_body,tx("Travel expense: EUR ","Coste de viaje: EUR ") + str(region["fee"]),15)
	_line(right_body,tx("Wildlife encounter chance (game): ","Riesgo de fauna (juego): ") + str(int(float(region["risk"])*100.0)) + "%",13,DANGER)
	var goods: Dictionary = farm.content["goods"]
	var found: String = str(region["find"])
	_line(right_body,tx("Possible forage: ","Recoleccion posible: ") + farm.n(goods.get(found,{})),14)
	if FarmScript.MATERIAL_SITES.has(selected_region):
		var site: Dictionary = FarmScript.MATERIAL_SITES[selected_region]
		_line(right_body,tx("Gather: ","Materiales: ") + farm.n(goods[str(site["good"])]) + "  " + str(site["kg"]) + "kg",14,ACCENT)
		_line(right_body,tx("Field effort: ","Esfuerzo: ") + str(site["hours"]) + " h  |  " + tx("Energy ","Energia ") + str(site["energy"]) + "  |  EUR " + str(site["fee"]),13,MUTED)
		_button(tx("Gather resources here","Recoger materiales aqui"),_ask.bind("gatherMaterials",{"regionId":selected_region}),right_body)
	_button(tx("Travel here, with quoted cost","Viajar con coste previsto"),_ask.bind("explore",{"regionId":selected_region}),right_body,true)
	_button(tx("Activities, scenic trails and villagers","Actividades, senderos y vecinos"),_change_tab.bind("Countryside54"),right_body,true)
	_button(tx("Regional projects and professions","Proyectos y profesiones"),_change_tab.bind("Expeditions58"),right_body)
	_caption(right_body,tx("Outdoor equipment & stamina","Equipo y energia"))
	var wildlife: Dictionary = farm.state["wildlife"]
	_line(right_body,tx("Energy: ","Energia: ") + str(int(wildlife["energy"])) + "/100",15)
	_line(right_body,tx("Outdoor kit: ","Equipo de campo: ") + (tx("Owned","Comprado") if wildlife["gear"] else tx("Not owned","Sin comprar")),14)
	_line(right_body,tx("Recovery hours: ","Horas de recuperacion: ") + str(wildlife["venom_hours"]),14,DANGER if int(wildlife["venom_hours"]) > 0 else MUTED)
	if not wildlife["gear"]:
		_button(tx("Buy outdoor kit: EUR 120","Comprar equipo: 120 EUR"),_ask.bind("buyGear",{}),right_body)
	_button(tx("Rest four game hours","Descansar cuatro horas"),_ask.bind("rest",{}),right_body)
	_caption(right_body,tx("Regional gathering board","Tablon de recursos regionales"))
	for place in FarmScript.MATERIAL_SITES.keys():
		var site_info: Dictionary = FarmScript.MATERIAL_SITES[place]
		_line(right_body,farm.n(FarmScript.REGIONS[place]) + ": " + farm.n(goods[str(site_info["good"])]) + "  " + str(site_info["kg"]) + "kg",13)
	_caption(right_body,tx("Visited regions","Zonas visitadas"))
	for place in FarmScript.REGIONS.keys():
		var visits: int = int(farm.state["overworld"]["visits"].get(place,0))
		_line(right_body,farm.n(FarmScript.REGIONS[place]) + ": " + str(visits),13,MUTED)
	_line(right_body,tx("Venom is an abstract fictional wildlife hazard. This game provides no medical, poison or wildlife-safety guidance.","El veneno es un peligro ficticio de juego. No es guia medica ni de seguridad real."),12,MUTED)

func _panel_fields() -> void:
	_caption(right_body,tx("Your fields","Tus parcelas"),tx("Search and filter all 24 plots; select one to manage it.","Busca y filtra las 24 parcelas; elige una para gestionarla."))
	var search: LineEdit = _field(right_body,"",tx("Search plot number or crop...","Buscar parcela o cultivo..."))
	var filters: OptionButton = _select(right_body,["all","owned","for_sale","dry","pests","ready"],
		[tx("All fields","Todas"),tx("Owned fields","Propias"),tx("For sale","En venta"),tx("Dry fields","Secas"),tx("Pest alerts","Con plagas"),tx("Ready for harvest","Listas para cosechar")])
	var choice: OptionButton = _select(right_body,[selected_field],[selected_field])
	var refill: Callable = func():
		choice.clear()
		var selected_index: int = -1
		var term: String = search.text.strip_edges().to_lower()
		var filter_id: String = str(filters.get_item_metadata(filters.selected))
		for field in farm.state["fields"]:
			var crop: Dictionary = field["crop"]
			var crop_name: String = tx("Fallow","Barbecho") if crop.is_empty() else farm.n(farm.content["crops"][str(crop["id"])])
			var soil_water: float = float(field["soil"]["water"])
			var max_pest: float = 0.0
			for pest in FarmScript.PEST_IDS:
				max_pest = maxf(max_pest,float(field["pests"].get(pest,0.0)))
			var matches: bool = filter_id == "all" or (filter_id == "owned" and bool(field["owned"])) or (filter_id == "for_sale" and not bool(field["owned"])) or (filter_id == "dry" and field["owned"] and soil_water < 30.0) or (filter_id == "pests" and field["owned"] and max_pest >= 15.0) or (filter_id == "ready" and not crop.is_empty() and float(crop.get("development",0.0)) >= 0.995)
			if not matches or (term != "" and not (str(field["id"]).to_lower() + " " + crop_name.to_lower()).contains(term)):
				continue
			var field_id: String = str(field["id"])
			var label: String = field_id.to_upper() + " · " + crop_name + (" · " + tx("owned","propia") if field["owned"] else " · " + tx("for sale","en venta"))
			choice.add_item(label)
			var index: int = choice.item_count - 1
			choice.set_item_metadata(index,field_id)
			if field_id == selected_field:
				selected_index = index
		if choice.item_count == 0:
			choice.add_item(tx("No matching fields","No hay parcelas"))
			choice.set_item_disabled(0,true)
		else:
			choice.select(maxi(0,selected_index))
	search.text_changed.connect(func(_new_value):refill.call())
	filters.item_selected.connect(func(_index):refill.call())
	choice.item_selected.connect(func(index):_select_field_from_menu(str(choice.get_item_metadata(index))))
	refill.call()
	var f: Dictionary = farm.field_of(selected_field)
	var terrain: Dictionary = farm.content["terrains"][str(f["terrain"])]
	_line(right_body,farm.n(terrain),18,ACCENT)
	_line(right_body,farm.n(terrain,"benefit"),13)
	_line(right_body,farm.n(terrain,"risk"),13,DANGER)
	if not f["owned"]:
		_line(right_body,tx("Land price: EUR ","Precio terreno: EUR ") + str(farm.land_price(selected_field)),17)
		_button(tx("Purchase this field","Comprar parcela"),_ask.bind("buyField",{"fieldId":selected_field}),right_body,true)
		return
	var soil: Dictionary = f["soil"]
	var crop: Dictionary = f["crop"]
	var current_layout: String = str(f.get("plot_type","open"))
	var layout_info: Dictionary = Fields52.PLOTS[current_layout]
	_caption(right_body,tx("Plot layout / production system","Tipo de parcela / sistema de cultivo"),Fields52.localized(layout_info,language))
	_line(right_body,str(layout_info["description"].get(language,layout_info["description"]["en"])),13,MUTED)
	if crop.is_empty():
		var layout_ids: Array = []
		var layout_names: Array = []
		for layout_id in Fields52.PLOTS.keys():
			if not Fields52.allowed_layout(str(layout_id),str(f["terrain"])) or str(layout_id) == current_layout:
				continue
			if str(layout_id) in ["orchard","paddy"] and not farm.building_of("greenhouse",selected_field).is_empty():
				continue
			var candidate_info: Dictionary = Fields52.PLOTS[layout_id]
			layout_ids.append(layout_id)
			layout_names.append(Fields52.localized(candidate_info,language)+"  ·  EUR "+str(candidate_info["cost"]))
		if not layout_ids.is_empty():
			var layout_picker: OptionButton = _select(right_body,layout_ids,layout_names)
			_button(tx("Convert plot (confirm price)","Transformar parcela (confirmar precio)"),func():_ask("configurePlot",{"fieldId":selected_field,"plotType":str(layout_picker.get_item_metadata(layout_picker.selected))}),right_body)
		_line(right_body,tx("Layout changes require empty land, real cash and one conversion per game day.","Los cambios requieren suelo libre, dinero real y un cambio por dia de juego."),12,MUTED)
	if int(f.get("cover_until",0)) > int(farm.state["time"]["total"]):
		_line(right_body,tx("Cover crop protects this field for ","Cubierta vegetal protege durante ")+str(int(ceil(float(int(f["cover_until"])-int(farm.state["time"]["total"]))/24.0)))+tx(" more days"," dias mas"),13,ACCENT)
	if crop.is_empty():
		if int(f.get("cover_until",0)) > int(farm.state["time"]["total"]):
			_line(right_body,tx("Protective cover is still growing. Plant cash crops when it finishes.","La cubierta vegetal sigue creciendo. Siembra cuando termine."),14,ACCENT)
		else:
			_line(right_body,tx("Fallow soil - ready to plant","Tierra en descanso - lista para sembrar"),14)
		var crops: Dictionary = farm.content["crops"]
		var crop_ids: Array = crops.keys()
		var crop_labels: Array = []
		var compatible_ids: Array = []
		for id in crop_ids:
			if Fields52.allows_crop(f,crops[id]):
				compatible_ids.append(id)
				crop_labels.append(farm.n(crops[id]))
		crop_ids = compatible_ids
		var picker: OptionButton = _select(right_body,crop_ids,crop_labels)
		var variety_ids: Array = Fields52.VARIETIES.keys()
		var variety_names: Array = []
		for vid in variety_ids:
			var variety_data: Dictionary = Fields52.VARIETIES[vid]
			variety_names.append(Fields52.localized(variety_data,language) + "  ·  x" + str(variety_data["seed"]) + tx(" seed cost"," coste semilla"))
		var variety_picker: OptionButton = _select(right_body,variety_ids,variety_names)
		_button(tx("Plant selected crop and variety","Sembrar cultivo y variedad"),func():_ask("plant",{"fieldId":selected_field,"cropId":str(picker.get_item_metadata(picker.selected)),"variety":str(variety_picker.get_item_metadata(variety_picker.selected))}),right_body,true)
		_line(right_body,tx("Early seeds mature faster but yield less. Resilient seeds cost more and tolerate drought.","La semilla temprana madura antes pero rinde menos. La resistente cuesta mas y soporta sequia."),12,MUTED)
	else:
		var crop_info: Dictionary = farm.content["crops"][str(crop["id"])]
		_line(right_body,farm.n(crop_info) + "   " + str(int(float(crop["development"])*100)) + "%",18,ACCENT)
		_line(right_body,tx("Variety: ","Variedad: ")+Fields52.localized(Fields52.VARIETIES[str(crop.get("variety","standard"))],language),13,MUTED)
		if bool(crop_info.get("perennial",false)):
			_line(right_body,tx("Perennial: the plant remains after harvest. Completed harvest cycles: ","Perenne: la planta permanece tras cosechar. Cosechas completadas: ")+str(crop.get("harvest_cycles",0)),13,ACCENT)
		_line(right_body,tx("Biomass: ","Biomasa: ") + str(snappedf(float(crop["biomass"]),0.1)) + " kg/ha")
		_line(right_body,tx("Crop condition: ","Estado: ") + str(int(float(crop["health"])*100)) + "%")
		_line(right_body,tx("Visible growth stage: ","Fase de crecimiento: ") + Visual.crop_stage_text(float(crop["development"]),language=="es"),14,ACCENT)
		_line(right_body,tx("Visual plant health: ","Salud visual de la planta: ") + str(int(Visual.plant_health(f)*100.0)) + "%",13,MUTED)
		var harvest_button: Button = _button(tx("Harvest ready crop","Recoger cosecha"),_ask.bind("harvest",{"fieldId":selected_field}),right_body,true)
		harvest_button.disabled = float(crop["development"]) < 0.995
	_line(right_body,tx("Root-zone water: ","Agua en raiz: ") + str(snappedf(float(soil["water"]),0.1)) + " / " + str(soil["capacity"]) + " mm")
	_line(right_body,"N " + str(snappedf(float(soil["n"]),0.1)) + "  P " + str(snappedf(float(soil["p"]),0.1)) + "  K " + str(snappedf(float(soil["k"]),0.1)),13)
	_line(right_body,tx("Organic matter ","Materia organica ")+str(snappedf(float(soil["organic_matter"]),0.01))+"% · "+tx("Compaction ","Compactacion ")+str(int(float(soil["compaction"])*100.0))+"% · "+tx("Erosion ","Erosion ")+str(int(float(soil["erosion"])*100.0))+"%",13,ACCENT if farm.soil_health(selected_field)>=0.85 else DANGER)
	var care_row: HBoxContainer = _hbox(right_body)
	_button(tx("Aerate soil","Airear suelo"),_ask.bind("aerateSoil",{"fieldId":selected_field}),care_row)
	_button(tx("Plant hedgerow","Plantar seto"),_ask.bind("plantHedgerow",{"fieldId":selected_field}),care_row)
	if crop.is_empty() and int(f.get("cover_until",0)) <= int(farm.state["time"]["total"]):
		_button(tx("Sow protective cover crop (4 days)","Sembrar cubierta protectora (4 dias)"),_ask.bind("coverCrop",{"fieldId":selected_field}),right_body)
	if crop.is_empty():
		_caption(right_body,tx("Crop rotation planner","Planificador de rotacion"))
		for idea in farm.rotation_advice(selected_field,3):
			_line(right_body,str(idea["name"])+" · "+str(int(idea["score"]))+"/100"+(tx(" (same family penalty)"," (penalizacion por repetir familia)") if bool(idea["repeat"]) else ""),13,ACCENT if not bool(idea["repeat"]) else DANGER)
	var ir: HBoxContainer = _hbox(right_body)
	_line(ir,tx("Irrigate (mm)","Riego (mm)"),13)
	var irrigation: SpinBox = _spin(ir,15,1,60,1)
	_button(tx("Irrigate","Regar"),func():_ask("irrigate",{"fieldId":selected_field,"mm":irrigation.value}),right_body)
	var fert: HBoxContainer = _hbox(right_body)
	var elements: OptionButton = _select(fert,["n","p","k"],["N", "P", "K"])
	var quantity: SpinBox = _spin(fert,12,1,80,1)
	_button(tx("Apply fertilizer","Abonar"),func():_ask("fertilize",{"fieldId":selected_field,"element":str(elements.get_item_metadata(elements.selected)),"kg":quantity.value}),right_body)
	var care: HBoxContainer = _hbox(right_body)
	_button(tx("Compost","Compost"),_ask.bind("compost",{"fieldId":selected_field}),care)
	_button(tx("Mulch","Acolchado"),_ask.bind("mulch",{"fieldId":selected_field}),care)
	_button(tx("Inspect","Inspeccionar"),_direct.bind("inspect",{"fieldId":selected_field}),right_body)
	_button(tx("Focus this field on map","Centrar parcela en mapa"),func():world.focus_field(selected_field),right_body)
	if farm.stock("manure") >= 10.0:
		_button(tx("Recycle 10 kg manure into soil","Usar 10 kg estiercol en el suelo"),_ask.bind("useManure",{"fieldId":selected_field}),right_body)
	var treatment: OptionButton = _select(right_body,["soap","bt","trap","nets","spray","fungicide","solarize"],["Soap / Jabon","Selective Bt","Slug / insect traps","Protection nets","Broad spray","Fungicide","Soil solarization"])
	_button(tx("Apply selected control","Aplicar control"),func():_ask("treat",{"fieldId":selected_field,"method":str(treatment.get_item_metadata(treatment.selected))}),right_body)
	var allies: HBoxContainer = _hbox(right_body)
	_button(tx("Release ladybirds","Soltar mariquitas"),_ask.bind("release",{"fieldId":selected_field,"species":"ladybirds"}),allies)
	_button(tx("Release parasitoids","Soltar parasitoides"),_ask.bind("release",{"fieldId":selected_field,"species":"parasitoids"}),allies)
	_line(right_body,tx("Tip: inspect before treating. A broad spray harms natural enemies.","Consejo: inspecciona antes de tratar. El insecticida general perjudica a auxiliares."),13,MUTED)
	if farm.stock("compost") >= 5.0:
		_button(tx("Use 5 kg recycled compost","Aplicar 5 kg de compost"),_ask.bind("spreadCompost",{"fieldId":selected_field}),right_body)

func _panel_crop_guide52() -> void:
	_caption(right_body,tx("Crop guide · 5.2","Guía de cultivos · 5.2"),tx("All 27 crops, their plot needs and seed strategies.","Los 27 cultivos, sus parcelas y estrategias de semilla."))
	var f: Dictionary = farm.field_of(selected_field)
	if not f.is_empty():
		_line(right_body,tx("Selected field: ","Parcela seleccionada: ") + selected_field.to_upper()+" · "+Fields52.localized(Fields52.PLOTS[str(f.get("plot_type","open"))],language),14,ACCENT)
	var crop_ids: Array = farm.content["crops"].keys()
	var crop_labels: Array = []
	for crop_id in crop_ids:
		var crop_entry: Dictionary = farm.content["crops"][crop_id]
		crop_labels.append(farm.n(crop_entry)+" · "+Fields52.crop_group(crop_entry,language=="es"))
	var crop_picker: OptionButton = _select(right_body,crop_ids,crop_labels)
	var details: VBoxContainer = _vbox(right_body,7)
	var refresh_crop: Callable = func(index: int):
		for previous in details.get_children():
			details.remove_child(previous)
			previous.queue_free()
		var crop_id: String = str(crop_picker.get_item_metadata(index))
		var entry: Dictionary = farm.content["crops"][crop_id]
		_line(details,farm.n(entry),21,ACCENT)
		_line(details,str(entry["description"].get(language,entry["description"]["en"])),14,MUTED)
		_line(details,tx("Plot: ","Parcela: ")+Fields52.crop_group(entry,language=="es"),14)
		_line(details,tx("Growing hours: ","Horas de crecimiento: ")+str(entry["growHours"])+" · "+tx("seed cost/ha: EUR ","semilla/ha: EUR ")+str(entry["seedCost"]),13)
		_line(details,tx("Base market price: EUR ","Precio base en mercado: EUR ")+str(farm.content["goods"][crop_id]["basePrice"])+"/kg",13)
		if bool(entry.get("perennial",false)):
			_line(details,tx("Perennial: regrowth after each harvest takes ","Perenne: cada rebrote necesita ")+str(entry["regrowHours"])+tx(" hours."," horas."),13,ACCENT)
		if not f.is_empty() and bool(f["owned"]):
			_line(details,tx("Compatible with your selected field: ","Compatible con tu parcela: ")+(tx("YES","SÍ") if Fields52.allows_crop(f,entry) else tx("NO — change plot layout first","NO — cambia el tipo de parcela")),14,ACCENT if Fields52.allows_crop(f,entry) else DANGER)
	crop_picker.item_selected.connect(refresh_crop)
	refresh_crop.call(0)
	_button(tx("Open field management","Abrir gestión de parcelas"),_change_tab.bind("Fields"),right_body,true)

func _panel_ecology() -> void:
	_caption(right_body,tx("Soil & living ecology","Suelo y ecologia"),tx("Real field readings change with the weather","Lecturas que cambian con el clima"))
	var f: Dictionary = farm.field_of(selected_field)
	if not f.get("owned",false):
		_line(right_body,tx("Choose an owned field first","Elige una parcela propia"))
		return
	var soil: Dictionary = f["soil"]
	_line(right_body,tx("Selected field: ","Parcela: ")+selected_field,17,ACCENT)
	_line(right_body,"Water " + str(snappedf(float(soil["water"]),0.1)) + " mm  /  " + str(soil["capacity"]) + " mm")
	_line(right_body,"N " + str(snappedf(float(soil["n"]),0.1)) + " kg   P " + str(snappedf(float(soil["p"]),0.1)) + " kg   K " + str(snappedf(float(soil["k"]),0.1)) + " kg")
	_line(right_body,"Organic N " + str(snappedf(float(soil["organic_n"]),0.1)) + "   Mulch " + str(int(float(soil["mulch"])*100)) + "%",13,MUTED)
	_line(right_body,tx("Soil organic matter: ","Materia organica del suelo: ")+str(snappedf(float(soil["organic_matter"]),0.01))+"%",14,ACCENT)
	_line(right_body,tx("Compaction: ","Compactacion: ")+str(int(float(soil["compaction"])*100.0))+"%  ·  "+tx("Erosion: ","Erosion: ")+str(int(float(soil["erosion"])*100.0))+"%",13)
	_line(right_body,tx("Soil vitality: ","Vitalidad del suelo: ")+Life.soil_label(f,language=="es")+" ("+str(int(farm.soil_health(selected_field)*100.0))+"%)",14,ACCENT)
	_line(right_body,tx("Hedgerow: ","Seto natural: ")+(tx("planted","plantado") if bool(f.get("hedgerow",false)) else tx("not planted","sin plantar")),13)
	var scouted: bool = int(f.get("scouted_day",-1)) == int(farm.state["time"]["day"])
	_button(tx("Scout pests (EUR 14)","Inspeccion tecnica de plagas (14 EUR)"),_ask.bind("scoutField",{"fieldId":selected_field}),right_body,true)
	if not scouted:
		_line(right_body,tx("Detailed pest readings are unknown today. Scout to obtain fresh measurements; old reports remain dated.","Las mediciones exactas de plagas son desconocidas hoy. Contrata una inspeccion para obtener datos actuales."),13,DANGER)
	else:
		_line(right_body,tx("Fresh field report for today","Informe de campo actualizado hoy"),13,ACCENT)
	if float(soil["water"]) < 30:
		_line(right_body,tx("DRY: growth may slow. Consider water or mulch.","SECO: el crecimiento puede bajar. Considera riego o acolchado."),13,DANGER)
	elif float(soil["water"]) > 125:
		_line(right_body,tx("WET: monitor slugs and root rot.","HUMEDO: vigila babosas y podredumbre de raiz."),13,DANGER)
	_caption(right_body,tx("Eight pest groups","Ocho grupos de plagas"))
	var report: Dictionary = f.get("scout_report",{})
	var old_day: int = int(f.get("scouted_day",-1))
	if old_day >= 0:
		_line(right_body,tx("Report day: ","Informe del dia: ")+str(old_day)+(tx(" (outdated)"," (desactualizado)") if not scouted else ""),12,MUTED)
	for pest in FarmScript.PEST_IDS:
		var info: Dictionary = farm.content["pests"][pest]
		var caption: String = farm.n(info) + ": " + (str(snappedf(float(report.get("pests",{}).get(pest,0.0)),0.1)) if old_day >= 0 else "?")
		_line(right_body,caption,13,DANGER if scouted and float(report.get("pests",{}).get(pest,0.0)) > 15 else INK)
	_caption(right_body,tx("Three diseases","Tres enfermedades"))
	for disease in FarmScript.DISEASE_IDS:
		_line(right_body,farm.n(farm.content["diseases"][disease]) + ": " + (str(int(float(report.get("diseases",{}).get(disease,0.0))*100)) + "%" if old_day>=0 else "?"),13)
	_caption(right_body,tx("Beneficial organisms","Organismos auxiliares"))
	for id in f["beneficial"].keys():
		_line(right_body,str(id) + ": " + str(snappedf(float(f["beneficial"][id]),0.1)),13)
	_button(tx("Go to field actions","Volver a tratamientos"),_change_tab.bind("Fields"),right_body,true)
	_line(right_body,tx("Educational game values, not real pest thresholds or fertilizer advice.","Datos de videojuego, no consejos agricolas reales."),12,MUTED)

func _panel_planning() -> void:
	_caption(right_body,tx("Tomorrow starts today","El manana empieza hoy"),tx("Forecast probabilities are estimates. Outcomes remain uncertain.","Las probabilidades son orientativas; el clima real sigue siendo incierto."))
	_line(right_body,tx("Current weather: ","Tiempo actual: ")+farm.weather_text(),14,ACCENT)
	for report in farm.farm_forecast():
		_line(right_body,tx("Day ","Dia ")+str(report["day"])+" · "+str(report["summary"])+" · "+str(report["rain_percent"])+"% "+tx("rain risk","prob. lluvia")+" · "+str(report["temperature"])+"°C",13)
	_caption(right_body,tx("Your soil at a glance","Tus suelos de un vistazo"))
	var healthy: int = 0
	var degraded: int = 0
	var vacant: int = 0
	for f in farm.state["fields"]:
		if not bool(f["owned"]):
			continue
		if farm.soil_health(str(f["id"])) >= 0.9:
			healthy += 1
		else:
			degraded += 1
		if f["crop"].is_empty():
			vacant += 1
	_line(right_body,tx("Healthy fields ","Parcelas sanas ")+str(healthy)+" · "+tx("Need care ","Requieren cuidados ")+str(degraded)+" · "+tx("Fallow ","Barbecho ")+str(vacant),14)
	_button(tx("Improve selected field","Mejorar parcela seleccionada"),_change_tab.bind("Fields"),right_body,true)
	_caption(right_body,tx("Recommended next crops","Cultivos recomendados para rotacion"))
	for suggestion in farm.rotation_advice(selected_field,4):
		_line(right_body,str(suggestion["name"])+"  "+str(int(suggestion["score"]))+"/100"+(tx(" · rotation risk"," · riesgo de repeticion") if suggestion["repeat"] else ""),13)
	_caption(right_body,tx("Tomorrow's budget commitments","Compromisos economicos de manana"))
	var b: Dictionary = farm.operating_budget()
	_line(right_body,tx("Buildings per day: EUR ","Edificios al dia: EUR ")+str(snappedf(float(b["building_upkeep"]),0.01)),13)
	_line(right_body,tx("Machines per day: EUR ","Maquinas al dia: EUR ")+str(snappedf(float(b["machine_upkeep"]),0.01)),13)
	_line(right_body,tx("Seven days of fixed costs: EUR ","Siete dias de costes fijos: EUR ")+str(snappedf(float(b["week_fixed"]),0.01)),14,ACCENT)
	_line(right_body,tx("Estimated animal feed/day: ","Pienso estimado/dia: ")+str(snappedf(float(b["feed_estimate"]),0.1))+" kg · "+tx("water/day: ","agua/dia: ")+str(snappedf(float(b["water_estimate"]),0.1))+" m³",13,MUTED)
	_line(right_body,tx("Variable costs (seeds, water, feed, labour) are NOT included.","Los costes variables (semillas, agua, pienso, mano de obra) NO estan incluidos."),12,MUTED)
	_button(tx("Review business strategy","Revisar estrategia"),_change_tab.bind("Economy"),right_body)

func _panel_garden_studio57() -> void:
	_caption(right_body,tx("Garden Studio · 5.7", "Estudio del jardín · 5.7"), tx("Choose a numbered spot on the live map or in the list. Place new decorations and move finished ones without losing them.", "Elige una posición numerada en el mapa o en la lista. Coloca adornos y mueve los terminados sin perderlos."))
	var placed57: Array = farm.state["decorations"]
	var vacant57: Array = Living57.open_slots(placed57)
	var chosen57: Dictionary = Living57.decoration_at(placed57, selected_garden_slot57)
	_line(right_body,tx("Position ", "Posición ") + str(selected_garden_slot57 + 1) + " / 24  ·  " + (tx("Free", "Libre") if chosen57.is_empty() else farm.n(FarmScript.DECORATIONS[str(chosen57["kind"])])),16,ACCENT)
	_line(right_body,tx("Free positions: ", "Posiciones libres: ") + str(vacant57.size()) + "/24",13,MUTED)
	if compact_mode:
		_button(tx("Pick a position on the map", "Elegir posición sobre el mapa"),_show_garden_map57,right_body,true)
	var slot_ids57: Array = []
	var slot_names57: Array = []
	for idx57 in range(Living57.GARDEN_SLOTS):
		slot_ids57.append(idx57)
		var occupied57: bool = not Living57.decoration_at(placed57, idx57).is_empty()
		slot_names57.append("#" + str(idx57 + 1) + "  ·  " + (tx("Occupied", "Ocupada") if occupied57 else tx("Free", "Libre")))
	var slots57: OptionButton = _select(right_body,slot_ids57,slot_names57)
	slots57.select(clampi(selected_garden_slot57,0,Living57.GARDEN_SLOTS - 1))
	slots57.item_selected.connect(func(index57: int): _choose_garden_slot57(int(slots57.get_item_metadata(index57))))
	if not chosen57.is_empty() and not bool(chosen57["completed"]):
		var due57: int = maxi(0,int(chosen57["ready_at"]) - int(farm.state["time"]["total"]))
		_line(right_body,tx("Construction remaining: ", "Obra pendiente: ") + str(due57) + " h",13,DANGER)
	_caption(right_body,tx("Create a decoration", "Construir un adorno"))
	var design_ids57: Array = FarmScript.DECORATIONS.keys()
	var design_labels57: Array = []
	for design_key57 in design_ids57:
		design_labels57.append(farm.n(FarmScript.DECORATIONS[design_key57]))
	var design_menu57: OptionButton = _select(right_body,design_ids57,design_labels57)
	var cost_label57: Label = _line(right_body,"",13,MUTED)
	var refresh_cost57: Callable = func():
		var spec57: Dictionary = FarmScript.DECORATIONS[str(design_menu57.get_item_metadata(design_menu57.selected))]
		var needs57: Array = []
		for good57 in spec57["materials"].keys():
			needs57.append(str(spec57["materials"][good57]) + " kg " + str(good57) + " (" + str(snappedf(farm.stock(str(good57)),0.1)) + ")")
		cost_label57.text = "EUR " + str(spec57["fee"]) + " · " + str(spec57["hours"]) + "h · " + tx("Level ", "Nivel ") + str(spec57["level"]) + "\n" + ", ".join(PackedStringArray(needs57))
	design_menu57.item_selected.connect(func(_idx57: int): refresh_cost57.call())
	refresh_cost57.call()
	var craft57: Button = _button(tx("Build at selected position", "Construir en posición elegida"),func():_ask("craftDecoration",{"decorationId":str(design_menu57.get_item_metadata(design_menu57.selected)),"slot":selected_garden_slot57}),right_body,true)
	craft57.disabled = not chosen57.is_empty() or vacant57.is_empty()
	_caption(right_body,tx("Rearrange your finished garden", "Reorganizar el jardín"))
	_line(right_body,tx("Moving costs EUR 18 and 4 energy. Construction must be finished and the destination free.", "Trasladar cuesta 18 EUR y 4 de energía. El adorno debe estar terminado y el destino libre."),13,MUTED)
	if placed57.is_empty():
		_line(right_body,tx("Build a decoration first.", "Primero construye un adorno."),13,MUTED)
	else:
		var move_ids57: Array = []
		var move_labels57: Array = []
		for deco57 in placed57:
			move_ids57.append(str(deco57["id"]))
			move_labels57.append(farm.n(FarmScript.DECORATIONS[str(deco57["kind"])]) + "  ·  #" + str(int(deco57["slot"]) + 1))
		var source57: OptionButton = _select(right_body,move_ids57,move_labels57)
		var source_index57: int = move_ids57.find(selected_deco_id57)
		if source_index57 < 0:
			source_index57 = 0
		source57.select(source_index57)
		selected_deco_id57 = str(move_ids57[source_index57])
		source57.item_selected.connect(func(index57: int): _set_source_garden57(str(source57.get_item_metadata(index57))))
		var move57: Button = _button(tx("Move selected decoration here", "Mover adorno a esta posición"),func(): _ask("relocateDecoration",{"decorationId":str(source57.get_item_metadata(source57.selected)),"slot":selected_garden_slot57}),right_body)
		move57.disabled = not chosen57.is_empty() or vacant57.is_empty()
	_caption(right_body,tx("Your existing garden", "Adornos colocados"))
	for deco57 in placed57:
		var remaining57: int = maxi(0,int(deco57["ready_at"]) - int(farm.state["time"]["total"]))
		var state57: String = tx("Ready", "Listo") if bool(deco57["completed"]) else str(remaining57) + " h"
		_line(right_body,"#" + str(int(deco57["slot"]) + 1) + "  " + farm.n(FarmScript.DECORATIONS[str(deco57["kind"])]) + "  ·  " + state57,13)
	_button(tx("Gather more materials", "Recoger más materiales"),_change_tab.bind("Resources"),right_body)

func _panel_machinery() -> void:
	_caption(right_body,tx("Machinery yard","Parque de maquinaria"),tx("Equipment changes actual costs and resources. Usage wears parts; neglected machines can break down.","La maquinaria cambia los costes reales. Se desgasta con el uso y puede averiarse."))
	_line(right_body,tx("Owned machines are visible and selectable near the village in both map perspectives.", "Las máquinas compradas aparecen junto al pueblo y se pueden tocar en ambos mapas."),13,MUTED)
	for id in Life.MACHINES.keys():
		var definition: Dictionary = Life.MACHINES[id]
		var image57: TextureRect = TextureRect.new()
		var machine_image_path57: String = "res://assets/machine57_" + str(id) + ".png"
		image57.texture = load(machine_image_path57)
		image57.custom_minimum_size = Vector2(136,84)
		image57.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image57.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		right_body.add_child(image57)
		_caption(right_body,farm.n(definition))
		_line(right_body,farm.n(definition,"description"),13,MUTED)
		var machine: Dictionary = farm.state["life"]["machines"].get(id,{})
		if machine.is_empty():
			_line(right_body,"EUR "+str(definition["cost"])+" · "+tx("daily EUR ","diario EUR ")+str(definition["upkeep"]),13)
			_button(tx("Purchase machine","Comprar maquina"),_ask.bind("buyMachine",{"machineId":id}),right_body,true)
		else:
			var broken: bool = int(machine["broken_until"]) > int(farm.state["time"]["total"])
			_line(right_body,tx("Condition ","Estado ")+str(int(float(machine["condition"])*100))+"% · "+tx("jobs ","usos ")+str(machine["hours_used"])+(tx(" · OUT OF ORDER"," · AVERIADA") if broken else ""),13,DANGER if broken or float(machine["condition"])<0.35 else ACCENT)
			_line(right_body,tx("Current performance ","Rendimiento actual ")+str(int(farm.machine_efficiency(id)*100.0))+"%",13)
			_button(tx("Service this machine","Revisar maquinaria"),_ask.bind("serviceMachine",{"machineId":id}),right_body)
	_line(right_body,tx("Breakdowns recorded: ","Averias registradas: ")+str(farm.state["life"]["machine_breakdowns"]),13,MUTED)

func _panel_economy() -> void:
	_caption(right_body,tx("Choose how your farm grows","Elige como crece tu finca"),tx("Specializations offer trade-offs, not guaranteed wins. First selection is free; retraining costs EUR 240 and has a 12-day cooldown.","Las especializaciones tienen ventajas e inconvenientes. La primera eleccion es gratis; cambiar cuesta 240 EUR y requiere 12 dias."))
	var current_path: String = str(farm.state["life"]["path"])
	_line(right_body,tx("Current strategy: ","Estrategia actual: ")+farm.n(Life.PATHS[current_path]),17,ACCENT)
	for id in Life.PATHS.keys():
		var plan: Dictionary = Life.PATHS[id]
		_line(right_body,farm.n(plan)+("  ✓" if id==current_path else ""),15,ACCENT if id==current_path else INK)
		_line(right_body,farm.n(plan,"description"),13,MUTED)
		if id != current_path:
			_button(tx("Choose this strategy","Elegir esta estrategia"),_ask.bind("choosePath",{"path":id}),right_body)
	_caption(right_body,tx("Operating budget","Presupuesto operativo"))
	var b: Dictionary = farm.operating_budget()
	_line(right_body,tx("Available money: EUR ","Dinero disponible: EUR ")+str(snappedf(float(b["cash"]),0.01)),17,ACCENT)
	_line(right_body,tx("Building maintenance / day: EUR ","Coste de edificios / dia: EUR ")+str(snappedf(float(b["building_upkeep"]),0.01)),13)
	_line(right_body,tx("Equipment maintenance / day: EUR ","Coste maquinaria / dia: EUR ")+str(snappedf(float(b["machine_upkeep"]),0.01)),13)
	_line(right_body,tx("Cash coverage for FIXED costs: ","Cobertura SOLO gastos fijos: ")+(tx("No fixed costs","Sin costes fijos") if float(b["days_runway"])<0 else str(int(b["days_runway"]))+tx(" days"," dias")),14)
	_line(right_body,tx("Future sales are uncertain; this excludes feed, water, land, crop labour and purchases.","Las ventas son inciertas; no incluye pienso, agua, terrenos, mano de obra ni compras."),12,MUTED)
	_caption(right_body,tx("Premium harvest inventory","Cosecha premium almacenada"))
	var any_quality: bool = false
	for id in farm.state["life"]["quality_stock"].keys():
		if farm.premium_stock(str(id)) <= 0.01:
			continue
		any_quality = true
		_line(right_body,farm.n(farm.content["goods"][id])+": "+str(snappedf(farm.premium_stock(str(id)),0.1))+tx(" kg (28% base price bonus)"," kg (+28% sobre precio base)"),13,ACCENT)
	if not any_quality:
		_line(right_body,tx("No premium-quality crops stored yet.","Todavia no hay cosechas de calidad premium."),13,MUTED)
	_button(tx("Go to market","Ir al mercado"),_change_tab.bind("Market"),right_body,true)

func _panel_buildings() -> void:
	_caption(right_body,tx("Buildings and landscapes","Edificios y decoracion"),tx("Construction is timed; completed buildings can be visited.","Las obras requieren tiempo y los edificios se pueden visitar."))
	var catalog: Dictionary = farm.content["buildings"]
	var building_ids: Array = catalog.keys()
	var building_names: Array = []
	for id in building_ids:
		building_names.append(farm.n(catalog[id]))
	var pick: OptionButton = _select(right_body,building_ids,building_names)
	if not building_ids.has(selected_building_kind):
		selected_building_kind = str(building_ids[0])
	pick.select(building_ids.find(selected_building_kind))
	var show_details: Label = _line(right_body,"",14,MUTED)
	var update: Callable = func():
		var id: String = str(pick.get_item_metadata(pick.selected))
		var b: Dictionary = catalog[id]
		show_details.text = farm.n(b,"description") + "\nEUR " + str(b["cost"]) + " / " + str(b["buildHours"]) + " h  /  " + str(b["scope"])
	pick.item_selected.connect(func(_i):
		selected_building_kind = str(pick.get_item_metadata(pick.selected))
		update.call()
	)
	update.call()
	_line(right_body,tx("Field buildings use the chosen plot; other structures use one of 24 marked construction slots.","Los edificios de parcela usan la parcela elegida. Los demas utilizan una de las 24 posiciones del mapa."),12,MUTED)
	var slots: Array = []
	var names: Array = []
	for number in range(Life.CONSTRUCTION_SLOT_COUNT):
		slots.append(number)
		var occupant: String = ""
		for existing in farm.state["buildings"]:
			if str(existing.get("field","")) == "" and int(existing.get("slot",-1)) == number:
				occupant = str(existing["kind"])
		var prefix: String = tx("North ","Norte ") if number%2 == 0 else tx("South ","Sur ")
		names.append(prefix+str(int(number/2)+1)+" · "+(tx("Free","Libre") if occupant=="" else occupant))
	var slot_select: OptionButton = _select(right_body,slots,names)
	var slot_guess: int = Life.suggested_slot(farm.state["buildings"])
	if selected_build_slot < 0:
		selected_build_slot = slot_guess
	if selected_build_slot >= 0:
		slot_select.select(selected_build_slot)
		world.active_build_slot = selected_build_slot
		world.queue_redraw()
	slot_select.item_selected.connect(func(index):
		selected_build_slot = int(slot_select.get_item_metadata(index))
		world.active_build_slot = selected_build_slot
		world.queue_redraw()
	)
	_line(right_body,tx("Tip: click any free numbered circle on the map to choose its construction position.","Consejo: pulsa un circulo numerado libre del mapa para elegir donde construir."),12,ACCENT)
	_button(tx("Build in selected position","Construir en posicion elegida"),func():_ask("build",{"buildingId":str(pick.get_item_metadata(pick.selected)),"fieldId":selected_field,"slot":int(slot_select.get_item_metadata(slot_select.selected))}),right_body,true)
	_button(tx("Visit your farmhouse","Visitar la casa"),_enter_building.bind("farmhouse"),right_body)
	_caption(right_body,tx("Your structures","Tus construcciones"))
	if farm.state["buildings"].is_empty():
		_line(right_body,tx("No structures built yet. A storehouse makes the next harvest easier.","No has construido nada. Un almacen te ayudara a guardar cosechas."),13,MUTED)
	for b in farm.state["buildings"]:
		var bdef: Dictionary = catalog[str(b["kind"])]
		var title: String = farm.n(bdef) + "  L" + str(b["level"])
		if int(b["target"]) > int(b["level"]):
			title += "  (" + str(maxi(0,int(b["ready_at"])-int(farm.state["time"]["total"]))) + "h)"
		_line(right_body,title+(" · "+tx("slot ","posicion ")+str(int(b.get("slot",-1))+1) if str(b.get("field",""))=="" else " · "+str(b["field"])),14)
		var row: HBoxContainer = _hbox(right_body)
		var visit: Button = _button(tx("Visit","Visitar"),_enter_building.bind(str(b["kind"])),row)
		visit.disabled = int(b["level"]) < 1
		var upgrade: Button = _button(tx("Upgrade","Mejorar"),_ask.bind("upgrade",{"buildingId":str(b["kind"]),"fieldId":str(b["field"])}),row)
		upgrade.disabled = int(b["level"]) < 1 or int(b["target"]) > int(b["level"]) or int(b["level"]) >= int(bdef["maxLevel"])
		if str(b.get("field","")) == "" and int(b["level"]) > 0:
			_button(tx("Move here (EUR 45)","Mover aqui (45 EUR)"),_ask.bind("relocateBuilding",{"buildingId":str(b["id"]),"slot":int(slot_select.get_item_metadata(slot_select.selected))}),right_body)

func _panel_animals() -> void:
	_caption(right_body,tx("Animal care","Cuidado de animales"),tx("Feed and water influence welfare and produce","Pienso y agua afectan al bienestar y la produccion"))
	_line(right_body,tx("Stored feed: ","Pienso: ") + str(snappedf(farm.stock("feed"),0.1)) + " kg",17,ACCENT)
	var animals: Dictionary = farm.content["animals"]
	var ids: Array = animals.keys()
	var labels: Array = []
	for id in ids:
		labels.append(farm.n(animals[id]))
	var animal: OptionButton = _select(right_body,ids,labels)
	var row: HBoxContainer = _hbox(right_body)
	_line(row,tx("Number","Cantidad"),13)
	var count: SpinBox = _spin(row,1,1,20,1)
	_button(tx("Buy animals","Comprar animales"),func():_ask("buyAnimal",{"animalId":str(animal.get_item_metadata(animal.selected)),"count":int(count.value)}),right_body,true)
	_line(right_body,tx("Animals need their appropriate completed housing. Mixed species share housing space.","Cada especie necesita su alojamiento. Las especies compartidas suman ocupacion."),13,MUTED)
	var feed_row: HBoxContainer = _hbox(right_body)
	_line(feed_row,tx("Buy feed kg","Comprar pienso kg"),13)
	var feed: SpinBox = _spin(feed_row,40,1,400,5)
	_button(tx("Buy feed","Comprar pienso"),func():_ask("buySupply",{"goodId":"feed","kg":feed.value}),right_body)
	_caption(right_body,tx("Livestock on your farm","Ganado en tu finca"))
	if farm.state["animals"].is_empty():
		_line(right_body,tx("No animals yet. Build a home before buying them.","Aun no hay animales. Construye su hogar primero."),13,MUTED)
	for i in range(farm.state["animals"].size()):
		var a: Dictionary = farm.state["animals"][i]
		_line(right_body,farm.n(animals[str(a["kind"])]) + " x" + str(a["count"]) + " · "+tx("welfare ","bienestar ") + str(int(float(a["condition"])*100)) + "%",14)
		_line(right_body,tx("Health ","Salud ")+str(int(float(a["health"])*100))+"%  ·  "+tx("Nutrition ","Nutricion ")+str(int(float(a["nutrition"])*100))+"%  ·  "+tx("Age ","Edad ")+str(a["age_days"])+tx(" days"," dias"),13,ACCENT if float(a["health"])>=0.7 else DANGER)
		_line(right_body,tx("Feeding plan: ","Plan de alimentacion: ")+(tx("balanced (10% extra feed)","equilibrado (+10% de pienso)") if str(a["feeding"])=="balanced" else tx("standard","normal")),12,MUTED)
		var routine: String = Visual.animal_behavior(a,int(farm.state["time"]["hour"]),i,0.0)
		var status_en: Dictionary = {"sleeping":"Sleeping","resting":"Resting","grazing":"Grazing","drinking":"Drinking","walking":"Exploring paddock","unwell":"Needs care"}
		var status_es: Dictionary = {"sleeping":"Durmiendo","resting":"Descansando","grazing":"Pastando","drinking":"Bebiendo","walking":"Paseando por corral","unwell":"Necesita cuidados"}
		_line(right_body,tx("Current routine: ","Actividad actual: ")+str((status_es if language=="es" else status_en).get(routine,routine)),13,MUTED)
		_button(tx("Care for this group (EUR 9)","Cuidar grupo (9 EUR)"),_ask.bind("animalCare",{"animalId":str(a["id"])}),right_body)
		var actions: HBoxContainer = _hbox(right_body)
		_button(tx("Vet visit","Veterinario"),_ask.bind("vetVisit",{"animalId":str(a["id"])}),actions)
		_button(tx("Plan breeding","Criar"),_ask.bind("breedAnimal",{"animalId":str(a["id"])}),actions)
		var change_to: String = "standard" if str(a["feeding"])=="balanced" else "balanced"
		_button(tx("Switch feed plan","Cambiar alimentacion"),_direct.bind("feedingPlan",{"animalId":str(a["id"]),"mode":change_to}),right_body)
		if int(a.get("pregnancy_due",0))>int(farm.state["time"]["total"]):
			_line(right_body,tx("Expected newborn in ","Nueva cria prevista en ")+str(int(ceil(float(int(a["pregnancy_due"])-int(farm.state["time"]["total"]))/24.0)))+tx(" days"," dias"),13,ACCENT)
	_line(right_body,tx("Animal goods: eggs, milk, wool, fiber; apiaries make honey.","Productos: huevos, leche, lana, fibra y miel."),13,MUTED)

func _panel_processing() -> void:
	_caption(right_body,tx("Processing workshop","Taller de elaboracion"),tx("Turn perishable harvests into higher-value products","Transforma cosechas en productos mas valiosos"))
	for id in FarmScript.RECIPES.keys():
		var rec: Dictionary = FarmScript.RECIPES[id]
		var required: String = str(rec["building"])
		_line(right_body,str(id).capitalize() + "   " + str(rec["input"]) + " -> " + str(rec["output"]),17,ACCENT)
		_line(right_body,tx("Requires ","Necesita ") + required + "  /  " + str(rec["hours"]) + "h  /  x" + str(rec["ratio"]),12,MUTED)
		_line(right_body,tx("Available: ","Disponible: ") + str(snappedf(farm.stock(str(rec["input"])),0.1)) + " kg")
		var row: HBoxContainer = _hbox(right_body)
		var amount: SpinBox = _spin(row,20,1,500,5)
		var button: Button = _button(tx("Start job","Elaborar"),_process_batch.bind(str(id),amount),row)
		button.disabled = not farm.ready(required)
	var queue: Array = farm.state["processing"]
	_caption(right_body,tx("Jobs in progress","Trabajos en curso"))
	if queue.is_empty():
		_line(right_body,tx("No active production jobs","No hay trabajos pendientes"),13,MUTED)
	for job in queue:
		_line(right_body,str(job["recipe"]) + " " + str(snappedf(float(job["input_kg"]),0.1)) + " kg   " + str(maxi(0,int(job["finish"])-int(farm.state["time"]["total"]))) + " h",13)

func _process_batch(recipe: String, amount: SpinBox) -> void:
	_ask("process",{"recipeId":recipe,"kg":amount.value})

func _panel_market() -> void:
	_caption(right_body,tx("Valley market","Mercado del valle"),tx("Prices vary. Holding stock risks spoilage.","Los precios cambian y los productos pueden estropearse."))
	_button(tx("Visit the market building","Visitar el mercado"),_enter_building.bind("market"),right_body)
	_line(right_body,tx("Cash: EUR ","Dinero: EUR ") + str(farm.state["economy"]["cash"]),17,ACCENT)
	_line(right_body,tx("Storage: ","Almacen: ") + str(snappedf(farm.stored(),0.1)) + "/" + str(farm.storage_capacity()) + " kg")
	_caption(right_body,tx("Sell stored products","Vender productos almacenados"))
	for id in farm.content["goods"].keys():
		var kg: float = farm.stock(str(id))
		if kg < 0.1:
			continue
		var good_name: String = farm.n(farm.content["goods"][id])
		var row: HBoxContainer = _hbox(right_body)
		_line(row,good_name + " " + str(snappedf(kg,0.1)) + "kg",13)
		_line(row,"EUR " + str(farm.market_price(str(id))) + "/kg",12,MUTED)
		_button(tx("Sell 10","Vender 10"),_sell_quick.bind(str(id)),row)
		if farm.premium_stock(str(id)) > 0.01:
			_line(right_body,tx("Premium stock: ","Stock premium: ")+str(snappedf(farm.premium_stock(str(id)),0.1))+tx(" kg · sold first with a quality bonus"," kg · se vende primero con prima de calidad"),12,ACCENT)
	var water_row: HBoxContainer = _hbox(right_body)
	_line(water_row,tx("Deliver water m3","Comprar agua m3"),13)
	var water: SpinBox = _spin(water_row,100,1,1500,10)
	_button(tx("Purchase water","Comprar agua"),func():_ask("buyWater",{"m3":water.value}),right_body)
	_caption(right_body,tx("Limited-time visitor offers","Ofertas temporales"))
	for o in farm.state["market"]["offers"]:
		if o["status"] != "open":
			continue
		_line(right_body,str(o["npc"]).capitalize() + ": " + str(o["kg"]) + "kg " + str(o["good"]) + "  EUR " + str(o["price"]) + "/kg",13)
		var row: HBoxContainer = _hbox(right_body)
		_button(tx("Accept","Aceptar"),_ask.bind("offer",{"offerId":str(o["id"]),"accept":true}),row,true)
		_button(tx("Decline","Rechazar"),_direct.bind("offer",{"offerId":str(o["id"]),"accept":false}),row)
	_caption(right_body,tx("Delivery contracts","Contratos de entrega"))
	for contract in farm.state["market"]["contracts"]:
		if contract["status"] != "open" and contract["status"] != "active":
			continue
		_line(right_body,str(contract["kg"]) + " kg " + str(contract["good"]) + "  EUR " + str(contract["payout"]) + "  " + str(contract["status"]),13)
		if contract["status"] == "open":
			_button(tx("Accept contract","Aceptar contrato"),_ask.bind("contractAccept",{"contractId":str(contract["id"])}),right_body)
		else:
			_button(tx("Deliver complete order","Entregar pedido completo"),_ask.bind("contractDeliver",{"contractId":str(contract["id"])}),right_body)
	_button(tx("Enter seasonal festival (10 kg produce)","Participar en feria (10 kg)"),_ask.bind("festivalEnter",{}),right_body)

func _sell_quick(id: String) -> void:
	_ask("sell",{"goodId":id,"kg":minf(10.0,farm.stock(id))})

func _panel_neighbours() -> void:
	_caption(right_body,tx("Life in the village","Vida en el pueblo"),tx("Ten neighbours with daily routines, advice and community favours.","Diez vecinos con rutinas, consejos y favores."))
	var npcs: Dictionary = farm.content["npcs"]
	var ids: Array = npcs.keys()
	var labels: Array = []
	for id in ids:
		labels.append(farm.n(npcs[id]))
	var pick: OptionButton = _select(right_body,ids,labels)
	for i in range(ids.size()):
		if ids[i] == selected_npc:
			pick.select(i)
	pick.item_selected.connect(_choose_npc.bind(ids))
	var info: Dictionary = npcs[selected_npc]
	_line(right_body,farm.n(info),20,ACCENT)
	_line(right_body,farm.n(info,"role"),13,MUTED)
	var now_day: int = int(farm.state["time"]["day"])
	var now_hour: int = int(farm.state["time"]["hour"])
	var npc_region_id: String = Country54.npc_region(selected_npc,now_day,now_hour)
	_line(right_body,tx("Today's location: ","Ubicacion actual: ") + farm.n(FarmScript.REGIONS.get(npc_region_id,FarmScript.REGIONS["village"])),13,ACCENT)
	_button(tx("Find villagers on the valley map","Buscar vecinos en el valle"),_change_tab.bind("Countryside54"),right_body)
	_line(right_body,tx("Ask them about:","Preguntale por:"),14)
	for pair in [["weather",tx("Today's weather","El tiempo")],["soil",tx("The condition of your land","Estado del terreno")],["pests",tx("Pests and useful insects","Plagas y auxiliares")],["market",tx("Market prices","Precios de mercado")],["garden",tx("Their neighbouring garden","Su huerto")],["wildlife",tx("Wildlife and venom","Fauna y veneno")],["favours",tx("Neighbour favours","Favores vecinales")],["hello",tx("Say hello","Saludar")]]:
		_button(str(pair[1]),_talk_to.bind(selected_npc,str(pair[0])),right_body)
	_line(right_body,tx("Conversations give advice without changing resources. Helping a neighbour is a separate paid choice.","Las charlas no gastan recursos. Ayudar a un vecino es una decision aparte."),12,MUTED)
	_line(right_body,tx("Favours: ","Favores: ") + str(farm.state["neighbours"]["favours"].get(selected_npc,0)) + "  ·  " + tx("Trust: ","Confianza: ") + str(farm.npc_trust(selected_npc)) + "/10",14,ACCENT)
	if farm.npc_trust(selected_npc) >= 4:
		_line(right_body,tx("Trusted neighbour · shared expertise can help your farm.","Vecino de confianza · su experiencia puede ayudar a tu finca."),12,ACCENT)
	_button(tx("Ask about our relationship","Preguntar por nuestra relación"),_talk_to.bind(selected_npc,"relationship"),right_body)
	_button(tx("See village storylines","Ver historias del pueblo"),_change_tab.bind("Stories"),right_body)
	_button(tx("Help neighbour (EUR 24)","Ayudar a vecino (24 EUR)"),_ask.bind("helpNeighbour",{"npcId":selected_npc}),right_body)

func _show_neighbour(id: String) -> void:
	selected_npc = id
	var npc: Dictionary = farm.content["npcs"].get(id,{})
	if npc.is_empty():
		return
	_close_modal()
	var body: VBoxContainer = _modal_body(farm.n(npc))
	if body == null:
		return
	_line(body,farm.n(npc,"role"),14,MUTED)
	_line(body,tx("Choose a topic","Elige un tema"),16)
	for pair in [["weather",tx("Weather","Tiempo")],["soil",tx("Soil","Suelo")],["pests",tx("Pests","Plagas")],["market",tx("Prices","Precios")],["garden",tx("The garden","El huerto")],["wildlife",tx("Wildlife","Fauna")],["favours",tx("Favours","Favores")],["relationship",tx("Our relationship","Nuestra relación")]]:
		_button(str(pair[1]),_talk_to.bind(id,str(pair[0])),body)
	_button(tx("Goodbye","Adios"),_close_modal,body,true)

func _talk_to(id: String, topic: String) -> void:
	_notify(farm.talk(id,topic))

func _level_progress(parent: Node) -> void:
	var player: Dictionary = farm.state["player"]
	var current_xp: int = int(player["xp"]) % 220
	_line(parent,tx("FARMER LEVEL ","NIVEL AGRICULTOR ") + str(player["level"]) + "  -  " + str(current_xp) + "/220 XP  |  " + str(farm.available_points()) + tx(" points"," puntos"),14,ACCENT)
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0,14)
	bar.min_value = 0.0
	bar.max_value = 220.0
	bar.value = float(current_xp)
	bar.add_theme_stylebox_override("background",_style(Color("#dce6d7"),8))
	bar.add_theme_stylebox_override("fill",_style(Color("#66aa76"),8))
	parent.add_child(bar)

func _resource_row(parent: Node, id: String, quantity: float, description: String = "") -> void:
	var row: HBoxContainer = _hbox(parent,10)
	var path: String = "res://assets/icon_" + id + ".png"
	if ResourceLoader.exists(path):
		var icon_view: TextureRect = TextureRect.new()
		icon_view.texture = load(path)
		icon_view.custom_minimum_size = Vector2(43,43)
		icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon_view)
	_line(row,farm.n(farm.content["goods"][id]) + ": " + str(snappedf(quantity,0.1)) + " kg" + ("  " + description if description != "" else ""),14)

func _panel_resources() -> void:
	_caption(right_body,tx("Valley resources and garden","Recursos del valle y jardin"),tx("Bring natural materials home, recycle them, and build the farm you want.","Recoge materiales, reciclalos y personaliza la finca."))
	_level_progress(right_body)
	_line(right_body,tx("Warehouse: ","Almacen: ") + str(snappedf(farm.stored(),0.1)) + " / " + str(farm.storage_capacity()) + " kg",14,MUTED)
	_caption(right_body,tx("Stored materials","Materiales disponibles"))
	for id in ["timber","stone","clay","wildflowers","reeds","compost","manure"]:
		_resource_row(right_body,id,farm.stock(id))
	_caption(right_body,tx("Foraged and wild goods","Recolecta silvestre"),tx("Travel and explore to bring back more than crops.","Viaja y explora para traer mas que cultivos."))
	for id in ["herbs","berries","mushrooms","honey","lavender_oil"]:
		_resource_row(right_body,id,farm.stock(id))
	_caption(right_body,tx("Sustainable gathering","Recogida sostenible"),tx("One resource visit per region each game day. Gathering uses time, stamina, storage and some money.","Una visita de recursos por zona y dia. Gastas tiempo, energia, almacen y dinero."))
	for id in FarmScript.MATERIAL_SITES.keys():
		var site: Dictionary = FarmScript.MATERIAL_SITES[id]
		var taken: bool = int(farm.state["resources"]["gathered_today"].get(id,-1)) == int(farm.state["time"]["day"])
		var found: String = str(site["good"])
		var name: String = farm.n(FarmScript.REGIONS[id])
		_resource_row(right_body,found,float(site["kg"]),tx("possible","posibles"))
		var button: Button = _button(name + "   " + str(site["hours"]) + "h / EUR " + str(site["fee"]) + (tx("  (visited)","  (visitado)") if taken else ""),_ask.bind("gatherMaterials",{"regionId":id}),right_body)
		button.disabled = taken
	_caption(right_body,tx("Recycling organic matter","Reciclar materia organica"))
	_line(right_body,tx("8 kg manure + 2 kg wildflowers + EUR 7 = 7 kg compost.","8 kg estiercol + 2 kg flores + 7 EUR = 7 kg compost."),13,MUTED)
	_button(tx("Make compost","Producir compost"),_ask.bind("makeCompost",{}),right_body)
	_button(tx("Use compost on selected field","Aplicar compost en parcela"),_ask.bind("spreadCompost",{"fieldId":selected_field}),right_body)
	_button(tx("Open interactive garden studio","Abrir estudio de jardin interactivo"),_change_tab.bind("GardenStudio57"),right_body,true)
	_caption(right_body,tx("Build a personal garden","Decora tu jardin"),tx("Choose a design and a free slot. Materials are consumed when construction starts.","Elige un diseno y un lugar libre. Los materiales se consumen al iniciar."))
	var designs: Array = FarmScript.DECORATIONS.keys()
	var names: Array = []
	for id in designs:
		names.append(farm.n(FarmScript.DECORATIONS[id]))
	var picker: OptionButton = _select(right_body,designs,names)
	var slots: Array = []
	var labels: Array = []
	for i in range(24):
		slots.append(i)
		var occupied: bool = false
		for decoration in farm.state["decorations"]:
			if int(decoration["slot"]) == i:
				occupied = true
				break
		labels.append(tx("Garden position ","Posicion jardin ") + str(i+1) + (tx(" - occupied"," - ocupada") if occupied else ""))
	var slot_picker: OptionButton = _select(right_body,slots,labels)
	var details: Label = _line(right_body,"",13,MUTED)
	var update: Callable = func():
		var design: Dictionary = FarmScript.DECORATIONS[str(picker.get_item_metadata(picker.selected))]
		var materials: Array = []
		for id in design["materials"].keys():
			materials.append(str(design["materials"][id]) + " kg " + str(id))
		details.text = ", ".join(PackedStringArray(materials)) + "   |   EUR " + str(design["fee"]) + "  / " + str(design["hours"]) + "h  /  " + tx("level ","nivel ") + str(design["level"])
	picker.item_selected.connect(func(_i):update.call())
	update.call()
	_button(tx("Craft selected decoration","Fabricar decoracion"),func():_ask("craftDecoration",{"decorationId":str(picker.get_item_metadata(picker.selected)),"slot":int(slot_picker.get_item_metadata(slot_picker.selected))}),right_body,true)
	for decoration in farm.state["decorations"]:
		var left: int = maxi(0,int(decoration["ready_at"])-int(farm.state["time"]["total"]))
		_line(right_body,farm.n(FarmScript.DECORATIONS[str(decoration["kind"])]) + "  /  " + tx("slot ","posicion ") + str(int(decoration["slot"])+1) + (tx(" completed"," terminado") if bool(decoration["completed"]) else "  -  " + str(left) + "h"),14)

func _panel_stories() -> void:
	_caption(right_body,tx("Village stories & consequences","Historias del pueblo y consecuencias"),
		tx("Your choices affect relationships and bring follow-up events over several days.","Tus decisiones cambian las relaciones y crean nuevos sucesos días después."))
	var active: Dictionary = farm.state["events"]["active"]
	if not active.is_empty():
		var title: String = Chains.title(str(active["id"]),language) if str(active.get("arc","")) != "" else Decisions.title(str(active["id"]),language)
		_line(right_body,tx("DECISION WAITING: ","DECISIÓN PENDIENTE: ") + title,15,DANGER)
		_button(tx("Make a decision","Tomar una decisión"),_show_decision_board,right_body,true)
	_caption(right_body,tx("Storylines in progress","Historias en curso"))
	var stories: Array = farm.story_branches()
	if stories.is_empty():
		_line(right_body,tx("Your first village storyline will begin after an event involving Mateo, Inés, Lila, Bruno, Rosa or Clara.",
			"La primera historia aparecerá tras un evento con Mateo, Inés, Lila, Bruno, Rosa o Clara."),13,MUTED)
	for arc in stories:
		var status: String = str(arc["status"])
		var status_title: String = tx("Completed","Terminada") if status == "completed" else (tx("Decision waiting","Esperando decisión") if status == "active" else tx("Developing","En desarrollo"))
		var panel: PanelContainer = PanelContainer.new()
		panel.add_theme_stylebox_override("panel",_style(Color("#edf5e9"),12,Color("#b3ccb6")))
		right_body.add_child(panel)
		var body: VBoxContainer = _vbox(panel,4)
		_line(body,str(arc["name"]),17,ACCENT)
		_line(body,status_title + "  ·  " + farm.n(farm.content["npcs"][str(arc["npc"])]),13,MUTED)
		_line(body,tx("Last choice: ","Última decisión: ") + str(arc["last_choice"]).replace("_"," "),12)
	_caption(right_body,tx("Invite a neighbour to discuss a new project","Invitar a un vecino a proponer un proyecto"),
		tx("You can proactively begin an untouched storyline for €20. Allow three game days between invitations.",
		"Puedes iniciar una historia por 20 €. Deben pasar tres días de juego entre invitaciones."))
	for arc_id in Chains.catalog().get("arcs",{}).keys():
		if farm.state["decisions"]["branches"].has(str(arc_id)):
			continue
		var arc_data: Dictionary = Chains.arc(str(arc_id))
		var invite: Dictionary = farm.quote("inviteStory",{"arcId":str(arc_id)})
		var visit: Button = _button(Chains.arc_name(str(arc_id),language) + " · " + farm.n(farm.content["npcs"][str(arc_data["npc"])]) + " · €20",
			_ask.bind("inviteStory",{"arcId":str(arc_id)}),right_body)
		visit.disabled = not bool(invite.get("ok",false))
		if visit.disabled:
			visit.tooltip_text = str(invite.get("error",""))
	_caption(right_body,tx("Follow-up visits","Próximas visitas"))
	var jobs: Array = farm.pending_story_events()
	if jobs.is_empty():
		_line(right_body,tx("There are no scheduled follow-up visits.","No hay visitas de seguimiento programadas."),13,MUTED)
	for job in jobs:
		_line(right_body,Chains.title(str(job["stage"]),language) + "  ·  " + str(job["hours"]) + " h",14)
	_caption(right_body,tx("Your relationships","Tus relaciones"),tx("Trust grows through help and significant choices. Some trusted neighbours provide modest lasting bonuses.",
		"La confianza mejora con favores y decisiones importantes. Algunas amistades dan pequeñas ventajas permanentes."))
	for id in ["mateo","ines","lila","bruno","rosa","clara"]:
		var trust: int = farm.npc_trust(id)
		_line(right_body,farm.n(farm.content["npcs"][id]) + "  ·  " + str(trust) + "/10",14,ACCENT if trust >= 4 else MUTED)
	_caption(right_body,tx("What happens next?","¿Qué ocurrirá después?"))
	_line(right_body,tx("A storyline starts after a genuine valley event. Its consequences emerge after simulated time passes; the clock pauses for each new decision.",
		"Las historias empiezan tras un evento real. Las consecuencias llegan tras varias horas de juego y el reloj se detiene en cada decisión."),13,MUTED)
	_button(tx("Read the decision diary","Leer el diario de decisiones"),_change_tab.bind("Journal"),right_body)

func _panel_character() -> void:
	var player: Dictionary = farm.state["player"]
	_caption(right_body,tx("Farmer and experience","Agricultor y experiencia"),tx("Learning takes time and money; perks have lasting effects.","Aprender requiere tiempo y dinero; las habilidades se mantienen."))
	var portrait: Variant = PortraitScript.new()
	portrait.custom_minimum_size = Vector2(180,165)
	right_body.add_child(portrait)
	portrait.call("set_avatar",player)
	_line(right_body,str(player["name"]) + "  -  Lv " + str(player["level"]) + "  XP " + str(player["xp"]),19,ACCENT)
	_level_progress(right_body)
	_line(right_body,tx("Talent points available: ","Puntos de habilidad: ") + str(farm.available_points()),16)
	_caption(right_body,tx("Skill mastery tracks","Especializacion por disciplinas"),tx("Every useful action builds practice in its field. Training and talents offer additional bonuses.","Cada accion util aumenta tu experiencia y tu especializacion."))
	for track in FarmScript.MASTERY_TRACKS:
		var mastery_xp: int = int(farm.state["progression"]["tracks"].get(track,0))
		_line(right_body,track.capitalize() + "   L" + str(farm.mastery_level(track)) + "  /  " + str(mastery_xp) + " XP",14)
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(0,10)
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = 140.0
		bar.value = float(mastery_xp % 140)
		bar.add_theme_stylebox_override("background",_style(Color("#e8e9db"),6))
		bar.add_theme_stylebox_override("fill",_style(Color("#d8b66c"),6))
		right_body.add_child(bar)
	_line(right_body,tx("Masteries improve relevant farm operations, up to a 12% efficiency bonus.","La especializacion mejora las tareas asociadas, hasta un 12% de eficiencia."),12,MUTED)
	var bg: Dictionary = farm.content["backgrounds"].get(str(player["background"]),{})
	_line(right_body,farm.n(bg,"perk"),13,MUTED)
	_caption(right_body,tx("Eight training courses","Ocho cursos"))
	for id in farm.content["courses"].keys():
		var entry: Dictionary = farm.content["courses"][id]
		_line(right_body,farm.n(entry) + "  EUR " + str(entry["cost"]) + "  / " + str(entry["hours"]) + "h",14)
		_line(right_body,farm.n(entry,"description"),12,MUTED)
		var state_desc: String = ""
		if farm.has_course(str(id)):
			state_desc = tx("Completed","Terminado")
		else:
			for job in player["training"]:
				if str(job["id"]) == str(id):
					state_desc = tx("Studying","Estudiando")
		var button: Button = _button(state_desc if state_desc != "" else tx("Enroll","Matricular"),_ask.bind("enrollCourse",{"courseId":str(id)}),right_body)
		button.disabled = state_desc != ""
	_caption(right_body,tx("25 permanent talents","25 habilidades permanentes"),tx("Unlock prerequisites before advanced talents.","Desbloquea requisitos para acceder a talentos avanzados."))
	for branch in ["water","ecology","craft","husbandry"]:
		_line(right_body,branch.capitalize(),18,ACCENT)
		for id in farm.content["talents"].keys():
			var talent: Dictionary = farm.content["talents"][id]
			if str(talent["branch"]) != branch:
				continue
			_line(right_body,farm.n(talent),14)
			_line(right_body,farm.n(talent,"description"),12,MUTED)
			var lock: String = ""
			if talent.get("requires") != null and str(talent["requires"]) != "":
				lock = "Needs " + str(talent["requires"])
			if talent.get("course") != null and str(talent["course"]) != "":
				lock += " | course " + str(talent["course"])
			if lock != "":
				_line(right_body,lock,11,MUTED)
			var learned: bool = farm.has_talent(str(id))
			var button: Button = _button(tx("Learned","Aprendido") if learned else tx("Learn talent","Aprender talento"),_ask.bind("learnTalent",{"talentId":str(id)}),right_body)
			button.disabled = learned

	_caption(right_body,tx("Farm wardrobe","Vestuario de la finca"),tx("Open the 5.3 appearance editor to change clothes and hairstyle, save outfits and preview your farmer.","Abre el editor 5.3 para personalizar la ropa y el peinado y guardar conjuntos."))
	_button(tx("Customize farmer","Personalizar agricultor"),_change_tab.bind("Wardrobe53"),right_body,true)

func _panel_wardrobe53() -> void:
	var player: Dictionary = farm.state["player"]
	_caption(right_body,tx("Your farmer, your story","Tu agricultor, tu historia"),tx("Live preview. These choices are visual only; they do not change farming bonuses.","Vista previa en directo. Son cambios visuales; no modifican las ventajas de la finca."))
	var portrait: Control = PortraitScript.new()
	portrait.custom_minimum_size = Vector2(220,220)
	right_body.add_child(portrait)
	_line(right_body,str(player["name"])+"  ·  "+tx("Level ","Nivel ")+str(player["level"]),18,ACCENT)
	var editor: Dictionary = _build_avatar_editor53(right_body,portrait,player,farm.state)
	_button(tx("Apply this appearance","Aplicar este aspecto"),func():_direct("setFarmerLook",_read_avatar_editor53(editor)),right_body,true)
	_caption(right_body,tx("Three saved outfits","Tres conjuntos guardados"),tx("Save the current preview in a slot, then switch back instantly at any time.","Guarda la vista previa y vuelve a equiparla cuando quieras."))
	var presets: Array = farm.state["wardrobe53"]["presets"]
	for i in range(3):
		var row: HBoxContainer = _hbox(right_body,6)
		var saved: Dictionary = presets[i]
		var title: String = tx("Outfit ","Conjunto ") + str(i+1) + (tx(" · empty"," · vacio") if saved.is_empty() else " · " + Style53.display_name("hair",str(saved["hair"]),language=="es"))
		var title_label: Label = _line(row,title,13,MUTED if saved.is_empty() else ACCENT)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_button(tx("Save preview","Guardar"),_save_wardrobe_preview53.bind(i,editor),row)
		if not saved.is_empty():
			_button(tx("Wear","Equipar"),_direct.bind("applyOutfitPreset",{"slot":i}),row)
			_button(tx("Clear","Vaciar"),_direct.bind("clearOutfitPreset",{"slot":i}),row)
	_caption(right_body,tx("Earn unique cosmetics","Consigue cosmeticos exclusivos"))
	var certificate_found: bool = farm.state["world50"]["certifications"].size() > 0
	var festival_found: bool = farm.state["world50"]["festival_history"].size() > 0
	_line(right_body,("✓ " if certificate_found else "○ ") + tx("Ranger hat: complete an advanced certification","Sombrero explorador: completa una certificacion"),13,ACCENT if certificate_found else MUTED)
	_line(right_body,("✓ " if festival_found else "○ ") + tx("Festival laurel: enter a seasonal festival","Laurel festivo: participa en una fiesta estacional"),13,ACCENT if festival_found else MUTED)


func _panel_story() -> void:
	_caption(right_body,tx("Your story & lessons","Tu historia y lecciones"))
	var story: Dictionary = farm.state["story"]
	_line(right_body,tx("Story chapter ","Capitulo ") + str(story["chapter"]) + "/4",18,ACCENT)
	var id: int = int(story["chapter"]) - 1
	if id < farm.content["story"].size():
		var chapter: Dictionary = farm.content["story"][id]
		_line(right_body,farm.n(chapter,"title"),17)
		_line(right_body,farm.n(chapter,"text"),13,MUTED)
	elif story["completed"]:
		_line(right_body,tx("Your farm has found its place in the valley.","Tu finca ya forma parte del valle."),14)
	_caption(right_body,tx("Interactive tutorial","Tutorial interactivo"))
	var step: int = int(story["tutorial"])
	if step < FarmScript.TUTORIAL.size():
		_line(right_body,"Step " + str(step+1) + " / " + str(FarmScript.TUTORIAL.size()),15,ACCENT)
		_line(right_body,farm.n(FarmScript.TUTORIAL[step],""),14)
		_button(tx("Skip this lesson","Saltar esta leccion"),_direct.bind("tutorial",{"skip":true}),right_body)
	else:
		_line(right_body,tx("All tutorial lessons finished.","Has terminado todas las lecciones."),14)
	_caption(right_body,tx("Quests and rewards","Misiones y recompensas"))
	for id_quest in FarmScript.QUESTS.keys():
		var q: Dictionary = FarmScript.QUESTS[id_quest]
		var progress: float = float(farm.state["stats"].get(q["stat"],0.0))
		_line(right_body,farm.n(q) + "  " + str(int(progress)) + "/" + str(int(q["target"])),14)
		var claimed: bool = story["quests"].has(id_quest)
		var button: Button = _button(tx("Claimed","Cobrado") if claimed else tx("Claim reward","Cobrar recompensa"),_ask.bind("claimQuest",{"questId":str(id_quest)}),right_body)
		button.disabled = claimed or progress < float(q["target"])
	_caption(right_body,tx("Achievements","Logros"))
	_line(right_body,", ".join(PackedStringArray(story["achievements"])) if not story["achievements"].is_empty() else tx("Discover achievements by playing.","Descubre logros al jugar."),13,MUTED)

func _panel_journal() -> void:
	_caption(right_body,tx("Farm diary","Diario de la finca"))
	_caption(right_body,tx("Decision history","Historial de decisiones"))
	var decision_history: Array = farm.state["decisions"]["history"]
	for index in range(decision_history.size()-1,maxi(-1,decision_history.size()-13),-1):
		var entry: Dictionary = decision_history[index]
		var branch_event: bool = not Chains.stage(str(entry["id"])).is_empty()
		var name: String = Chains.title(str(entry["id"]),language) if branch_event else Decisions.title(str(entry["id"]),language)
		var picked: String = str(entry["choice"])
		var option_list: Array = Chains.options(str(entry["id"]),language) if branch_event else Decisions.options(str(entry["id"]),language)
		for option in option_list:
			if str(option["id"]) == picked:
				picked = str(option["text"])
				break
		_line(right_body,name + ": " + picked,13,ACCENT)
		_line(right_body,"€ " + str(entry.get("cash_change",0)) + "  |  " + tx("Reputation ","Reputación ") + str(entry.get("reputation_change",0)),12,MUTED)
		if branch_event:
			var result_text: String = str(entry.get("result","certain"))
			var outcome: String = tx("Success","Éxito") if result_text == "success" else (tx("Setback","Revés") if result_text == "setback" else tx("Certain result","Resultado seguro"))
			_line(right_body,outcome + "  |  " + tx("Neighbour trust ","Confianza vecinal ") + str(entry.get("trust_change",0)) + "  |  " + tx("Water ","Agua ") + str(snappedf(float(entry.get("water_change",0.0)),0.1)) + " m³",12,MUTED)
	_caption(right_body,tx("Village relationships","Relaciones del pueblo"))
	var rapport: Array = farm.state["decisions"]["relationship_history"]
	for i in range(rapport.size()-1,maxi(-1,rapport.size()-9),-1):
		var line: Dictionary = rapport[i]
		_line(right_body,farm.n(farm.content["npcs"][str(line["npc"])]) + ": " + str(line["amount"]) + "  ·  " + tx("Trust ","Confianza ") + str(line["total"]),12,MUTED)
	_button(tx("Open village story board","Abrir historias del pueblo"),_change_tab.bind("Stories"),right_body)
	_caption(right_body,tx("Ongoing consequences","Consecuencias activas"))
	for effect in farm.active_effects():
		_line(right_body,_localized_effect(str(effect["id"])) + " · " + str(effect["hours"]) + " h",14,ACCENT)
	var logs: Array = farm.state["logs"]
	for i in range(logs.size() - 1, maxi(-1,logs.size()-30), -1):
		var entry: Dictionary = logs[i]
		_line(right_body,"[h" + str(entry["hour"]) + "]  " + str(entry["message"]),12,MUTED)
	_caption(right_body,tx("Recent transactions","Ultimos movimientos"))
	var ledger: Array = farm.state["economy"]["ledger"]
	for i in range(ledger.size() - 1, maxi(-1, ledger.size() - 13), -1):
		var entry: Dictionary = ledger[i]
		_line(right_body,str(entry["description"]) + "  EUR " + str(entry["amount"]),12)

func _panel_community50() -> void:
	_caption(right_body,tx("Neighbour journeys · 10 village stories","Historias vecinales · 10 relatos"),
		tx("Each neighbour has three chapters. Deliver real supplies and choose between sharing more or earning more; progress persists in saves.",
		"Cada vecino tiene tres capítulos. Entrega productos reales y elige entre compartir más o ganar más; el progreso queda guardado."))
	var chapters: Dictionary = farm.world_catalog.get("npc_chapters",{})
	var progress: Dictionary = farm.state["world50"]["npc_chapters"]
	var completed: int = 0
	for npc_id in chapters.keys():
		completed += int(progress.get(npc_id,0))
	_line(right_body,tx("Completed chapters: ","Capítulos completados: ")+str(completed)+" / 30",17,ACCENT)
	for npc_id in chapters.keys():
		var stage: int = int(progress.get(npc_id,0))
		var npc_title: String = farm.n(farm.content["npcs"][str(npc_id)])
		_caption(right_body,npc_title+"  ·  "+str(stage)+"/3")
		var chapter: Dictionary = farm.npc_chapter_info(str(npc_id))
		if chapter.is_empty():
			_line(right_body,tx("Story complete. Your neighbour remembers your help.","Historia terminada. Tu vecino recuerda tu ayuda."),13,ACCENT)
			continue
		_line(right_body,World50.localized(chapter["title"],language),15,ACCENT)
		_line(right_body,World50.localized(chapter["description"],language),13)
		var good: String = str(chapter["good"])
		var need: float = float(chapter["kg"])
		var owned: float = farm.stock(good)
		var goods_name: String = farm.n(farm.content["goods"][good])
		_line(right_body,tx("Deliver ","Entregar ")+str(need)+" kg " +goods_name+"  ·  "+tx("Available: ","Disponible: ")+str(snappedf(owned,0.1))+" kg",13,MUTED)
		var remaining: int = maxi(0,int(farm.state["world50"]["npc_next_hours"].get(npc_id,0))-int(farm.state["time"]["total"]))
		if remaining>0:
			_line(right_body,tx("Next chapter in ","Próximo capítulo en ")+str(remaining)+" h",12,MUTED)
		var enabled: bool = owned+0.00001 >= need and remaining == 0
		var row: HBoxContainer = _hbox(right_body)
		var share: Button = _button(tx("Share · more trust","Compartir · más confianza"),_ask.bind("completeNpcChapter",{"npcId":str(npc_id),"approach":"share"}),row)
		share.disabled = not enabled
		var trade: Button = _button(tx("Trade · more cash","Vender · más dinero"),_ask.bind("completeNpcChapter",{"npcId":str(npc_id),"approach":"trade"}),row)
		trade.disabled = not enabled
	_caption(right_body,tx("Latest neighbour exchanges","Últimas entregas vecinales"))
	var history: Array = farm.state["world50"]["npc_history"]
	if history.is_empty():
		_line(right_body,tx("Your first delivery will appear here.","Tu primera entrega aparecerá aquí."),13,MUTED)
	for index in range(history.size()-1,maxi(-1,history.size()-7),-1):
		var entry: Dictionary = history[index]
		_line(right_body,farm.n(farm.content["npcs"][str(entry["npc"])])+" · "+tx("chapter ","capítulo ")+str(entry["chapter"])+" · "+str(entry["kg"])+" kg "+str(entry["good"]),12,MUTED)

func _panel_festivals50() -> void:
	_caption(right_body,tx("Festivals & seasonal ambitions","Fiestas y objetivos de estación"),
		tx("A festival accepts one real exhibit on days 9–12 of each 12-day season. Once entered, you cannot repeat it that season.",
		"Cada fiesta admite una exposición real entre los días 9 y 12 de cada estación de 12 días. Solo puedes participar una vez por estación."))
	var season: int = int(farm.state["time"]["season"])
	var day: int = 1+(int(farm.state["time"]["day"])-1)%FarmScript.SEASON_DAYS
	var festival: Dictionary = farm.current_festival()
	_line(right_body,World50.localized(festival.get("name",{}),language)+"  ·  "+tx("season day ","día de estación ")+str(day)+"/12",18,ACCENT)
	_line(right_body,World50.localized(festival.get("theme",{}),language),13)
	var available: bool = farm.festival_available()
	if day < 9:
		_line(right_body,tx("Exhibition opens in ","La exposición comienza en ")+str(9-day)+tx(" days."," días."),13,MUTED)
	elif not available:
		_line(right_body,tx("You have already entered this festival.","Ya has participado en esta fiesta."),13,MUTED)
	for category in ["produce","artisan","community"]:
		var exhibit: Dictionary = festival.get("entries",{}).get(category,{})
		if exhibit.is_empty():
			continue
		var good: String = str(exhibit["good"])
		var quantity: float = float(exhibit["kg"])
		var title: String = World50.localized(farm.world_catalog.get("entry_labels",{}).get(category,{}),language)
		_line(right_body,title+"  ·  "+str(quantity)+" kg "+farm.n(farm.content["goods"][good])+"  ·  "+tx("in storage ","en almacén ")+str(snappedf(farm.stock(good),0.1)),14)
		var entry: Button = _button(tx("Enter exhibit · EUR 25","Participar · 25 EUR"),_ask.bind("festivalEnter",{"category":category}),right_body)
		entry.disabled = not available or farm.stock(good)+0.00001 < quantity or float(farm.state["economy"]["cash"]) < 25.0
	_caption(right_body,tx("Seasonal objective","Objetivo de la estación"))
	var objective: Dictionary = farm.season_goal_info()
	if not objective.is_empty():
		var current: float = farm.season_goal_progress()
		_line(right_body,World50.localized(objective["name"],language),17,ACCENT)
		_line(right_body,str(snappedf(current,0.1))+" / "+str(objective["target"])+"  ·  EUR "+str(objective["cash"])+" +"+str(objective["xp"])+" XP",13)
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size.y = 14
		bar.max_value = float(objective["target"])
		bar.value = minf(current,bar.max_value)
		bar.show_percentage = false
		right_body.add_child(bar)
		_line(right_body,tx("The season is evaluated automatically when the next one begins.","La estación se evalúa al empezar la siguiente."),12,MUTED)
	_caption(right_body,tx("Festival history","Historial de fiestas"))
	var history: Array = farm.state["world50"]["festival_history"]
	for index in range(history.size()-1,maxi(-1,history.size()-8),-1):
		var outcome: Dictionary = history[index]
		var rank: String = str(outcome["rank"])
		var label_rank: String = {"gold":tx("Gold","Oro"),"silver":tx("Silver","Plata"),"participant":tx("Participant","Participante")}.get(rank,rank)
		_line(right_body,tx("Season ","Estación ")+str(int(outcome["season_key"])+1)+"  ·  "+label_rank+"  ·  "+str(outcome["score"])+" pts  ·  EUR "+str(outcome["prize"]),13)
	_caption(right_body,tx("End-of-season reports","Balances de estación"))
	var reports: Array = farm.state["world50"]["season_results"]
	for index in range(reports.size()-1,maxi(-1,reports.size()-8),-1):
		var report: Dictionary = reports[index]
		_line(right_body,tx("Season ","Estación ")+str(int(report["season_key"])+1)+" · "+str(report["progress"])+"/"+str(report["target"])+" · "+(tx("Goal achieved","Objetivo conseguido") if report["completed"] else tx("Goal missed","Objetivo no alcanzado")),13)

func _panel_certifications50() -> void:
	_caption(right_body,tx("Professional qualifications","Acreditaciones profesionales"),
		tx("Advanced certificates require a completed course, real practical work, and mastery experience. Their benefits change the simulation.",
		"Las acreditaciones requieren un curso, trabajo práctico real y experiencia. Sus ventajas cambian la simulación."))
	for id in farm.world_catalog.get("certifications",{}).keys():
		var certificate: Dictionary = farm.world_catalog["certifications"][id]
		var acquired: bool = farm.has_certificate(str(id))
		_caption(right_body,World50.localized(certificate["name"],language)+("  ✓" if acquired else ""))
		_line(right_body,World50.localized(certificate["description"],language),13)
		var mastery: int = int(farm.state["progression"]["tracks"].get(str(certificate["track"]),0))
		var practical: float = float(farm.state["stats"].get(str(certificate["stat"]),0.0))
		var course: String = str(certificate["course"])
		_line(right_body,tx("Course ","Curso ")+course+"  ·  "+("✓" if farm.has_course(course) else tx("pending","pendiente")),13,MUTED)
		_line(right_body,tx("Practice XP ","Experiencia práctica ")+str(mastery)+"/"+str(certificate["xp"])+"  ·  "+str(snappedf(practical,0.1))+"/"+str(certificate["target"]),13,MUTED)
		var ready: bool = World50.certificate_ready(farm.world_catalog,farm.state["world50"],farm.state["stats"],farm.state["player"],farm.state["progression"],str(id))
		var qualify: Button = _button(tx("Earn qualification · EUR ","Obtener acreditación · ")+str(certificate["fee"]),_ask.bind("earnCertificate",{"certificateId":str(id)}),right_body)
		qualify.disabled = acquired or not ready or float(farm.state["economy"]["cash"]) < float(certificate["fee"])
		if acquired:
			qualify.text = tx("Qualified · benefit active","Acreditado · ventaja activa")
	_button(tx("Open courses & talents","Abrir cursos y talentos"),_change_tab.bind("Character"),right_body,true)

func _panel_options() -> void:
	_caption(right_body,tx("Settings & saves","Opciones y partidas"))
	_button(tx("Language: English / Español","Idioma: Español / English"),_toggle_game_language,right_body)
	_line(right_body,tx("Language can also be selected before starting the game.","También puedes elegir el idioma antes de comenzar."),13,MUTED)
	_caption(right_body,tx("Readability and accessibility","Legibilidad y accesibilidad"))
	_line(right_body,tx("Scale interface text and controls","Aumentar texto y controles"),14)
	var scale_values: Array = [1.0,1.15,1.3,1.5,1.65]
	var scales: OptionButton = _select(right_body,scale_values,["100%", "115%", "130%", "150%", "165%"])
	var size_index: int = 0
	for i in range(scale_values.size()):
		if absf(float(scale_values[i])-ui_scale) < absf(float(scale_values[size_index])-ui_scale):
			size_index = i
	scales.select(size_index)
	_button(tx("Apply interface size","Aplicar tamaño"),func():_set_ui_scale(float(scales.get_item_metadata(scales.selected))),right_body)
	var contrast: CheckBox = CheckBox.new()
	contrast.text = tx("High contrast controls","Controles de alto contraste")
	contrast.button_pressed = high_contrast
	contrast.toggled.connect(_set_high_contrast)
	right_body.add_child(contrast)
	for pair in [["motion",tx("Reduced motion (no cosmetic animation)","Movimiento reducido (sin animación decorativa)"),reduced_motion],["labels",tx("Always show field condition labels","Mostrar siempre etiquetas del estado del suelo"),visible_status_labels],["numbers",tx("Numeric map overlay labels (not color alone)","Valores numericos en el mapa (no solo color)"),overlay_numbers59]]:
		var option: CheckBox = CheckBox.new()
		option.text = str(pair[1])
		option.button_pressed = bool(pair[2])
		option.toggled.connect(_set_accessibility.bind(str(pair[0])))
		option.custom_minimum_size.y = Performance59.touch_target(ui_scale)
		right_body.add_child(option)
	_caption(right_body,tx("Graphics performance", "Rendimiento gráfico"),tx("Eco reduces animated detail and redraws; Balanced is the default; Quality is smoothest on fast devices.","Ahorro reduce detalles y repintados; Equilibrado es normal; Calidad ofrece mas fluidez."))
	var quality_ids: Array = ["eco","balanced","quality"]
	var quality_names: Array = [tx("Eco (battery saver)","Ahorro (bateria)"),tx("Balanced","Equilibrado"),tx("Quality","Calidad")]
	var quality: OptionButton = _select(right_body,quality_ids,quality_names)
	quality.select(maxi(0,quality_ids.find(performance_mode59)))
	_button(tx("Apply performance mode","Aplicar modo de rendimiento"),func():_set_performance59(str(quality.get_item_metadata(quality.selected))),right_body,true)
	var fps_toggle: CheckBox = CheckBox.new()
	fps_toggle.text = tx("Show live FPS counter", "Mostrar contador FPS")
	fps_toggle.button_pressed = show_fps59
	fps_toggle.toggled.connect(_toggle_fps59)
	fps_toggle.custom_minimum_size.y = Performance59.touch_target(ui_scale)
	right_body.add_child(fps_toggle)
	_line(right_body,tx("Touch controls: hold directional buttons to walk; drag the farm to pan, pinch to zoom.","Control tactil: mantener flechas para caminar; arrastrar el campo y pellizcar para ampliar."),13,MUTED)
	_caption(right_body,tx("Original ambient sound","Sonido ambiental original"))
	var sound: CheckBox = CheckBox.new()
	sound.text = tx("Seasonal ambience · birds, wind and water","Ambiente estacional · aves, viento y agua")
	sound.button_pressed = ambient_enabled
	sound.toggled.connect(_set_ambience)
	right_body.add_child(sound)
	var volumes: Array = [0.12,0.28,0.55,1.0]
	var volume_names: Array = [tx("Quiet","Bajo"),tx("Soft","Suave"),tx("Medium","Medio"),tx("Loud","Alto")]
	var volume_select: OptionButton = _select(right_body,volumes,volume_names)
	var index: int = 0
	for j in range(volumes.size()):
		if absf(float(volumes[j])-ambient_volume) < absf(float(volumes[index])-ambient_volume):
			index = j
	volume_select.select(index)
	_button(tx("Apply sound level","Aplicar volumen"),func():_set_ambience_volume(float(volume_select.get_item_metadata(volume_select.selected))),right_body)
	_caption(right_body,tx("Fieldwork 6.0 display", "Pantalla Fieldwork 6.0"))
	_button(tx("Switch to classic 2D map", "Cambiar al mapa 2D clásico") if use_25d else tx("Switch to isometric 2.5D", "Cambiar a isométrico 2.5D"),_toggle_perspective56,right_body,true)
	_line(right_body,tx("Isometric projection affects graphics and click coordinates only. Your farm, crops and save remain unchanged.", "La proyección isométrica solo afecta a gráficos y selección; cultivos y partida permanecen intactos."),13,MUTED)
	_button(tx("Open screen directory", "Abrir todas las pantallas"),_show_screen_picker,right_body)
	_button(tx("Show / hide sidebar", "Mostrar / ocultar menú lateral"),_toggle_sidebar,right_body)
	_line(right_body,tx("Farm map layers: growth, moisture, soil health and pests. Change the map layer above the farm.","Capas del mapa: crecimiento, humedad, salud del suelo y plagas. Cambia la capa sobre la finca."),13,MUTED)
	_caption(right_body,tx("Living world graphics","Gráficos del mundo vivo"),tx("Presentation settings change only visuals, never the farm simulation.","Las opciones visuales no cambian la simulación de la finca."))
	for pair in [["weather",tx("Weather, fog, seasonal particles and night lighting","Clima, niebla, particulas y luz nocturna"),visual_weather],["growth",tx("Growth stage labels on plants","Etiquetas de crecimiento en cultivos"),visual_growth_labels],["animals",tx("Animal behaviour labels","Etiquetas de comportamiento animal"),visual_animal_moods]]:
		var toggle: CheckBox = CheckBox.new()
		toggle.text = str(pair[1])
		toggle.button_pressed = bool(pair[2])
		toggle.toggled.connect(_set_visual_option.bind(str(pair[0])))
		right_body.add_child(toggle)
	_button(tx("Living world scenic view","Vista panoramica de la finca viva"),_show_panorama,right_body)
	_button(tx("Save now (protected)","Guardar ahora (protegido)"),_save_notice,right_body,true)
	_button(tx("Load latest local save","Cargar partida local"),_request_load_latest,right_body)
	_caption(right_body,tx("Manual saves · three slots","Partidas manuales · tres espacios"),tx("Every overwrite keeps rolling backups; loading a slot replaces the current farm only after confirmation.","Cada sustitución conserva copias; cargar una partida requiere confirmación."))
	for slot in range(1,FarmScript.SAVE_SLOT_COUNT+1):
		var data: Dictionary = farm.slot_info(slot)
		var slot_name: String = tx("Empty slot","Espacio vacío")
		if data.get("exists",false):
			slot_name = str(data.get("name","?")) + " · " + tx("day ","día ") + str(data.get("day","?")) if data.get("valid",false) else tx("Damaged slot · not loadable","Partida dañada · no se puede cargar")
			if data.get("recovery",false):
				slot_name += tx("  (backup available)","  (copia disponible)")
		_line(right_body,str(slot) + ". " + slot_name,13,MUTED)
		var slot_buttons: HBoxContainer = _hbox(right_body)
		_button(tx("Save in slot","Guardar aquí"),_request_save_slot.bind(slot),slot_buttons)
		var slot_load: Button = _button(tx("Load slot","Cargar"),_request_load_slot.bind(slot),slot_buttons)
		slot_load.disabled = not bool(data.get("valid",false))
	_caption(right_body,tx("Automatic recovery","Recuperación automática"))
	_line(right_body,tx("The game keeps the last two verified autosaves. If the current file is damaged, Continue attempts a recovery.","El juego conserva las dos últimas copias comprobadas. Si se daña la partida actual, Continuar intenta recuperarla."),13,MUTED)
	_button(tx("Export save as JSON","Exportar partida JSON"),func():export_dialog.popup_centered(Vector2i(820,540)),right_body)
	_button(tx("Import native JSON save","Importar partida nativa JSON"),func():import_dialog.popup_centered(Vector2i(820,540)),right_body)
	_button(tx("Take screenshot","Guardar captura"),_take_photo,right_body)
	_button(tx("Return to title menu","Volver al inicio"),_show_start_menu,right_body)
	_caption(right_body,tx("Technology & compatibility","Tecnologia y compatibilidad"))
	_line(right_body,tx("100% native GDScript, offline and without an account or web server.","Juego nativo GDScript, sin conexión, sin cuenta y sin servidor web."),13,MUTED)
	_line(right_body,tx("4.8–5.8 native saves remain importable without overwriting previous save files. Web saves use a separate format.","Las partidas nativas 4.8–5.8 pueden importarse sin sobrescribir archivos anteriores. Las partidas web usan otro formato."),13,MUTED)
	_line(right_body,tx("Network sync and real Android installation still need deployment and device tests.","La sincronizacion y las pruebas en Android fisico siguen pendientes."),13,DANGER)
	_line(right_body,tx("Farming systems are simplified game mechanics, not real agricultural advice.","El modelo es de videojuego, no asesoramiento agricola."),13,MUTED)

func _save_notice() -> void:
	var response: Dictionary = farm.save_file()
	_notify(str(response.get("message",response.get("error","Saved"))))

func _request_load_latest() -> void:
	_confirm_action(tx("Load saved farm?","¿Cargar partida guardada?"),
		tx("Your current unsaved changes will be replaced. The game will attempt verified backup recovery if needed.","Se perderán los cambios sin guardar. El juego intentará recuperar una copia si es necesario."), _load_notice)

func _load_notice() -> void:
	var response: Dictionary = farm.load_file()
	if response.get("ok",false):
		_refresh()
	_notify(str(response.get("message",response.get("error","Loaded"))))

func _request_save_slot(index: int) -> void:
	var information: Dictionary = farm.slot_info(index)
	if bool(information.get("exists",false)):
		_confirm_action(tx("Overwrite slot ","¿Sobrescribir espacio ") + str(index) + "?",
			tx("The previous slot will be kept as a backup.","Se conservará una copia del espacio anterior."),_commit_save_slot.bind(index))
	else:
		_commit_save_slot(index)

func _commit_save_slot(index: int) -> void:
	var result: Dictionary = farm.save_slot(index)
	_refresh()
	_notify(str(result.get("message",result.get("error","Save slot failed"))))

func _request_load_slot(index: int) -> void:
	_confirm_action(tx("Load slot ","¿Cargar espacio ") + str(index) + "?",
		tx("The active farm will change; its last saved version will be retained in recovery.","Cambiará la finca activa; su última versión se conservará como copia."),_commit_load_slot.bind(index))

func _commit_load_slot(index: int) -> void:
	var result: Dictionary = farm.load_slot(index)
	if result.get("ok",false):
		var stored: Dictionary = farm.save_file()
		if not stored.get("ok",false):
			_notify(str(stored.get("error","Could not activate save slot")))
			return
		_refresh()
	_notify(str(result.get("message",result.get("error","Load slot failed"))))

func _modal_body(title: String) -> VBoxContainer:
	if modal != null and is_instance_valid(modal):
		_close_modal()
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.04,0.12,0.08,0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_root.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal = shade
	var center: CenterContainer = CenterContainer.new()
	shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame: PanelContainer = PanelContainer.new()
	var viewport_size: Vector2 = get_viewport_rect().size
	frame.custom_minimum_size = Vector2(minf(590.0,maxf(280.0,viewport_size.x-36.0)),minf(620.0,viewport_size.y*0.82))
	frame.add_theme_stylebox_override("panel",_style(PANEL,18))
	center.add_child(frame)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	var content: VBoxContainer = _vbox(scroll,12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caption(content,title)
	if world != null and is_instance_valid(world):
		world.controls_enabled = false
	return content

func _close_modal() -> void:
	if modal != null and is_instance_valid(modal):
		modal.get_parent().remove_child(modal)
		modal.queue_free()
	modal = null
	inside = null
	if world != null and is_instance_valid(world):
		world.controls_enabled = true

func _show_decision_board() -> void:
	if not game_running:
		return
	var current: Dictionary = farm.state["events"]["active"]
	if current.is_empty():
		var calm: VBoxContainer = _modal_body(tx("Your decision desk","Tablón de decisiones"))
		if calm == null:
			return
		_line(calm,tx("No urgent event today. Explore your land or plan the next season.","Hoy no hay ningún evento urgente. Explora tus tierras o planifica la temporada."),15)
		var f: Dictionary = farm.field_of(selected_field)
		if f.get("owned",false):
			_line(calm,tx("Soil water: ","Humedad: ") + str(snappedf(float(f["soil"]["water"]),0.1)) + " mm",14)
		var effects: Array = farm.active_effects()
		for item in effects:
			_line(calm,_localized_effect(str(item["id"])) + " · " + str(item["hours"]) + " h",14,ACCENT)
		_button(tx("Review fields","Revisar las parcelas"),_go_from_modal.bind("Fields"),calm)
		_button(tx("Read the decision journal","Leer el diario de decisiones"),_go_from_modal.bind("Journal"),calm)
		_button(tx("Close","Cerrar"),_close_modal,calm,true)
		return
	speed = 0
	var id: String = str(current["id"])
	var is_chain: bool = str(current.get("arc","")) != ""
	var decision_title: String = Chains.title(id,language) if is_chain else Decisions.title(id,language)
	var body: VBoxContainer = _modal_body(tx("DECISION · ","DECISIÓN · ") + decision_title)
	if body == null:
		return
	_line(body,Chains.description(id,language) if is_chain else Decisions.description(id,language),16,MUTED)
	_line(body,tx("Consider immediate costs and longer-term consequences.","Compara los costes inmediatos y las consecuencias a largo plazo."),14,ACCENT)
	if not is_chain and Chains.root_arc(id) != "":
		_line(body,tx("Your response will start a continuing village storyline; neighbours may return several days later.",
			"Tu respuesta iniciará una historia del pueblo; los vecinos pueden volver días después."),13,ACCENT)
	if is_chain:
		var arc: Dictionary = Chains.arc(str(current["arc"]))
		_line(body,tx("Neighbour trust: ","Confianza con vecino: ") + str(farm.npc_trust(str(arc["npc"]))) + "/10",14,ACCENT)
		if not farm.has_event_research(id):
			var research: Dictionary = farm.quote("eventResearch",{})
			var clue_button: Button = _button(tx("Ask for an expert assessment · €18","Pedir asesoramiento experto · 18 €"),_research_current_event,body)
			clue_button.disabled = not bool(research.get("ok",false))
		else:
			_line(body,tx("Neighbour's risk assessment complete · risky options have a better chance.","Informe de riesgos completado · las opciones arriesgadas tienen más posibilidades de éxito."),13,ACCENT)
	for choice in farm.event_options():
		var preview: Dictionary = farm.quote("eventChoice",{"choice":str(choice["id"])})
		var panel: PanelContainer = PanelContainer.new()
		panel.add_theme_stylebox_override("panel",_style(Color("#f5f9ee"),12,Color("#bdd4b8")))
		body.add_child(panel)
		var card: VBoxContainer = _vbox(panel,5)
		var title: Label = _line(card,str(choice["text"]),17,INK)
		title.add_theme_font_size_override("font_size",16)
		_line(card,tx("Now: ","Ahora: ") + str(choice.get("effect","")),13,ACCENT)
		_line(card,tx("Trade-off: ","Contrapartida: ") + str(choice.get("risk","")),12,DANGER)
		if is_chain and float(choice.get("chance",1.0)) < 1.0:
			if farm.has_event_research(id):
				_line(card,tx("Estimated success: ","Éxito estimado: ") + str(int(farm.option_probability(id,str(choice["id"]))*100.0)) + "%",13,ACCENT)
			else:
				_line(card,tx("Uncertain result · expert assessment available","Resultado incierto · puedes consultar a un experto"),13,DANGER)
		if bool(preview.get("ok",false)):
			var cost: float = float(preview.get("cost",0.0))
			var revenue: float = float(preview.get("revenue",0.0))
			if cost > 0.0 or revenue > 0.0:
				_line(card,(tx("Cost ","Coste ") + "€" + str(cost)) if cost > 0.0 else (tx("Income ","Ingreso ") + "€" + str(revenue)),13,INK)
		else:
			_line(card,tx("Not available: ","No disponible: ") + str(preview.get("error","")),12,DANGER)
		var button: Button = _button(tx("Choose this option","Elegir esta opción"),_event_decide.bind(str(choice["id"])),card,true)
		button.disabled = not bool(preview.get("ok",false))
	_line(body,tx("Time is paused until you make a choice.","El tiempo está pausado hasta que tomes una decisión."),12,MUTED)

func _research_current_event() -> void:
	var result: Dictionary = farm.act("eventResearch",{})
	if not bool(result.get("ok",false)):
		_notify(str(result.get("error","Research not available")))
		return
	farm.save_file()
	_show_decision_board()

func _event_decide(choice: String) -> void:
	var id: String = str(farm.state["events"]["active"].get("id",""))
	var selected_option: Dictionary = {}
	for opt in farm.event_options():
		if str(opt["id"]) == choice:
			selected_option = opt
			break
	var result: Dictionary = farm.act("eventChoice",{"choice":choice})
	if not bool(result.get("ok",false)):
		_notify(str(result.get("error",tx("Action failed","Acción no disponible"))))
		return
	farm.save_file()
	_close_modal()
	_refresh()
	var outcome_title: String = Chains.title(id,language) if not Chains.stage(id).is_empty() else Decisions.title(id,language)
	_notify(outcome_title + "\n" + str(selected_option.get("effect","")) + "\n" + str(result.get("message","")))

func _enter_building(kind: String) -> void:
	if not game_running:
		return
	var outdoors: bool = ["pond","fence","path","wildGarden","flowers","irrigation"].has(kind)
	var props: Array = []
	match kind:
		"farmhouse": props = ["Workbench","Bookshelf","Resting chair"]
		"market": props = ["Market stalls","Contracts desk","Village map"]
		"coop": props = ["Nesting boxes","Feed trough","Clean straw"]
		"barn": props = ["Hay racks","Water trough","Milking stand"]
		"pasture": props = ["Grazing meadow","Alpaca shelter","Water trough"]
		"stable": props = ["Horse boxes","Grooming area","Hay storage"]
		"pigsty": props = ["Feed bay","Resting pen","Waste collection"]
		"lookout": props = ["Valley telescope","Hiking notices","Wildlife map"]
		"clinic": props = ["Resting bench","Water corner","Recovery notes"]
		"warehouse": props = ["Crop crates","Drying shelves","Ledger"]
		"mill": props = ["Grinding stones","Flour bags","Mill wheel"]
		"press": props = ["Seed hopper","Oil press","Storage barrels"]
		"dairy": props = ["Milk churns","Curd vats","Cheese shelves"]
		"kitchen": props = ["Fruit cooker","Jam pots","Recipe book"]
		"greenhouse": props = ["Seedling beds","Ventilation","Watering can"]
		"pond": props = ["Water levels","Reeds","Wildlife habitat"]
		"apiary": props = ["Hive boxes","Bee flight","Honey frames"]
		"academy": props = ["Course desk","Soil samples","Library"]
		"hutch": props = ["Rabbit housing","Food rack","Fiber basket"]
		"rootCellar": props = ["Cool storage","Root vegetables","Crates"]
		"flowers": props = ["Pollinator plants","Flower border","Insects"]
		"wildGarden": props = ["Wildlife corner","Native flowers","Beetle shelter"]
		"irrigation": props = ["Drip network","Valves","Reservoir meter"]
		"fence": props = ["Hedgerow","Gate","Wild insects"]
		"path": props = ["Stone path","Signposts","Wildflowers"]
		_: props = ["Work station","Materials","Notice board"]
	farm.act("visit",{})
	var body: VBoxContainer = _modal_body(kind.capitalize().replace("_"," "))
	if body == null:
		return
	_line(body,tx("Click a visible object to learn about it.","Pulsa los objetos para conocerlos."),14,MUTED)
	var view: Variant = InteriorScript.new()
	view.custom_minimum_size = Vector2(0,minf(340.0,get_viewport_rect().size.y*0.42))
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(view)
	view.call("set_place",kind,props,outdoors)
	view.call("set_avatar",farm.state["player"])
	view.connect("prop_selected",_inspect_prop)
	_button(tx("Return to the farm","Volver a la finca"),_close_modal,body,true)

func _inspect_prop(value: String) -> void:
	_notify(value + ": " + tx("A working part of your farm. Its practical benefits come from the completed building level.","Forma parte de tu finca. Sus beneficios dependen del nivel de construccion terminado."))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		if modal != null:
			_close_modal()
		return
	if not game_running or modal != null:
		return
	match event.keycode:
		KEY_F1: _change_tab("Explorer")
		KEY_F2: _change_tab("Fields")
		KEY_F3: _change_tab("Valley")
		KEY_F4: _change_tab("Journal")
