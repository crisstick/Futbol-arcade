class_name Pitch
## Medidas del campo en píxeles del mundo. El origen (0, 0) es la esquina
## superior izquierda del rectángulo de juego.

const LENGTH := 640.0
const WIDTH := 384.0
const CENTER := Vector2(LENGTH / 2.0, WIDTH / 2.0)

const GOAL_MOUTH := 80.0     # ancho de la portería (eje Y)
const GOAL_DEPTH := 16.0     # profundidad de la red detrás de la línea
const CROSSBAR_HEIGHT := 28.0

const BOX_DEPTH := 96.0      # área grande
const BOX_WIDTH := 200.0
const SMALL_BOX_DEPTH := 32.0
const SMALL_BOX_WIDTH := 112.0
const CENTER_CIRCLE_RADIUS := 48.0

## Margen fuera de las líneas que la cámara puede mostrar.
const BORDER := 48.0


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
