class_name FootballPlayer
extends Node2D
## Un futbolista. No lee teclas: recibe un PlayerInput de su controlador y el
## partido le llama `step` en cada tick. `pos` está en coordenadas del mundo.

const SPEED := 110.0
const SPEED_WITH_BALL := 104.0
const KEEPER_SPEED := 100.0
const ACCEL := 1000.0
const CONTROL_RADIUS := 8.0
const KEEPER_REACH := 14.0
const LOSE_BALL_COOLDOWN := 0.8
const STEAL_PROTECTION := 0.6
const STUN := 0.5               # tras perder el balón se mueve lento un momento

var team := 0
var number := 1
var is_keeper := false
var home := Vector2.ZERO
var color := Color.WHITE
var pos := Vector2.ZERO
var velocity := Vector2.ZERO
var facing := Vector2.RIGHT
var cooldown := 0.0
var stun := 0.0
var protection := 0.0   # tras robar, nadie puede quitarle el balón
var hold_time := 0.0
var selected := false
var _anim := 0.0


func step(input: PlayerInput, has_ball: bool, delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	protection = maxf(0.0, protection - delta)
	stun = maxf(0.0, stun - delta)
	hold_time = hold_time + delta if has_ball else 0.0
	var max_speed := SPEED
	if is_keeper:
		max_speed = KEEPER_SPEED
	elif has_ball:
		max_speed = SPEED_WITH_BALL
	if stun > 0.0:
		max_speed *= 0.4

	velocity = velocity.move_toward(input.move * max_speed, ACCEL * delta)
	pos += velocity * delta
	pos = pos.clamp(Vector2(-30, -20), Vector2(Pitch.LENGTH + 30, Pitch.WIDTH + 20))
	if input.move.length() > 0.1:
		facing = input.move.normalized()
	_anim += velocity.length() * delta * 0.1


func sync_view() -> void:
	position = View.project(pos)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)

	var stride := 0.0
	if velocity.length() > 5.0:
		stride = 1.0 if fmod(_anim, 2.0) < 1.0 else -1.0
	var shirt := Color("e8d23a") if is_keeper else color
	var shorts := color.darkened(0.5)
	draw_rect(Rect2(-3, -4 + stride * 0.5, 2, 4), shorts)
	draw_rect(Rect2(1, -4 - stride * 0.5, 2, 4), shorts)
	draw_rect(Rect2(-4, -11, 8, 7), shirt)
	draw_rect(Rect2(-3, -15, 6, 4), Color(0.95, 0.78, 0.6))
	draw_rect(Rect2(-3, -16, 6, 2), Color(0.2, 0.12, 0.05))

	if selected:
		var y := -21.0
		draw_colored_polygon(PackedVector2Array([Vector2(-3, y), Vector2(3, y), Vector2(0, y + 3)]), Color(1, 0.9, 0.2))
