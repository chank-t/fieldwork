extends Control
const Style53 = preload("res://scripts/FarmerStyle53.gd")
## Fieldwork 4.7: interactive 2D interiors/outdoor sites. No farm state mutation.
## Locations share drawing rules but have individual palettes and props.
signal prop_selected(label: String)

const PAL = {
	"farmhouse":{"floor":"#b88967","wall":"#f0dfc7","trim":"#765c44"},
	"market":{"floor":"#c1a78d","wall":"#f4e2c7","trim":"#986743"},
	"coop":{"floor":"#c9a776","wall":"#e7cba2","trim":"#8e6749"},
	"barn":{"floor":"#b59a72","wall":"#d3b38b","trim":"#76583f"},
	"greenhouse":{"floor":"#a6ba8e","wall":"#cce4d0","trim":"#548769"},
	"academy":{"floor":"#beac84","wall":"#e1d6bc","trim":"#6e776c"},
	"warehouse":{"floor":"#b8a68a","wall":"#d7c7aa","trim":"#80705a"},
	"kitchen":{"floor":"#d6c4a5","wall":"#f1e4ca","trim":"#9b7156"},
	"dairy":{"floor":"#c8bca1","wall":"#e6e3d2","trim":"#7e9990"},
	"stable":{"floor":"#b08d6b","wall":"#d8b98a","trim":"#785842"},
	"pond":{"floor":"#b6d4ac","wall":"#8cbda5","trim":"#497e82"},
	"wildGarden":{"floor":"#b7d399","wall":"#c6dda4","trim":"#5d8555"}
}

var title: String = "farmhouse"
var items: Array = []
var outdoors: bool = false
var visitor: Vector2 = Vector2(0.50,0.77)
var destination: Vector2 = visitor
var elapsed: float = 0.0
var selected_prop: int = -1
var scenery_accum: float = 0.0
var farmer_look: Dictionary = Style53.defaults()

func set_avatar(values: Dictionary) -> void:
	farmer_look = Style53.normalize(values)
	queue_redraw()

func set_place(new_title: String, new_items: Array, is_outdoors: bool = false) -> void:
	title = new_title
	items = new_items.duplicate()
	outdoors = is_outdoors
	visitor = Vector2(0.50,0.77)
	destination = visitor
	selected_prop = -1
	queue_redraw()

func _prop_pos(i: int) -> Vector2:
	return Vector2(size.x * (float(i+1)/float(maxi(1,items.size()+1))),size.y*0.43)

func _rect(rx: float,ry: float,rw: float,rh: float) -> Rect2:
	return Rect2(Vector2(rx*size.x,ry*size.y),Vector2(rw*size.x,rh*size.y))

func _draw_room() -> void:
	var set: Dictionary = PAL.get(title,PAL["farmhouse"])
	var floor: Color = Color(str(set["floor"]))
	var wall: Color = Color(str(set["wall"]))
	var trim: Color = Color(str(set["trim"]))
	draw_rect(Rect2(Vector2.ZERO,size),wall)
	if outdoors:
		draw_rect(_rect(0.02,0.03,0.96,0.94),Color("#a2c88f"))
		for i in range(23):
			var px: float = float((i*37+9)%101)/101.0*size.x
			var py: float = float((i*23+7)%97)/97.0*size.y
			draw_circle(Vector2(px,py),5.0+float(i%3),Color("#89b877"))
			if i%4 == 0:
				draw_circle(Vector2(px+4.0,py-3.0),2.0,Color("#f4d47a"))
		if title=="pond":
			var pool: Rect2 = _rect(0.08,0.13,0.84,0.65)
			draw_rect(pool,Color("#70acba"))
			for i in range(6):
				var p: Vector2 = Vector2(size.x*(0.22+i*0.10),size.y*(0.25+0.06*sin(float(i))))
				draw_circle(p,6.0,Color("#4e9266"))
		elif title in ["flowers","wildGarden","apiary"]:
			for i in range(28):
				var px: float = size.x*(0.08+float((i*17)%83)/100.0)
				var py: float = size.y*(0.17+float((i*29)%72)/100.0)
				draw_circle(Vector2(px,py),3.1,Color("#f0c775") if i%3==0 else Color("#e1a6c8"))
		return
	# Wooden or stone floor (perspective-free, easy to click)
	draw_rect(_rect(0.02,0.22,0.96,0.75),floor)
	for row in range(11):
		var y: float = size.y*(0.26+float(row)*0.061)
		draw_line(Vector2(size.x*0.02,y),Vector2(size.x*0.98,y),floor.darkened(0.10),1.0)
	for col in range(11):
		var x: float = size.x*(0.04+float(col)*0.085)
		draw_line(Vector2(x,size.y*0.26),Vector2(x,size.y*0.95),Color(0.28,0.17,0.14,0.045),1.0)
	draw_rect(_rect(0.02,0.21,0.96,0.025),trim)
	# Window glass, warm light, ledge
	var window: Rect2 = _rect(0.39,0.038,0.22,0.18)
	draw_rect(window,trim)
	draw_rect(window.grow(-4.0),Color("#a3cbd2"))
	draw_line(Vector2(window.get_center().x,window.position.y+4),Vector2(window.get_center().x,window.end.y-4),Color("#e9ebd0"),3.0)
	draw_line(Vector2(window.position.x+4,window.get_center().y),Vector2(window.end.x-4,window.get_center().y),Color("#e9ebd0"),3.0)
	draw_rect(Rect2(window.position+Vector2(-5,window.size.y),Vector2(window.size.x+10,6)),trim.lightened(0.18))
	# Side shelves: same room layout for predictable navigation.
	for side in [0.075,0.86]:
		var shelf: Rect2 = _rect(side,0.09,0.065,0.23)
		draw_rect(shelf,trim)
		for row in range(2):
			draw_line(Vector2(shelf.position.x,shelf.position.y+shelf.size.y*float(row+1)/3.0),Vector2(shelf.end.x,shelf.position.y+shelf.size.y*float(row+1)/3.0),Color("#e4b987"),3.0)

