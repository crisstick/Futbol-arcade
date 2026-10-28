extends Node2D
## Dibuja el campo con primitivas. Se reemplazará por un tileset pixel art
## en la semana 4.

const GRASS_A := Color("3f8f3a")
const GRASS_B := Color("378232")
const OUTSIDE := Color("2c6b2a")
const LINE := Color(1, 1, 1, 0.85)
const STRIPE := 40.0


func _draw() -> void:
	var b := Pitch.BORDER
	draw_rect(Rect2(-b * 2, -b * 2, Pitch.LENGTH + b * 4, Pitch.WIDTH + b * 4), OUTSIDE)
	var x := 0.0
	var i := 0
	while x < Pitch.LENGTH:
		draw_rect(Rect2(x, 0, minf(STRIPE, Pitch.LENGTH - x), Pitch.WIDTH), GRASS_A if i % 2 == 0 else GRASS_B)
		x += STRIPE
		i += 1

	draw_rect(Rect2(0, 0, Pitch.LENGTH, Pitch.WIDTH), LINE, false, 1.0)
	draw_line(Vector2(Pitch.CENTER.x, 0), Vector2(Pitch.CENTER.x, Pitch.WIDTH), LINE, 1.0)
	draw_arc(Pitch.CENTER, Pitch.CENTER_CIRCLE_RADIUS, 0, TAU, 48, LINE, 1.0)
	draw_circle(Pitch.CENTER, 1.5, LINE)

	for side in [0, 1]:
		var gx: float = 0.0 if side == 0 else Pitch.LENGTH
		var dir: float = 1.0 if side == 0 else -1.0
		_box(gx, dir, Pitch.BOX_DEPTH, Pitch.BOX_WIDTH)
		_box(gx, dir, Pitch.SMALL_BOX_DEPTH, Pitch.SMALL_BOX_WIDTH)
		draw_circle(Vector2(gx + dir * 64.0, Pitch.CENTER.y), 1.5, LINE)
		_goal(gx, dir)


func _box(gx: float, dir: float, depth: float, width: float) -> void:
	var left := gx if dir > 0 else gx - depth
	draw_rect(Rect2(left, Pitch.CENTER.y - width / 2.0, depth, width), LINE, false, 1.0)


func _goal(gx: float, dir: float) -> void:
	var top := Pitch.goal_top()
	var depth := Pitch.GOAL_DEPTH
	var left := gx - depth if dir > 0 else gx
	var net := Rect2(left, top, depth, Pitch.GOAL_MOUTH)
	draw_rect(net, Color(1, 1, 1, 0.15))
	var y := top
	while y < top + Pitch.GOAL_MOUTH:
		draw_line(Vector2(left, y), Vector2(left + depth, y), Color(1, 1, 1, 0.3), 1.0)
		y += 4.0
	draw_rect(net, Color.WHITE, false, 1.0)
