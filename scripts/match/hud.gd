extends CanvasLayer
## Marcador, reloj y ayuda de controles.

var _score: Label
var _clock: Label
var _hint: Label
var _banner: Label
var _banner_time := 0.0


func _ready() -> void:
	_score = _label(Vector2(0, 2), HORIZONTAL_ALIGNMENT_CENTER, 10)
	_clock = _label(Vector2(0, 14), HORIZONTAL_ALIGNMENT_CENTER, 8)
	_hint = _label(Vector2(0, 200), HORIZONTAL_ALIGNMENT_CENTER, 8)
	_hint.text = "Mover: flechas/WASD   Tirar: J/Espacio   Pase: K   Cambiar: L"
	_banner = _label(Vector2(0, 90), HORIZONTAL_ALIGNMENT_CENTER, 24)
	_banner.visible = false


func _label(pos: Vector2, align: HorizontalAlignment, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(384, size + 4)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)
	return l


func set_score(home: int, away: int) -> void:
	_score.text = "LOCAL  %d - %d  VISITA" % [home, away]


func set_clock(seconds: float) -> void:
	var s := int(ceil(seconds))
	_clock.text = "%d:%02d" % [s / 60, s % 60]


func show_banner(text: String, duration: float) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_time = duration


func _process(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		if _banner_time <= 0.0:
			_banner.visible = false