func _draw_prop(i: int, p: Vector2) -> void:
	var name: String = str(items[i])
	var tint: Color = Color("#b88861")
	var box: Rect2 = Rect2(p-Vector2(29,22),Vector2(58,43))
	draw_circle(p+Vector2(2,25),32.0,Color(0.10,0.10,0.08,0.12))
	match title:
		"coop","barn","stable","pigsty","hutch":
			draw_rect(box,Color("#cda16f"))
			draw_rect(box,Color("#805d43"),false,3.0)
			for j in range(3):
				draw_line(p+Vector2(-26,-16+j*11),p+Vector2(26,-16+j*11),Color("#e1bf88"),2.0)
		"greenhouse","flowers","wildGarden","pond","apiary":
			draw_rect(box,Color("#8fa87c"))
			for j in range(5):
				var plant: Vector2 = p+Vector2(-21+j*10,5)
				draw_line(plant,plant-Vector2(0,17),Color("#376b4c"),2.0)
				draw_circle(plant-Vector2(0,18),5.0,Color("#91c16c") if j%2==0 else Color("#e4b68d"))
		"market","kitchen","dairy","warehouse","rootCellar":
			draw_rect(box,tint)
			draw_rect(box.grow(-4.0),Color("#d9bb88"))
			for j in range(4):
				draw_circle(p+Vector2(-18+j*12,-3),5.0,Color("#e49b65") if j%2==0 else Color("#95b97c"))
		"mill","press","workshop","irrigation":
			draw_rect(box,Color("#929d98"))
			draw_circle(p-Vector2(2,3),16.0,Color("#4f7777"))
			draw_circle(p-Vector2(2,3),8.0,Color("#dae0cf"))
			for j in range(6):
				var angle: float = TAU*float(j)/6.0
				var outer: Vector2 = p-Vector2(2,3)+Vector2(cos(angle),sin(angle))*16.0
				draw_circle(outer,3.0,Color("#d8d8cb"))
		_:
			draw_rect(box,Color("#bb936c"))
			draw_rect(box.grow(-5.0),Color("#e2bf91"))
			draw_line(p-Vector2(14,13),p+Vector2(12,7),Color("#6e8f69"),2.0)
	if selected_prop == i:
		draw_rect(box.grow(6.0),Color("#ffe9a2"),false,3.0)
	# Text is on a dark tag, below the object to avoid clipping.
	if ThemeDB.fallback_font != null:
		var label_width: float = minf(140.0,maxf(90.0,size.x/float(maxi(2,items.size()+1))-5.0))
		var tag: Rect2 = Rect2(p+Vector2(-label_width*0.5,32.0),Vector2(label_width,24.0))
		draw_rect(tag,Color(0.16,0.26,0.20,0.87))
		draw_string(ThemeDB.fallback_font,tag.position+Vector2(3,17),name,HORIZONTAL_ALIGNMENT_CENTER,tag.size.x-6,12,Color("#fffbea"))

