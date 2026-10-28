class_name Ball
extends Node2D
## Balón con altura falsa (z) como en los juegos retro: `position` es el punto
## en el suelo y la pelota se dibuja `z` píxeles más arriba, con su sombra.

const RADIUS := 2.5
const GRAVITY := 420.0
const GROUND_DRAG := 0.55     # fracción de velocidad que queda tras 1 s rodando
const AIR_DRAG := 0.9
const BOUNCE := 0.45
const WALL_BOUNCE := 0.6

var velocity := Vector2.ZERO
var z := 0.0
var vz := 0.0
var holder: FootballPlayer = null


func kick(direction: Vector2, speed: float, lift: float) -> void:
	holder = null
	velocity = direction.normalized() * speed
	vz = lift


func place(at: Vector2) -> void:
	holder = null
	position = at
	velocity = Vector2.ZERO
	z = 0.0
	vz = 0.0


func step(delta: float) -> void:
	if holder != null:
		position = holder.position + holder.facing * 5.0
		velocity = holder.velocity
		z = 0.0
		vz = 0.0
		queue_redraw()
		return

	position += velocity * delta
	if z > 0.0 or vz > 0.0:
		vz -= GRAVITY * delta
		z += vz * delta
		velocity *= pow(AIR_DRAG, delta)
		if z <= 0.0:
			z = 0.0
			vz = -vz * BOUNCE if vz < -40.0 else 0.0
	else:
		velocity *= pow(GROUND_DRAG, delta)
		if velocity.length() < 4.0:
			velocity = Vector2.ZERO

	_keep_in_bounds()
	queue_redraw()


## Por ahora el campo tiene paredes invisibles (estilo fútbol sala arcade).
## Los saques de banda y de esquina llegan en la semana 3.
func _keep_in_bounds() -> void:
	if position.y < 0.0:
		position.y = 0.0
		velocity.y = absf(velocity.y) * WALL_BOUNCE
	elif position.y > Pitch.WIDTH:
		position.y = Pitch.WIDTH
		velocity.y = -absf(velocity.y) * WALL_BOUNCE

	var in_mouth := position.y > Pitch.goal_top() and position.y < Pitch.goal_bottom()
	var limit_left := -Pitch.GOAL_DEPTH if in_mouth else 0.0
	var limit_right := Pitch.LENGTH + Pitch.GOAL_DEPTH if in_mouth else Pitch.LENGTH
	if position.x < limit_left:
		position.x = limit_left
		velocity.x = absf(velocity.x) * WALL_BOUNCE
	elif position.x > limit_right:
		position.x = limit_right
		velocity.x = -absf(velocity.x) * WALL_BOUNCE


func _draw() -> void:
	var shadow_scale := clampf(1.0 - z / 80.0, 0.4, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5) * shadow_scale)
	draw_circle(Vector2.ZERO, RADIUS + 0.5, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0, -RADIUS - z), RADIUS, Color.WHITE)
	draw_rect(Rect2(Vector2(-1, -RADIUS - z - 1), Vector2(2, 2)), Color(0.15, 0.15, 0.15))
