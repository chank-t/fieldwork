extends SceneTree
## Native UI and world asset test. Needs the import step for new PNG textures.
const Main = preload("res://Main.tscn")
const Fields = preload("res://scripts/FieldsOpportunity52.gd")
var passed: int = 0
var failed: int = 0
func _initialize() -> void:
	call_deferred("_test")
func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL " + label)
func _test() -> void:
	var ui: Control = Main.instantiate()
	root.add_child(ui)
	await process_frame
	ui.language="en"
	ui.farm.new_game({"seed":52071,"difficulty":"relaxed"})
	ui._show_game()
	await process_frame
	_check(ui.world != null and ui.world.art.has("crop_apple") and ui.world.art.has("growth_rice_2"),"New crops and sprites load in 2D farm")
	_check(ui.world.art.has("terrain52_paddy") and ui.world.art.has("terrain52_raised") and ui.world.art.has("terrain52_orchard"),"Three new layout textures load")
	ui._change_tab("CropGuide52")
	_check(ui.active_tab == "CropGuide52" and ui.right_body.get_child_count() > 3,"Crop encyclopedia opens from navigation")
	ui._change_tab("Fields")
	_check(ui.active_tab == "Fields" and ui.right_body.get_child_count() > 8,"Field layout and variety controls appear")
	ui.farm.act("configurePlot",{"fieldId":"plot1","plotType":"orchard"})
	ui._refresh()
	_check(ui.farm.field_of("plot1")["plot_type"] == "orchard" and Fields.allows_crop(ui.farm.field_of("plot1"),ui.farm.content["crops"]["apple"]),"UI updates when plot type is changed")
	ui.world.queue_redraw()
	ui.queue_free()
	print("FIELDWORK 5.2 UI: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
