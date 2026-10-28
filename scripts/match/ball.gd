class_name Ball
extends Node2D
## Balón con altura falsa (z) como en los juegos retro. `pos` es el punto en
## el suelo del campo (coordenadas del mundo); el nodo se coloca en pantalla
## con View.project y la pelota se dibuja `z` más arriba, con su sombra.

const RADIUS := 2.5
const GRAVITY := 420.0
const GROUND_DRAG := 0.5      # fracción de velocidad que queda tras 1 s rodando
const AIR_DRAG := 0.9
const BOUNCE := 0.45
const WALL_BOUNCE := 0.5

var pos := Vector2.ZERO
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
	pos = at
	velocity = Vector2.ZERO
	z = 0.0
	vz = 0.0


func step(delta: float) -> void:
	if holder != null:
		pos = holder.pos + holder.facing * 6.0
		velocity = holder.velocity
		z = 0.0
		vz = 0.0
		return

	pos += velocity * delta
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


## Por ahora el campo tiene vallas invisibles justo fuera de las líneas.
## Los saques de banda, de meta y de esquina llegan en la semana 3.
func _keep_in_bounds() -> void:
	var m := 6.0
	if pos.y < -m:
		pos.y = -m
		velocity.y = absf(velocity.y) * WALL_BOUNCE
	elif pos.y > Pitch.WIDTH + m:
		pos.y = Pitch.WIDTH + m
		velocity.y = -absf(velocity.y) * WALL_BOUNCE

	var in_mouth := pos.y > Pitch.goal_top() and pos.y < Pitch.goal_bottom()
	var limit_left := -Pitch.GOAL_DEPTH if in_mouth else -m
	var limit_right := Pitch.LENGTH + Pitch.GOAL_DEPTH if in_mouth else Pitch.LENGTH + m
	if pos.x < limit_left:
		pos.x = limit_left
		velocity.x = absf(velocity.x) * WALL_BOUNCE
	elif pos.x > limit_right:
		pos.x = limit_right
		velocity.x = -absf(velocity.x) * WALL_BOUNCE


func sync_view() -> void:
	position = View.project(pos)
	queue_redraw()


func _draw() -> void:
	var lift := View.project(pos, z) - position
	var shadow_scale := clampf(1.0 - z / 80.0, 0.4, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5) * shadow_scale)
	draw_circle(Vector2.ZERO, RADIUS + 0.5, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var c := lift + Vector2(0, -RADIUS)
	draw_circle(c, RADIUS, Color.WHITE)
	draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color(0.15, 0.15, 0.15))
