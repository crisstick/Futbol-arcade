extends SceneTree
## Prueba rápida sin pantalla: juega 3 minutos de IA contra IA y comprueba que
## hay 22 jugadores y que el balón recorre el campo de un lado al otro.
## Uso: godot --headless --path . --fixed-fps 60 -s tests/smoke_test.gd

const SECONDS := 180

var _game: MatchState
var _frames := 0
var _min_x := INF
var _max_x := -INF


func _initialize() -> void:
	_game = load("res://scenes/main.tscn").instantiate()
	_game.autoplay = true
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames += 1
	_min_x = minf(_min_x, _game.ball.pos.x)
	_max_x = maxf(_max_x, _game.ball.pos.x)
	if _frames < SECONDS * 60:
		return false
	print("Jugadores: %d" % _game.players.size())
	print("Marcador tras %d s: %d - %d" % [SECONDS, _game.score[0], _game.score[1]])
	print("Balón recorrió x de %d a %d" % [_min_x, _max_x])
	var ok := _game.players.size() == 22
	ok = ok and _min_x < Pitch.LENGTH * 0.3 and _max_x > Pitch.LENGTH * 0.7
	if ok:
		print("OK")
		quit(0)
	else:
		printerr("FALLO")
		quit(1)
	return true
