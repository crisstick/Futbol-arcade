class_name Pitch
## Medidas del campo en píxeles del mundo (10 px = 1 m, campo de 105 × 68 m).
## El origen (0, 0) es la esquina de la banda lejana con la portería izquierda.
## Y crece hacia la banda cercana (la de abajo en pantalla).

const LENGTH := 1050.0
const WIDTH := 680.0
const CENTER := Vector2(LENGTH / 2.0, WIDTH / 2.0)

const GOAL_MOUTH := 73.0     # ancho de la portería (eje Y)
const GOAL_DEPTH := 20.0     # profundidad de la red detrás de la línea
const CROSSBAR_HEIGHT := 24.0

const BOX_DEPTH := 165.0     # área grande
const BOX_WIDTH := 403.0
const SMALL_BOX_DEPTH := 55.0
const SMALL_BOX_WIDTH := 183.0
const PENALTY_SPOT := 110.0
const CENTER_CIRCLE_RADIUS := 91.5

## Margen fuera de las líneas que la cámara puede mostrar.
const BORDER := 40.0


static func goal_top() -> float:
	return CENTER.y - GOAL_MOUTH / 2.0


static func goal_bottom() -> float:
	return CENTER.y + GOAL_MOUTH / 2.0


## Centro de la portería que defiende `team` (0 = izquierda, 1 = derecha).
static func own_goal(team: int) -> Vector2:
	return Vector2(0.0 if team == 0 else LENGTH, CENTER.y)


## Centro de la portería rival de `team`.
static func target_goal(team: int) -> Vector2:
	return own_goal(1 - team)


## true si `p` está dentro del área grande que defiende `team`.
static func in_own_box(team: int, p: Vector2) -> bool:
	if absf(p.y - CENTER.y) > BOX_WIDTH / 2.0:
		return false
	return p.x < BOX_DEPTH if team == 0 else p.x > LENGTH - BOX_DEPTH
