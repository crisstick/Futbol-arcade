class_name View
## Proyección de la vista lateral estilo ISS Deluxe. La simulación vive en un
## campo plano (x, y) más una altura z; aquí se convierte a pantalla:
## - el ancho del campo se aplasta (KY) porque la cámara mira de costado;
## - lo lejano se encoge hacia `cam_x`, así las líneas verticales del campo
##   se inclinan según dónde esté la cámara, como en ISSD.

const KY := 0.42          # aplastamiento vertical del campo
const FAR_SCALE := 0.78   # escala horizontal en la banda lejana (la cercana es 1)
const KZ := 0.9           # cuánto sube en pantalla un píxel de altura

## Posición X del mundo donde mira la cámara (centro de la pantalla).
static var cam_x := Pitch.CENTER.x


static func scale_at(y: float) -> float:
	return FAR_SCALE + (1.0 - FAR_SCALE) * (y / Pitch.WIDTH)


static func project(p: Vector2, z := 0.0) -> Vector2:
	var s := scale_at(p.y)
	return Vector2(cam_x + (p.x - cam_x) * s, p.y * KY - z * KZ * s)