func _draw_farmer() -> void:
	var avatar: Vector2 = Vector2(visitor.x*size.x,visitor.y*size.y)
	var bob: float = 1.5*sin(elapsed*4.0)
	var look: Dictionary = farmer_look
	var skin: Color = Color(str(look["skin"]))
	var outfit_color: Color = Color(str(look["outfit"]))
	var pants: Color = Color(str(look["pants"]))
	var boots: Color = Color(str(look["boots"]))
	var hair_color: Color = Color(str(look["hair_color"]))
	var shoulder: float = 10.0
	if look["body"] == "compact":
		shoulder = 8.0
	elif look["body"] == "broad":
		shoulder = 13.0
	draw_circle(avatar+Vector2(0,15),18.0,Color(0,0,0,0.13))
	draw_rect(Rect2(avatar+Vector2(-shoulder,0+bob),Vector2(shoulder*2.0,20)),outfit_color)
	draw_circle(avatar+Vector2(0,-7+bob),10.0,skin)
	draw_rect(Rect2(avatar+Vector2(-7,18+bob),Vector2(6,8)),pants)
	draw_rect(Rect2(avatar+Vector2(1,18+bob),Vector2(6,8)),pants)
	draw_line(avatar+Vector2(-4,26),avatar+Vector2(-7,29),boots,3.3)
	draw_line(avatar+Vector2(4,26),avatar+Vector2(7,29),boots,3.3)
	if look["hair"] != "bald":
		draw_arc(avatar+Vector2(0,-9+bob),10.0,PI,TAU,12,hair_color,4.0,true)
		if look["hair"] in ["braids","long"]:
			for side in [-1.0,1.0]:
				draw_line(avatar+Vector2(side*9,-10+bob),avatar+Vector2(side*11,8+bob),hair_color,4.0)
		elif look["hair"] in ["bun","pony"]:
			draw_circle(avatar+Vector2(6,-16+bob),4.0,hair_color)
	if look["facial_hair"] in ["moustache","beard"]:
		draw_line(avatar+Vector2(-4,-3+bob),avatar+Vector2(4,-3+bob),hair_color,1.5)
	for side in [-1.0,1.0]:
		draw_circle(avatar+Vector2(side*3,-8+bob),1.0,Color(str(look["eyes"])))
	if look["accessory"] in ["scarf","bandana"]:
		draw_line(avatar+Vector2(-8,-1+bob),avatar+Vector2(8,-1+bob),Color("#d47a65") if look["accessory"] == "scarf" else Color("#eac46e"),3.3)
	elif look["accessory"] == "glasses":
		for side in [-1.0,1.0]:
			draw_arc(avatar+Vector2(side*3,-8+bob),2.8,0,TAU,9,Color("#293b38"),1.0)
	elif look["accessory"] in ["flower","laurel"]:
		draw_circle(avatar+Vector2(8,-16+bob),2.6,Color("#f09bbb") if look["accessory"] == "flower" else Color("#b8d879"))
	if look["hat"] != "none":
		var hat_color: Color = Color("#d4b36e") if look["hat"] == "straw" else Color("#526c85")
		draw_rect(Rect2(avatar+Vector2(-8,-20+bob),Vector2(16,6)),hat_color)
		if look["hat"] != "beanie":
			draw_line(avatar+Vector2(-12,-14+bob),avatar+Vector2(12,-14+bob),hat_color,3.0)

func _draw() -> void:
	_draw_room()
	for i in range(items.size()):
		_draw_prop(i,_prop_pos(i))
	_draw_farmer()
	if ThemeDB.fallback_font != null:
		var tip: String = "CLICK TO WALK & INSPECT"
		var label: Rect2 = Rect2(Vector2(12,size.y-35),Vector2(minf(270.0,size.x-24),25))
		draw_rect(label,Color(0.15,0.28,0.20,0.80))
		draw_string(ThemeDB.fallback_font,label.position+Vector2(8,18),tip,HORIZONTAL_ALIGNMENT_LEFT,label.size.x-12,12,Color("#fff8dd"))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	destination = Vector2(clampf(event.position.x/maxf(1.0,size.x),0.05,0.95),clampf(event.position.y/maxf(1.0,size.y),0.28,0.86))
	for i in range(items.size()):
		if _prop_pos(i).distance_to(event.position) < 53.0:
			selected_prop = i
			prop_selected.emit(str(items[i]))
			break
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	# Smooth local walking animation; never changes farm resources or time.
	var distance: float = visitor.distance_to(destination)
	if distance > 0.0001:
		visitor = visitor.move_toward(destination,delta*0.50)
	scenery_accum += delta
	if scenery_accum > 0.07 and is_visible_in_tree():
		scenery_accum = 0.0
		queue_redraw()
