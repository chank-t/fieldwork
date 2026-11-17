extends RefCounted
## Shared destination IDs and labels; presentation never performs travel.
const LOCATIONS = [
	{"id":"village", "xy":Vector2(0.52,0.42), "label":"WILLOW VILLAGE", "label_es":"VILLA SAUCE", "color":"#e8c993", "icon":"building_market"},
	{"id":"river", "xy":Vector2(0.24,0.49), "label":"SILVER RIVER", "label_es":"RÍO PLATEADO", "color":"#9edcd1", "icon":"water"},
	{"id":"woods", "xy":Vector2(0.18,0.23), "label":"MOSSWOOD", "label_es":"BOSQUE DEL MUSGO", "color":"#76a277", "icon":"tree"},
	{"id":"hills", "xy":Vector2(0.79,0.21), "label":"GOLDEN HILLS", "label_es":"COLINAS DORADAS", "color":"#cbb98f", "icon":"rock"},
	{"id":"marsh", "xy":Vector2(0.25,0.79), "label":"REED MARSH", "label_es":"HUMEDAL DE JUNCOS", "color":"#8daf98", "icon":"reed"},
	{"id":"orchard", "xy":Vector2(0.76,0.73), "label":"OLD ORCHARD", "label_es":"HUERTO ANTIGUO", "color":"#acc28e", "icon":"crop_pumpkin"},
	{"id":"lake", "xy":Vector2(0.88,0.51), "label":"BLUEWATER LAKE", "label_es":"LAGO AZUL", "color":"#99ccd7", "icon":"region_lake"},
	{"id":"quarry", "xy":Vector2(0.56,0.13), "label":"OLD STONE QUARRY", "label_es":"CANTERA VIEJA", "color":"#c8b39a", "icon":"region_quarry"}
]
