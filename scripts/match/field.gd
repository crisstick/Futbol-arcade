extends Node2D
## Dibuja el campo con perspectiva lateral (ver View). Se redibuja cada vez
## que se mueve la cámara porque las líneas cambian de inclinación.
## Se reemplazará por arte pixel en la semana 4.

const GRASS_A := Color("3f8f3a")
const GRASS_B := Color("378232")
const OUTSIDE := Color("2c6b2a")
const LINE := Color(1, 1, 1, 0.85)
const NET := Color(1, 1, 1, 0.35)
const STRIPES := 14


func _draw() -> void:
	var cam := View.project(Vector2(View.cam_x, Pitch.CENTER.y))
	draw_rect(Rect2(cam - Vector2(1000, 1000), Vector2(2000, 2000)), OUTSIDE)

	var w := Pitch.LENGTH / STRIPES
	for i in STRIPES:
		var x0 := i * w
		_quad(Vector2(x0, 0), Vector2(x0 + w, Pitch.WIDTH), GRASS_A if i % 2 == 0 else GRASS_B)

	_rect_lines(Vector2.ZERO, Vector2(Pitch.LENGTH, Pitch.WIDTH))
	_seg(Vector2(Pitch.CENTER.x, 0), Vector2(Pitch.CENTER.x, Pitch.WIDTH))
	_circle(Pitch.CENTER, Pitch.CENTER_CIRCLE_RADIUS)
	_spot(Pitch.CENTER)

	for side in [0, 1]:
		var gx: float = 0.0 if side == 0 else Pitch.LENGTH
		var dir: float = 1.0 if side == 0 else -1.0
		_box(gx, dir, Pitch.BOX_DEPTH, Pitch.BOX_WIDTH)
		_box(gx, dir, Pitch.SMALL_BOX_DEPTH, Pitch.SMALL_BOX_WIDTH)
		_spot(Vector2(gx + dir * Pitch.PENALTY_SPOT, Pitch.CENTER.y))
		_goal(gx, dir)


func _quad(a: Vector2, b: Vector2, color: Color) -> void:
	var pts := PackedVector2Array([
		View.project(Vector2(a.x, a.y)), View.project(Vector2(b.x, a.y)),
		View.project(Vector2(b.x, b.y)), View.project(Vector2(a.x, b.y)),
	])
	draw_colored_polygon(pts, color)


func _seg(a: Vector2, b: Vector2, color := LINE, z := 0.0) -> void:
	draw_line(View.project(a, z), View.project(b, z), color, 1.0)


func _rect_lines(a: Vector2, b: Vector2) -> void:
	_seg(Vector2(a.x, a.y), Vector2(b.x, a.y))
	_seg(Vector2(b.x, a.y), Vector2(b.x, b.y))
	_seg(Vector2(b.x, b.y), Vector2(a.x, b.y))
	_seg(Vector2(a.x, b.y), Vector2(a.x, a.y))


func _circle(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var t := TAU * i / 48.0
		pts.append(View.project(c + Vector2(cos(t), sin(t)) * r))
	draw_polyline(pts, LINE, 1.0)


func _spot(p: Vector2) -> void:
	draw_rect(Rect2(View.project(p) - Vector2(1, 0.5), Vector2(2, 1)), LINE)


func _box(gx: float, dir: float, depth: float, width: float) -> void:
	var top := Pitch.CENTER.y - width / 2.0
	var bottom := Pitch.CENTER.y + width / 2.0
	var fx := gx + dir * depth
	_seg(Vector2(gx, top), Vector2(fx, top))
	_seg(Vector2(fx, top), Vector2(fx, bottom))
	_seg(Vector2(fx, bottom), Vector2(gx, bottom))


func _goal(gx: float, dir: float) -> void:
	var top := Pitch.goal_top()
	var bottom := Pitch.goal_bottom()
	var bx := gx - dir * Pitch.GOAL_DEPTH
	var h := Pitch.CROSSBAR_HEIGHT
	# Red: fondo y techo.
	var back := PackedVector2Array([
		View.project(Vector2(bx, top)), View.project(Vector2(bx, bottom)),
		View.project(Vector2(bx, bottom), h), View.project(Vector2(bx, top), h),
	])
	draw_colored_polygon(back, Color(1, 1, 1, 0.12))
	var y := top
	while y <= bottom:
		draw_line(View.project(Vector2(bx, y)), View.project(Vector2(bx, y), h), NET, 1.0)
		y += 6.0
	_seg(Vector2(gx, top), Vector2(bx, top), NET, h)
	_seg(Vector2(gx, bottom), Vector2(bx, bottom), NET, h)
	_seg(Vector2(bx, top), Vector2(bx, bottom), NET, h)
	_seg(Vector2(gx, top), Vector2(bx, top), NET)
	_seg(Vector2(gx, bottom), Vector2(bx, bottom), NET)
	# Postes y travesaño.
	for py in [top, bottom]:
		draw_line(View.project(Vector2(gx, py)), View.project(Vector2(gx, py), h), Color.WHITE, 2.0)
	_seg(Vector2(gx, top), Vector2(gx, bottom), Color.WHITE, h)
