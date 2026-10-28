class_name FootballPlayer
extends Node2D
## Un futbolista. No lee teclas: recibe un PlayerInput de su controlador y el
## partido le llama `step` en cada tick.

const SPEED := 88.0
const SPEED_WITH_BALL := 76.0
const ACCEL := 900.0
const CONTROL_RADIUS := 7.0
const LOSE_BALL_COOLDOWN := 0.45

var team := 0
var number := 1
var home := Vector2.ZERO
var color := Color.WHITE
var controller: Controller
var velocity := Vector2.ZERO
var facing := Vector2.RIGHT
var cooldown := 0.0
var selected := false
var _anim := 0.0


func step(input: PlayerInput, has_ball: bool, delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	var max_speed := SPEED_WITH_BALL if has_ball else SPEED

	velocity = velocity.move_toward(input.move * max_speed, ACCEL * delta)
	position += velocity * delta
	position = position.clamp(Vector2(-8, -8), Vector2(Pitch.LENGTH + 8, Pitch.WIDTH + 8))
	if input.move.length() > 0.1:
		facing = input.move.normalized()
	_anim += velocity.length() * delta * 0.12
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)

	var stride := 0.0
	if velocity.length() > 5.0:
		stride = 1.0 if fmod(_anim, 2.0) < 1.0 else -1.0
	var shorts := color.darkened(0.45)
	draw_rect(Rect2(-3, -4 + stride * 0.5, 2, 4), shorts)
	draw_rect(Rect2(1, -4 - stride * 0.5, 2, 4), shorts)
	draw_rect(Rect2(-4, -11, 8, 7), color)
	draw_rect(Rect2(-3, -15, 6, 4), Color(0.95, 0.78, 0.6))
	draw_rect(Rect2(-3, -16, 6, 2), Color(0.2, 0.12, 0.05))

	if selected:
		var y := -21.0
		draw_colored_polygon(PackedVector2Array([Vector2(-3, y), Vector2(3, y), Vector2(0, y + 3)]), Color(1, 0.9, 0.2))
