extends SceneTree
## Prueba rápida sin pantalla: juega 90 s de IA contra IA y comprueba que el
## partido avanza y que se marcan goles.
## Uso: godot --headless --path . --fixed-fps 60 -s tests/smoke_test.gd

const SECONDS := 90

var _game: MatchState
var _frames := 0


func _initialize() -> void:
	_game = load("res://scenes/main.tscn").instantiate()
	_game.autoplay = true
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < SECONDS * 60:
		return false
	var goals: int = _game.score[0] + _game.score[1]
	print("Marcador tras %d s: %d - %d" % [SECONDS, _game.score[0], _game.score[1]])
	if goals == 0:
		printerr("FALLO: no hubo goles")
		quit(1)
	else:
		print("OK")
		quit(0)
	return true
