extends SceneTree
## Static sizing logic invoked inside Godot, independent of physical monitor.
const Rules = preload("res://scripts/ResponsiveLayout.gd")

func _initialize() -> void:
	var passed: bool = true
	for sample in [
		[Vector2i(390,844),Vector2(390,844),0],
		[Vector2i(430,932),Vector2(430,932),0],
		[Vector2i(820,1180),Vector2(820,1180),1],
		[Vector2i(1024,768),Vector2(1024,768),1],
		[Vector2i(1366,768),Vector2(1366,768),2],
		[Vector2i(1920,1080),Vector2(1920,1080),2]
	]:
		if Rules.mode(sample[0],sample[1]) != sample[2]:
			push_error("Responsive breakpoint mismatch: "+str(sample))
			passed = false
	if Rules.inspector_width(1280) < 330.0 or Rules.inspector_width(2400) > 488.0:
		push_error("Inspector width bounds violated")
		passed = false
	if not Rules.map_tab("Valley") or Rules.map_tab("Machinery"):
		push_error("Mobile map/detail screen mapping wrong")
		passed = false
	print("FIELDWORK 5.5 LAYOUT RULES: ","PASS" if passed else "FAIL")
	quit(0 if passed else 1)
