extends Control
## Fieldwork 5.3: procedural farmer illustration driven by the same saved
## appearance dictionary as the map and interior. No imported sprite mismatch.
const Style53 = preload("res://scripts/FarmerStyle.gd")
var appearance: Dictionary = Style53.defaults()

func set_look(h: String, s: String, c: String) -> void:
	# Compatibility with older callers and tests.
	set_avatar({"hair":h,"skin":s,"outfit":c})

func set_avatar(values: Dictionary) -> void:
	var combined: Dictionary = appearance.duplicate()
	combined.merge(values,true)
	appearance = Style53.normalize(combined)
	queue_redraw()

func _draw() -> void:
	var mid: Vector2 = Vector2(size.x*0.50,size.y*0.43)
	var scale_factor: float = maxf(0.45,minf(size.x/240.0,size.y/245.0))
	var s: float = scale_factor
	var skin: Color = Color(str(appearance["skin"]))
	var coat: Color = Color(str(appearance["outfit"]))
	var pants: Color = Color(str(appearance["pants"]))
	var boots: Color = Color(str(appearance["boots"]))
	var hair_color: Color = Color(str(appearance["hair_color"]))
	var eyes: Color = Color(str(appearance["eyes"]))
	var face: Vector2 = mid+Vector2(0,-19)*s
	var shoulder_width: float = 57.0
	if str(appearance["body"]) == "compact":
		shoulder_width = 46.0
	elif str(appearance["body"]) == "broad":
		shoulder_width = 70.0
	# Colored background medallion makes every skin/hair style readable.
	draw_circle(mid+Vector2(0,22)*s,94.0*s,Color("#dcebd4"))
	draw_arc(mid+Vector2(0,22)*s,91.0*s,0.0,TAU,48,Color("#86b4a0"),2.0*s,true)
	draw_ellipse_shadow(mid+Vector2(0,105)*s,68.0*s)
	# Boots, trousers, work coat, collar and hands.
	draw_rect(Rect2(mid+Vector2(-33,62)*s,Vector2(27,34)*s),pants)
	draw_rect(Rect2(mid+Vector2(6,62)*s,Vector2(27,34)*s),pants)
	draw_rect(Rect2(mid+Vector2(-40,93)*s,Vector2(35,13)*s),boots)
	draw_rect(Rect2(mid+Vector2(5,93)*s,Vector2(35,13)*s),boots)
	draw_rect(Rect2(mid+Vector2(-shoulder_width,24)*s,Vector2(2.0*shoulder_width,51)*s),coat)
	draw_rect(Rect2(mid+Vector2(-11,12)*s,Vector2(22,17)*s),skin)
	draw_line(mid+Vector2(-10,38)*s,mid+Vector2(10,66)*s,coat.lightened(0.30),2.0*s)
	draw_line(mid+Vector2(10,38)*s,mid+Vector2(-10,66)*s,coat.darkened(0.18),2.0*s)
	draw_circle(mid+Vector2(-shoulder_width,47)*s,12.0*s,skin)
	draw_circle(mid+Vector2(shoulder_width,47)*s,12.0*s,skin)
	# Head and face.
	draw_circle(face,40.0*s,skin)
	draw_circle(face+Vector2(-15,-4)*s,3.8*s,eyes)
	draw_circle(face+Vector2(15,-4)*s,3.8*s,eyes)
	draw_arc(face+Vector2(0,8)*s,12.0*s,0.20,PI-0.20,15,Color("#925f54"),2.0*s,true)
	var hair: String = str(appearance["hair"])
	if hair != "bald":
		draw_arc(face+Vector2(0,-8)*s,39.0*s,PI,TAU,25,hair_color,13.0*s,true)
		match hair:
			"crop", "undercut":
				draw_circle(face+Vector2(0,-34)*s,(22.0 if hair == "crop" else 16.0)*s,hair_color)
			"waves", "curly":
				for i in range(7):
					var hump: float = -34.0+float(i%2)*(-5.0 if hair == "curly" else 3.0)
					draw_circle(face+Vector2(-30.0+float(i)*10.0,hump)*s,(10.5 if hair=="curly" else 8.0)*s,hair_color)
			"braids":
				for side in [-1.0,1.0]:
					for i in range(5):
						draw_circle(face+Vector2(side*38.0,float(i)*13.0-15.0)*s,8.0*s,hair_color)
			"pony", "bun":
				draw_circle(face+Vector2(30,-31)*s,(14.0 if hair == "bun" else 10.0)*s,hair_color)
				if hair == "pony":
					draw_line(face+Vector2(34,-29)*s,face+Vector2(51,23)*s,hair_color,13.0*s,true)
			"long":
				for side in [-1.0,1.0]:
					draw_line(face+Vector2(side*37,-20)*s,face+Vector2(side*42,44)*s,hair_color,14.0*s,true)
	# Facial hair is a distinct cosmetic choice, never linked to pronouns.
	match str(appearance["facial_hair"]):
		"stubble":
			draw_arc(face+Vector2(0,11)*s,20.0*s,0.15,PI-0.15,15,hair_color.lightened(0.18),3.0*s,true)
		"moustache":
			draw_line(face+Vector2(-13,12)*s,face+Vector2(13,12)*s,hair_color,5.0*s,true)
		"beard":
			draw_arc(face+Vector2(0,13)*s,21.0*s,0.07,PI-0.07,15,hair_color,10.0*s,true)
	match str(appearance["accessory"]):
		"scarf", "bandana":
			var textile: Color = Color("#d47a65") if appearance["accessory"] == "scarf" else Color("#eac46e")
			draw_line(mid+Vector2(-23,25)*s,mid+Vector2(27,29)*s,textile,12.0*s,true)
			if appearance["accessory"] == "scarf":
				draw_line(mid+Vector2(16,28)*s,mid+Vector2(22,68)*s,textile,9.0*s,true)
		"glasses":
			for side in [-1.0,1.0]:
				draw_arc(face+Vector2(side*15,-4)*s,9.0*s,0,TAU,22,Color("#293b38"),2.8*s,true)
			draw_line(face+Vector2(-6,-4)*s,face+Vector2(6,-4)*s,Color("#293b38"),2.4*s)
		"flower", "laurel":
			var flower: Color = Color("#f09bbb") if appearance["accessory"] == "flower" else Color("#b8d879")
			draw_circle(face+Vector2(34,-32)*s,8.0*s,flower)
			draw_circle(face+Vector2(34,-32)*s,2.7*s,Color("#f6edb3"))
	var hat: String = str(appearance["hat"])
	if hat != "none":
		var hat_color: Color = Color("#d4b36e") if hat == "straw" else (Color("#597f6a") if hat == "ranger" else Color("#526c85"))
		draw_rect(Rect2(face+Vector2(-32,-57)*s,Vector2(64,20)*s),hat_color)
		if hat != "beanie":
			draw_line(face+Vector2(-46,-37)*s,face+Vector2(46,-37)*s,hat_color,9.0*s,true)
		else:
			draw_arc(face+Vector2(0,-41)*s,33.0*s,PI,TAU,18,hat_color,15.0*s,true)

func draw_ellipse_shadow(point: Vector2, radius: float) -> void:
	draw_circle(point+Vector2(0,2),radius,Color(0.10,0.24,0.16,0.15))
